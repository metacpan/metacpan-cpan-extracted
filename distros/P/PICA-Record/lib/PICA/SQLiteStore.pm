package PICA::SQLiteStore;
{
  $PICA::SQLiteStore::VERSION = '0.585';
}
#ABSTRACT: Store L<PICA::Record>s in a SQLite database with versioning
use strict;

use PICA::Record;
use PICA::Store;
use Carp qw(croak);
use DBD::SQLite;
use DBI;

our @ISA=qw(PICA::Store);


sub new {
    my $class = shift;
    my ($filename, %params) = (@_ % 2) ? (@_) : (undef, @_);

    PICA::Store::readconfigfile( \%params, $ENV{PICASTORE} )
        if exists $params{config} or exists $params{conf} ;

    $filename = $params{SQLite} unless defined $filename;

    croak("filename for SQLite database not specified") unless defined $filename;

    my $rebuild = $params{rebuild};
    # TODO: option to use PPN as ID !

    my $dbh = DBI->connect( "dbi:SQLite:dbname=$filename","","",
        { AutoCommit => 0, RaiseError => 1 } );
    $dbh->{sqlite_unicode} = 1;

    croak("SQLite database connection failed: $filename: " . DBD->errstr) unless $dbh;

    #$dbh::DESCTROY = DESTROY {
    #    my $sth = shift;
    #    $sth->finish if $sth->FETCH('Active');
    #}

    # tables and triggers
    my %tables = (
        record => [
            'record_ppn    INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT',
            'record_first INTEGER NOT NULL DEFAULT 0',  # first revision
            'record_latest INTEGER NOT NULL DEFAULT 0', # current revision
        ],
        revision => [
            'rev_id        INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT', # key (version)
            'rev_ppn       INTEGER DEFAULT 0', # foreign key to record.record_ppn
            'rev_data      TEXT NOT NULL',     # PICA+ data
            'rev_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP',
            'rev_user      TEXT DEFAULT 0',
            'rev_deleted   BOOLEAN NOT NULL DEFAULT 0', # delete action
            'rev_is_new    BOOLEAN NOT NULL DEFAULT 0'
        ],
        archive => [
            'arc_ppn    INTEGER PRIMARY KEY',
            'arc_latest INTEGER NOT NULL DEFAULT 0'
        ],
      );
      my %triggers = (
        record_insert => q{CREATE TRIGGER record_insert AFTER INSERT ON revision WHEN new.rev_ppn = 0
BEGIN
  INSERT INTO record (record_first,record_latest) VALUES (new.rev_id,new.rev_id);
  UPDATE revision SET rev_ppn=last_insert_rowid(), rev_is_new=1 WHERE rev_id=new.rev_id;
END;},
        record_update => q{CREATE TRIGGER record_update AFTER INSERT ON revision WHEN new.rev_ppn != 0
BEGIN
  UPDATE record SET record_latest=new.rev_id WHERE record_ppn=new.rev_ppn;
END;},
        record_delete => q{CREATE TRIGGER record_delete DELETE ON record
BEGIN                                                                                                                                            
  INSERT INTO archive (arc_ppn, arc_latest) VALUES (old.record_ppn, old.record_latest);
  UPDATE revision SET rev_deleted=1 WHERE rev_id=old.record_latest;
END;},
    );
# TODO: where is timestamp and user of deletion logged??
# INSERT INTO revision (rev_ppn,rev_deleted,rev_user) VALUES (old.record_ppn,1,''); -- TODO

    my @tb;
    my $std_tab = $dbh->table_info('', '', '%', '');
    while( my $tbl = $std_tab->fetchrow_hashref ) {
        push @tb, $tbl->{TABLE_NAME} if $tables{$tbl->{TABLE_NAME}};
        # TODO: check whether there is any difference in table definitions
    }    
    $rebuild = 1 if (@tb != keys %tables);

    if ($rebuild) {
        eval {
            foreach my $name (@tb) {
                $dbh->do("DROP TABLE $name");
            }
            foreach my $name (keys %tables) {
                my $sql = "CREATE TABLE $name (".join(",",@{$tables{$name}}).")";
                $dbh->do($sql);
            };
            foreach my $name (keys %triggers) {
                $dbh->do($triggers{$name});
            }
            $dbh->commit;
        };
        croak("Failed to create database structure: $@") if $@;
    }

    my $self = bless {
        dbh => $dbh,
        user => 0, # current user id
    }, $class;

    # init prepared statements
    $self->{get_record} = $dbh->prepare(q{SELECT 
 rev_user AS user, rev_ppn AS id, rev_data AS record, rev_timestamp AS timestamp, rev_id AS version, rev_id AS latest
 FROM revision, record WHERE revision.rev_id=record.record_latest AND revision.rev_ppn=record.record_ppn AND record_ppn=?;});
    $self->{get_revision} = $dbh->prepare(q{SELECT 
 rev_user AS user, rev_ppn AS id, rev_data AS record, rev_timestamp AS timestamp, rev_id AS version, record_latest AS latest
 FROM revision, record WHERE rev_ppn=record_ppn AND revision.rev_id=?;});
    $self->{insert_record} = $dbh->prepare('INSERT INTO revision (rev_ppn,rev_data,rev_user) VALUES (0,?,?)');
    $self->{update_record} = $dbh->prepare('INSERT INTO revision (rev_ppn,rev_data,rev_user) VALUES (?,?,?)');
    $self->{delete_record} = $dbh->prepare('DELETE FROM record WHERE record_ppn=?');
    $self->{recent_changes} = $dbh->prepare(q{SELECT
rev_id AS version, rev_ppn AS ppn, rev_user AS user, rev_timestamp AS timestamp, rev_is_new AS is_new, rev_deleted AS deleted FROM revision
ORDER BY version DESC LIMIT ? OFFSET ?});
    $self->{record_history} = $dbh->prepare(q{SELECT
rev_ppn AS ppn, rev_id AS version, rev_user AS user, rev_timestamp AS timestamp, rev_is_new AS is_new, rev_deleted AS deleted FROM revision
WHERE rev_ppn=?
ORDER BY version DESC LIMIT ? OFFSET ?
    });
    $self->{next_rev} = $dbh->prepare(q{SELECT
rev_id AS version, rev_user AS user, rev_timestamp AS timestamp, rev_is_new AS is_new, rev_deleted AS deleted FROM revision
WHERE rev_ppn = ? AND rev_id > ? 
ORDER BY version ASC LIMIT ?
    });
    $self->{prev_rev} = $dbh->prepare(q{SELECT
rev_id AS version, rev_user AS user, rev_timestamp AS timestamp, rev_is_new AS is_new, rev_deleted AS deleted FROM revision
WHERE rev_ppn = ? AND rev_id < ? 
ORDER BY version DESC LIMIT ?
    });
    $self->{deleted} = $dbh->prepare(q{SELECT rev_timestamp AS timestamp, rev_user AS user, arc_ppn AS ppn, arc_latest AS version FROM archive, revision
WHERE rev_id=arc_latest ORDER BY arc_latest DESC LIMIT ? OFFSET ?
    });
    $self->{contributions} = $dbh->prepare(q{SELECT
rev_id AS version, rev_ppn AS ppn, rev_user AS user, rev_timestamp AS timestamp, rev_is_new AS is_new, rev_deleted AS s FROM revision
WHERE rev_user=? ORDER BY version DESC LIMIT ? OFFSET ? 
    });

    return $self;
}


