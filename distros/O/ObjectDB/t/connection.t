use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;

package InheritedConnection;
use base 'TestDB';

package SetterConnection;
use base 'ObjectDB';

package main;

use TestDBH;
use Book;

subtest 'via method' => sub {
    my $self = shift;

    my $dbh = InheritedConnection->init_db;

    isa_ok($dbh, 'DBI::db');
};

subtest 'via setter' => sub {
    my $self = shift;

    my $dbh = TestDBH->dbh;
    SetterConnection->init_db($dbh);
    $dbh = SetterConnection->init_db;

    isa_ok($dbh, 'DBI::db');
};

subtest 'via dsn' => sub {
    my $self = shift;

    SetterConnection->init_db(
        dsn => $ENV{TEST_OBJECTDB_DBH} || 'dbi:SQLite::memory:',
        attrs => { RaiseError => 1 }
    );
    my $dbh = SetterConnection->init_db;

    isa_ok($dbh, 'DBI::db');
};

done_testing;
