package Monitoring::Spooler::DB;
$Monitoring::Spooler::DB::VERSION = '0.05';
BEGIN {
  $Monitoring::Spooler::DB::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: DB handling

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;
use DBI;

# extends ...
# has ...
has 'dbh' => (
    'is'    => 'rw',
    'isa'   => 'DBI::db',
    'lazy'  => 1,
    'builder' => '_init_dbh',
);

has 'config' => (
    'is'        => 'rw',
    'isa'       => 'Config::Yak',
    'required'  => 1,
);

has 'logger' => (
    'is'        => 'rw',
    'isa'       => 'Log::Tree',
    'required'  => 1,
);
# with ...
# initializers ...
sub _init_dbh {
    my $self = shift;

    my $db_file = $self->config()->get('Monitoring::Spooler::DBFile', { Default => '/var/lib/mon-spooler/db.sqlite3'});

    my $dsn = 'DBI:SQLite:dbname='.$db_file;

    # see http://search.cpan.org/~adamk/DBD-SQLite-1.35/lib/DBD/SQLite.pm#Transaction_and_Database_Locking
    my $dbh = DBI->connect($dsn, '', '', { sqlite_use_immediate_transaction => 1, });

    if($dbh) {
        $self->_check_tables($dbh);
    }

    return $dbh;
}

sub DEMOLISH {
    my $self = shift;

    $self->dbh()->disconnect();

    return;
}

# your code here ...
sub prepare {
    my $self = shift;
    my $sqlstr = shift;

    return $self->dbh()->prepare($sqlstr);
}

sub prepexec {
    my ( $self, $sqlstr, @params ) = @_;

    my $sth = $self->dbh()->prepare($sqlstr);

    if(!$sth) {
        $self->logger()->log( message => 'Failed to prepare statement from SQL: '.$sqlstr.' w/ error: '.$self->dbh()->errstr, level => 'warning', );
        return;
    }
    if($sth->execute(@params)) {
        return $sth;
    } else {
        $self->logger()->log( message => 'Failed to execute statement w/ error: '.$sth->errstr, level => 'warning', );
        return;
    }
}

sub do {
    my $self = shift;

    return $self->dbh()->do(@_);
}

sub last_insert_id {
    my $self = shift;

    return $self->dbh()->last_insert_id(@_);
}

sub errstr {
    my $self = shift;
    return $self->dbh()->errstr();
}

sub _check_tables {
    my $self = shift;
    my $dbh = shift;

    # TODO LOW handle corrupted DB somehow
    # see http://www.sqlite.org/faq.html#q21 for possible approaches

    # TODO LOW add archive table to archive sent messages for some time
    # see http://www.sqlite.org/pragma.html#pragma_auto_vacuum for keeping the
    # disk usage low

    my $sql_meta = <<EOS;
CREATE TABLE IF NOT EXISTS meta (
        key TEXT,
        value TEXT,
        CONSTRAINT ukey UNIQUE (key) ON CONFLICT ABORT
);
EOS
    if($dbh->do($sql_meta)) {
        #$self->logger()->log( message => 'Table meta OK', level => 'debug', );
    } else {
        $self->logger()->log( message => 'Failed to create table meta: '.$dbh->errstr, level => 'error', );
    }

    # check that all required tables exist and create them if they don't
    my $sql_groups = <<EOS;
CREATE TABLE IF NOT EXISTS groups (
        id INTEGER PRIMARY KEY ASC,
        name TEXT
);
EOS

    if($dbh->do($sql_groups)) {
        #$self->logger()->log( message => 'Table groups OK', level => 'debug', );
    } else {
        $self->logger()->log( message => 'Failed to create table groups: '.$dbh->errstr, level => 'error', );
    }

    my $sql_msgq = <<EOS;
CREATE TABLE IF NOT EXISTS msg_queue (
        id INTEGER PRIMARY KEY ASC,
        group_id INTEGER,
        type TEXT,
        message TEXT,
        ts INTEGER,
        event TEXT,
        trigger_id INTEGER,
        CONSTRAINT fk_gid FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
);
EOS

    if($dbh->do($sql_msgq)) {
        #$self->logger()->log( message => 'Table msg_queue OK', level => 'debug', );
    } else {
        $self->logger()->log( message => 'Failed to create table msg_queue: '.$dbh->errstr, level => 'error', );
    }

    my $sql_nq = <<EOS;
CREATE TABLE IF NOT EXISTS notify_order (
        id INTEGER PRIMARY KEY ASC,
        group_id INTEGER,
        name TEXT,
        number TEXT,
        CONSTRAINT fk_gid FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
);
EOS

    if($dbh->do($sql_nq)) {
        #$self->logger()->log( message => 'Table notify_order OK', level => 'debug', );
    } else {
        $self->logger()->log( message => 'Failed to create table notify_order: '.$dbh->errstr, level => 'error', );
    }

    my $sql_ni = <<EOS;
CREATE TABLE IF NOT EXISTS notify_interval (
        id INTEGER PRIMARY KEY ASC,
        group_id INTEGER,
        type TEXT,
        notify_from TEXT,
        notify_to TEXT,
        CONSTRAINT fk_gid FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
);
EOS

    if($dbh->do($sql_ni)) {
        #$self->logger()->log( message => 'Table notify_interval OK', level => 'debug', );
    } else {
        $self->logger()->log( message => 'Failed to create table notify_interval: '.$dbh->errstr, level => 'error', );
    }

    my $sql_pg = <<EOS;
CREATE TABLE IF NOT EXISTS paused_groups (
        id INTEGER PRIMARY KEY ASC,
        group_id INTEGER,
        until INTEGER,
        CONSTRAINT fk_gid FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
);
EOS

    if($dbh->do($sql_pg)) {
        #$self->logger()->log( message => 'Table paused_groups OK', level => 'debug', );
    } else {
        $self->logger()->log( message => 'Failed to create table paused_groups: '.$dbh->errstr, level => 'error', );
    }

    my $sql_pr = <<EOS;
CREATE TABLE IF NOT EXISTS running_procs (
        pid INTEGER PRIMARY KEY ASC,
        type TEXT,
        name TEXT
);
EOS

    if($dbh->do($sql_pr)) {
        #$self->logger()->log( message => 'Table running_procs OK', level => 'debug', );
    } else {
        $self->logger()->log( message => 'Failed to create table running_procs: '.$dbh->errstr, level => 'error', );
    }

    # SQLite honors FK constraints only if the are explicitly turned on ...
    # http://www.sqlite.org/foreignkeys.html#fk_enable
    $dbh->do('PRAGMA foreign_keys = ON;');

    # Speed up a bit, if we encounter a crash we have more to worry about than
    # just a messed up spooler queue ...
    # http://www.sqlite.org/pragma.html#pragma_synchronous
    $dbh->do('PRAGMA synchronous = OFF;');

    $self->_check_db_version($dbh);

    return 1;
}

sub _check_db_version {
    my $self = shift;
    my $dbh = shift;

    $dbh->do('BEGIN TRANSACTION');

    my $db_version = 0; # set default
    my $sql = 'SELECT value FROM meta WHERE `key` = ?';
    my $sth = $dbh->prepare($sql);
    if($sth) {
        if($sth->execute('version')) {
            $db_version = $sth->fetchrow_array();
        } else {
            $self->logger()->log( message => 'Failed to execute statement w/ error: '.$sth->errstr, level => 'warning', );
        }
        $sth->finish();
    } else {
        $self->logger()->log( message => 'Failed to prepare statement from SQL: '.$sql.' w/ error: '.$dbh->errstr, level => 'warning', );
    }

    # drop table paused_users regardless of db version
    $sql = 'DROP TABLE IF EXISTS paused_users;';
    if(!$dbh->do($sql)) {
        $self->logger()->log( message => 'Failed to drop table paused_users', level => 'warning', );
    }

    # do other kinds of upgrades
    if(defined($db_version)) {
        if($db_version < 2) {
            # col ts was added in version 2
            $sql = 'ALTER TABLE msg_queue ADD COLUMN ts INTEGER';
            if(!$dbh->do($sql)) {
                $self->logger()->log( message => 'Failed to add column ts to msq_queue table', level => 'warning', );
            }
        }
        if($db_version < 3) {
            # cols event and trigger_id were added in version 3
            $sql = 'ALTER TABLE msg_queue ADD COLUMN event TEXT';
            if(!$dbh->do($sql)) {
                $self->logger()->log( message => 'Failed to add column event to msq_queue table', level => 'warning', );
            }
            $sql = 'ALTER TABLE msg_queue ADD COLUMN trigger_id INTEGER';
            if(!$dbh->do($sql)) {
                $self->logger()->log( message => 'Failed to add column trigger_id to msq_queue table', level => 'warning', );
            }
        }
    }

    # finally we set the current version which we've reached by upgrading (or not)
    $sql = "INSERT OR REPLACE INTO meta ('key','value') VALUES('version',3);";
    $dbh->do($sql);

    $dbh->do('COMMIT');
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Spooler::DB - DB handling

=head1 NAME

Monitoring::Spooler::DB - database abstraction

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
