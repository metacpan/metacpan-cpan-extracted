package TestDBH;

use strict;
use warnings;

use DBI;

our $DBH;

sub import {
    my $has_sqlite = eval { require DBD::SQLite; 1 };
    my $has_mysql  = eval { require DBD::mysql;  1 };
    my $has_pg     = eval { require DBD::Pg;     1 };

    my $skip_reason;
    if ($has_sqlite) {
    } elsif ($has_mysql || $has_pg) {
        if (!$ENV{TEST_OBJECTDB_DBH}) {
            $skip_reason = 'Setup TEST_OBJECT_DBH to point to test database';
        }
    } else {
        $skip_reason = 'One of DBD::SQLite, DBD::mysql, DBD::Pg is required';
    }

    if ($skip_reason) {
        require Test::More;
        Test::More->import( skip_all => $skip_reason);
    }
}

sub dbh {
    my $class = shift;

    return $DBH if $DBH;

    my @dsn;
    if (my $dsn = $ENV{TEST_OBJECTDB_DBH}) {
        @dsn = split /,/, $dsn;
    }
    else {
        push @dsn, 'dbi:SQLite::memory:', '', '';
    }

    my $dbh = DBI->connect(@dsn, {RaiseError => 1});
    die $DBI::errorstr unless $dbh;

    if (!$ENV{TEST_OBJECTDB_DBH}) {
        $dbh->do("PRAGMA default_synchronous = OFF");
        $dbh->do("PRAGMA temp_store = MEMORY");
    }

    $DBH = $dbh;
    return $dbh;
}

1;
