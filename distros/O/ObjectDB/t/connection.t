use Test::Spec;
use Test::Fatal;

use lib 't/lib';

package InheritedConnection;
use base 'TestDB';

package SetterConnection;
use base 'ObjectDB';

package main;

use TestDBH;
use Book;

describe 'connection' => sub {

    it 'via method' => sub {
        my $self = shift;

        my $dbh = InheritedConnection->init_db;

        isa_ok($dbh, 'DBI::db');
    };

    it 'via setter' => sub {
        my $self = shift;

        my $dbh = TestDBH->dbh;
        SetterConnection->init_db($dbh);
        $dbh = SetterConnection->init_db;

        isa_ok($dbh, 'DBI::db');
    };

    it 'via pool' => sub {
        my $self = shift;

        SetterConnection->init_db(
            dsn   => 'dbi:SQLite::memory:',
            attrs => {RaiseError => 1}
        );
        my $dbh = SetterConnection->init_db;

        isa_ok($dbh, 'DBI::db');
    };
};

runtests unless caller;
