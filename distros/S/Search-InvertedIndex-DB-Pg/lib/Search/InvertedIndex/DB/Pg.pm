package Search::InvertedIndex::DB::Pg;

use strict;
use vars qw( $VERSION );
$VERSION = '0.02';

use Carp "croak";
use DBI;
use DBD::Pg qw(:pg_types);

=head1 NAME

Search::InvertedIndex::DB::Pg - A Postgres backend for Search::InvertedIndex.

=head1 SYNOPSIS

  use Search::InvertedIndex;
  use Search::InvertedIndex::DB::Pg;

  my $db = Search::InvertedIndex::DB::Pg->new(
        -db_name    => "testdb",
        -hostname   => "test.example.com",
        -port       => 5432,
        -username   => "testuser",
        -password   => "testpass",
        -table_name => "siindex",
        -lock_mode  => "EX",
  );

  my $map = Search::InvertedIndex->new( -database => $db );

=head1 DESCRIPTION

An interface allowing L<Search::InvertedIndex> to store and retrieve
data from a PostgreSQL database. All the data is stored in a single
table, which will be created automatically if it does not exist when
C<new> is called.

=head1 METHODS

=over 4

=item B<new>

  my $db = Search::InvertedIndex::DB::Pg->new(
        -db_name    => "testdb",
        -hostname   => "test.example.com",
        -port       => 5432,
        -username   => "testuser",
        -password   => "testpass",
        -table_name => "siindex",
        -lock_mode  => "EX",
  );

C<-db_name> and C<-table_name> are mandatory.  C<-lock_mode> defaults to C<EX>.
C<-port is optional> and defaults to not being specified..

=cut

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    foreach my $required ( qw( -db_name -table_name ) ) {
        croak "No $required supplied" unless $args{$required};
    }
    $args{-lock_mode} ||= "EX";

    foreach my $param ( qw( -db_name -hostname -port -username -password
                            -table_name -lock_mode ) ) {
        $self->{$param} = $args{$param};
      }

    return $self;
}

=item B<open>

  $db->open;

Opens the database in the mode specified when C<new> was called.
Croaks on error, returns true otherwise. Trying to open a nonexistent
database/table combination in C<SH> mode is considered to be an error.
Opening an already-open database/table combination isn't.

=cut

sub open {
    my $self = shift;
    my $db_name    = $self->{-db_name};
    my $hostname   = $self->{-hostname};
    my $port       = $self->{-port};
    my $username   = $self->{-username};
    my $password   = $self->{-password};
    my $table_name = $self->{-table_name};
    my $lock_mode  = $self->{-lock_mode};

    my $dsn = "dbi:Pg:dbname=$db_name";
    $dsn .= ";host=$hostname" if $hostname;
    $dsn .= ";port=$port"     if $port;

    my $dbh = DBI->connect( $dsn, $username, $password,
                            { AutoCommit => 0 } )#turn off autocommit for speed
      or croak "Couldn't connect to $db_name: $DBI::errstr";

    my $sth = $dbh->prepare(
        "SELECT tablename FROM pg_tables WHERE tablename=?"
    );
    $sth->execute( $table_name );
    my ($exists) = $sth->fetchrow_array;
    $sth->finish;

    # If the table doesn't already exist, create it if we're in a suitable
    # mode, and croak otherwise.
    unless ( $exists ) {
        if ( $lock_mode eq "EX" or $lock_mode eq "UN" ) {
            $dbh->do(
                "CREATE TABLE $table_name (
                                        ii_key character (128),
                                        ii_val bytea
                                          )"
            ) or croak $dbh->errstr;
            $dbh->do(
                "CREATE UNIQUE INDEX ${table_name}_pkey
                 ON $table_name (ii_key)"
            ) or croak $dbh->errstr;
	} else {
            croak "Tried to open with a lock mode other than 'EX' or 'UN'"
              . " and table $table_name doesn't exist in $db_name";

        }
    }

    $self->{-db_handle}   = $dbh;
    $self->{-lock_status} = "UN";
    $self->{-open_status} = 1;

    $self->lock( -lock_mode => $lock_mode );

    return 1;
}

=item B<lock>

  $db->lock( -lock_mode => "EX" );

The C<-lock_mode> parameter is required; allowed values are C<EX>,
C<SH> and C<UN>. Returns true on success; croaks on error.

=cut

sub lock {
    my ($self, %args) = @_;

    my $db_name     = $self->{-db_name};
    my $dbh         = $self->{-db_handle};
    my $table_name  = $self->{-table_name};
    my $lock_status = $self->{-lock_status};

    croak "lock() called but database $db_name/table $table_name isn't open"
      unless $self->status( "-open" );

    my $new_lock_mode = $args{-lock_mode};
    return 1 if $new_lock_mode eq $lock_status;

    if ( $lock_status eq "EX" and $new_lock_mode ne "EX" ) {
        $dbh->commit; # force a sync when changing to lower lock mode
      }

    if ( $new_lock_mode eq "UN" or $new_lock_mode eq "SH"
         or $new_lock_mode eq "EX" ) {
        $self->{-lock_status} = $new_lock_mode;
      } else {
        croak "Unknown lock_mode '$new_lock_mode' requested";
    }

    return 1;
}

=item B<status>

  my $opened = $db->status( "-open" );
  my $lock_mode = $db->status( "-lock_mode" );

