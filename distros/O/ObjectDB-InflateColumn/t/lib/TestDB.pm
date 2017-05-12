package TestDB;

use strict;
use warnings;

use base 'ObjectDB';
use ObjectDB::InflateColumn;

use DBI;
use File::Spec;

my $dbi = 'dbi:SQLite';

sub db {
    return 'sqlite' unless $ENV{TEST_MYSQL};

    return 'mysql';
}

sub _database { File::Spec->catfile(File::Spec->tmpdir, 'object_db.db') }

sub cleanup { db() eq 'sqlite' ?  unlink _database() : 1 }

our $dbh;

sub init_db {
    my $self = shift;

    return $dbh if $dbh;

    my @args = ();

    if ($ENV{TEST_MYSQL}) {
        my @options = split(',', $ENV{TEST_MYSQL});
        push @args, 'dbi:mysql:' . shift @options, @options ;
    }
    else {
        push @args, 'dbi:SQLite:' . _database();
    }

    $dbh = DBI->connect_cached(@args);
    die $DBI::errorstr unless $dbh;

    if (db() eq 'sqlite') {
        $dbh->do("PRAGMA default_synchronous = OFF");
        $dbh->do("PRAGMA temp_store = MEMORY");
    }

    return $dbh;
}

1;