sub get {
    my ($self, $id, $version) = @_;

    my %result;
    eval {
        my $stm;
        if ($version) {
            $stm = $self->{get_revision};
            $stm->execute( $version );
        } else {
            $stm = $self->{get_record};
            $stm->execute( $id );
        }
        my $hashref = $stm->fetchrow_hashref;
        croak( $version ? "version $version" : $id) unless $hashref;
        $hashref->{record} = PICA::Record->new( $hashref->{record} );
        if ($version && $id) {
            %result = $hashref->{id} == $id ? %$hashref : (
                errorcode => 2, errormessage => "record id does not match version"
            );
        } else {
            %result = %$hashref;
        }
        $stm->finish;
    };
    if ($@) {
        # TODO: remove line number
        %result = ( errorcode => 1, errormessage => "get failed: $@" );
    }
    return %result;
}


sub create {
    my ($self, $record) = @_;

    croak('create needs a PICA::Record object')
        unless UNIVERSAL::isa($record,'PICA::Record');

    my %result = eval {
        my $recorddata = $record->string;
        $self->{insert_record}->execute( $recorddata, $self->{user} );
        my $version = $self->{dbh}->func('last_insert_rowid');
        $self->get( undef, $version );
    };
    if ($@) {
        %result = ( errorcode => 1, errormessage => "create failed: $@" );
        $self->{dbh}->rollback;
    } else {
        $self->{dbh}->commit;
    }
    return %result;
}


sub update {
    my ($self, $id, $record, $version) = @_;

    croak('update needs a PICA::Record object') 
        unless UNIVERSAL::isa($record,'PICA::Record');

    my %result = eval {
        if ($version) {
            # TODO (version is ignored so far)
        }
        $self->{update_record}->execute( $id, $record->string, $self->{user} );
        $self->get( $id );    
    };
    if ($@) {
        %result = ( errorcode => 1, errormessage => "update failed: $@" );
        $self->{dbh}->rollback;
    } else {
        $self->{dbh}->commit;
    }
    return %result;
}