Allowed requests are C<-open> and C<-lock_mode>. C<-lock_mode> can
only be called on an open database. C<-lock> is a synonym for
C<-lock_mode>.  Croaks if sent an invalid request, or on error.

=cut

sub status {
    my ($self, $request) = @_;
    $request = lc($request);

    if ( $request eq '-open' ) {
      return $self->{-open_status};
    }

    if ( $request eq '-lock_mode' or $request eq '-lock' ) {
      if ( $self->{-open_status} ) {
	return uc($self->{-lock_status});
      } else {
            croak "Can't request 'lock_mode' status on an unopened db";
        }
    }

    croak "Invalid status request '$request'";
}

=item B<put>

  $db->put( -key => "foo", -value => "bar" );

Both parameters are mandatory. Any others will be silently ignored.
Returns true on success and false on error.

=cut

sub put {
    my $self = shift;
    my %args = ref $_[0] ? %{ $_[0] } : @_ ;
    %args = map { lc($_) => $args{$_} } keys %args;
    $args{-value} = "$args{-value}"; # stringify so can store in a bytea

    unless ( defined $args{-key} and defined $args{-value} ) {
        croak "Must supply both a -key and a -value";
    }

    my $dbh = $self->{-db_handle};
    my $old_ac = $dbh->{AutoCommit};
    $dbh->{AutoCommit} = 0;
    $dbh->commit;
    $dbh->do( "SET TRANSACTION ISOLATION LEVEL SERIALIZABLE" );
    my $key_exists = $self->get( -key => $args{-key} );

    my $sth;
    if ( defined $key_exists ) { # 'defined' as 0 is a legal value
        $sth = $self->{-put_handle_update};
        unless ($sth) {
            my $table = $self->{-table_name};
            $sth = $dbh->prepare(
                "UPDATE $table SET ii_val=? WHERE ii_key=?"
            );
            $self->{-put_handle_update} = $sth;
        }
    } else {
        $sth = $self->{-put_handle_insert};
        unless ($sth) {
            my $table = $self->{-table_name};
            $sth = $dbh->prepare(
                "INSERT INTO $table (ii_val, ii_key) VALUES(?, ?)"
            );
            $self->{-put_handle_insert} = $sth;
        }
    }

    # Use bind_param so nulls etc will be escaped properly.
    $sth->bind_param( 1, $args{-value}, { pg_type => DBD::Pg::PG_BYTEA } );
    $sth->bind_param( 2, $args{-key} );

    my $ok = $sth->execute;
    $sth->finish;
    if ( $ok ) {
        $dbh->commit;
        $dbh->{AutoCommit} = $old_ac;
        return 1;
    } else {
        $dbh->rollback;
        $dbh->{AutoCommit} = $old_ac;
        return 0;
    }
}

=item B<get>

  my $value = $db->get( -key => "foo" );

Croaks if no C<-key> supplied.

=cut

sub get {
    my $self = shift;
    my %args = ref $_[0] ? %{ $_[0] } : @_ ;
    %args = map { lc($_) => $args{$_} } keys %args;
    croak "Must supply a -key" unless defined $args{-key};

    my $dbh = $self->{-db_handle};
    my $sth = $self->{-get_handle};

    unless ( $sth ) {
        my $table = $self->{-table_name};
        $sth = $dbh->prepare("SELECT ii_val FROM $table WHERE ii_key = ?")
          or return 0;
        $self->{-get_handle} = $sth;
    }

    $sth->execute( $args{-key} );
    my $value = $sth->fetchrow_array;
    $sth->finish;

    return $value;
}

=item B<delete>

  $db->delete( -key => "foo" );

=cut

sub delete {
    my $self = shift;
    my %args = ref $_[0] ? %{ $_[0] } : @_ ;
    %args = map { lc($_) => $args{$_} } keys %args;
    croak "Must supply a -key" unless defined $args{-key};

    my $dbh = $self->{-db_handle};
    my $sth = $self->{-del_handle};

    unless ( $sth ) {
        my $table = $self->{-table_name};
        $sth = $dbh->prepare("DELETE FROM $table WHERE ii_key = ?")
          or return 0;
        $self->{-del_handle} = $sth;
    }

    $sth->execute( $args{-key} ) or return 0;
    $sth->finish;
    return 1;
}

=item B<close>

  $db->close;

=cut

sub close {
    my $self = shift;

    $self->lock( -lock_mode => 'UN' );

    my $dbh = $self->{-db_handle};
    $dbh->disconnect;

    $self->{-open_status} = 0;
    $self->{-db_handle} = undef;
}

=item B<clear>

  $db->clear;

Clears out I<all> indexing data.

=cut

sub clear {
    my $self = shift;
    my $dbh   = $self->{-db_handle};
    my $table = $self->{-table_name};
    $dbh->do("DELETE FROM $table") or return 0;
    return 1;
}

sub DESTROY {
    my $self = shift;
    $self->close if $self->status( "open" );
}

=back

=head1 AUTHOR

Kate L Pugh <kake@earth.li>, based on
L<Search::InvertedIndex::DB::Mysql> by Michael Cramer and
L<Search::InvertedIndex::DB::DB_File_SplitHash> by Benjamin Franz.

=head1 COPYRIGHT

     Copyright (C) 2003-4 Kake Pugh.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 CREDITS

Module based on work by Michael Cramer and Benjamin Franz.  Patch from
Cees Hek.

=head1 SEE ALSO

L<Search::InvertedIndex>

=cut

1;