sub delete {
    my ($self, $id) = @_;

    my %result = eval {
        # TODO: create a new version
        $self->{update_record}->execute( $id, "", $self->{user} );
        $self->{delete_record}->execute( $id );
        ( 'id' => $id );
    };
    if ($@) {
        %result = ( errorcode => 1, errormessage => "delete failed: $@" );
        $self->{dbh}->rollback;
    } else {
        $self->{dbh}->commit;
    }
    return %result;
}


sub access {
    my ($self, %params) = @_;

    for my $key (qw(userkey password dbsid language)) {
        # ...check whether access can be granted or not...
    }

    $self->{user} = $params{userkey};

    return $self;
}


sub history {
    my ($self, $id, $offset, $limit) = @_;

    $offset = 0 unless $offset;
    $limit = 30 unless $limit;

    eval {
        $self->{record_history}->execute( $id, $limit, $offset );
        my $result = $self->{record_history}->fetchall_arrayref({});
        $self->{record_history}->finish();
        return $result;
    };
}


sub prevnext {
    my ($self, $id, $version, $limit) = @_;
    $limit = 1 unless $limit;

    my $revisions = {};

    eval {
        $self->{prev_rev}->execute( $id, $version, $limit );
        $revisions = $self->{prev_rev}->fetchall_hashref('version');
        $self->{prev_rev}->finish();
        $self->{next_rev}->execute( $id, $version, $limit );
        my $result = $self->{next_rev}->fetchall_hashref('version');
        $self->{next_rev}->finish();
        while (my ($k,$v) = each %$result) {
            $revisions->{$k} = $v;
        }
    };

    return $revisions;
}


sub recentchanges {
    my ($self, $offset, $limit) = @_;

    $offset = 0 unless $offset;
    $limit = 30 unless $limit;

    eval {
        $self->{recent_changes}->execute( $limit, $offset );
        my $result = $self->{recent_changes}->fetchall_arrayref({});
        $self->{recent_changes}->finish();
        return $result;
    };
}


sub contributions {
    my ($self, $user, $offset, $limit) = @_;

    $offset = 0 unless $offset;
    $limit = 30 unless $limit;

    eval {
        $self->{contributions}->execute( $user, $limit, $offset );
        my $result = $self->{contributions}->fetchall_arrayref({});
        $self->{contributions}->finish();
        return $result;
    };
}


sub deletions {
    my ($self, $offset, $limit) = @_;

    $offset = 0 unless $offset;
    $limit = 30 unless $limit;

    eval {
        $self->{deleted}->execute( $limit, $offset );
        my $result = $self->{deleted}->fetchall_arrayref({});
        $self->{deleted}->finish();
        return $result;
    };
}


sub DESTROY {
    my $self = shift;
    $self->{dbh}->disconnect;
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

PICA::SQLiteStore - Store L<PICA::Record>s in a SQLite database with versioning

=head1 VERSION

version 0.585

=head1 METHODS

=head2 new ( [ SQLite => ] $filename [, %params ] )

Create a new or connect to an existing SQLite database.

=head2 get ( $id [, $version ] )

Retrieve the latest revision of record or a specific version.
Returns a hash with either 'errorcode' and 'errormessage' or a hash with 
'id', 'record' (a L<PICA::Record> object), 'version', and 'timestamp'.

=head2 create ( $record )

Insert a new record. The parameter must be a L<PICA::Record> object.
Returns a hash with either 'errorcode' and 'errormessage' or a hash
with 'id', 'record', 'version', and 'timestamp'.

=head2 update ( $id, $record [, $version ] )

Update a record by ID, updated record (of type L<PICA::Record>),
and version (of a previous get, create, or update command).

Returns a hash with either 'errorcode' and 'errormessage'
or a hash with 'id', 'record', 'version', and 'timestamp'.

The version parameter is ignore so far (this will be changed).

=head2 delete ( $id )

Delete a record by ID.

Returns a hash with either 'errorcode' and 'errormessage' or a hash with 'id'.

=head2 access ( $key => $value, ... )

Set general access parameters (userkey, password, dbsid and/or language).
Returns the store itself so you can chain anothe method call.

Any client that wants to access should first set these parameters and then
perform the actual access method (create, get, update, delete...).

Up to now only the userkey parameters is used.

=head2 history ( $id, $offset, $limit )

Return the version history of a given record.

=head2 prevnext ( $id, $version [, $limit ] )

Get previous and next revisions of a given record version.
Returns a hash reference indexed by version id.

=head2 recentchanges ( $offset, $limit )

Get a list of recent changes as array of hashref.
Deleted records are included.

=head2 contributions ( $user, $offset, $limit )

Get a list of contributions of a user as array of hashref.
Deleted records are included.

=head2 deletions ( $offset, $limit )

Get a list of deleted records.

=head2 DESTROY (destructor)

Disconnect the database before exit. This method is only called 
automatically as destructor, so don't call it explicitely!

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Verbundzentrale Goettingen (VZG) and Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
