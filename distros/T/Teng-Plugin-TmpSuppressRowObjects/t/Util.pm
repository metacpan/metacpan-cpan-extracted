package t::Util;
use strict;
use warnings;
use utf8;

use Exporter qw(import);
use DBI;
use TestDB::Model;

our @EXPORT = qw(
    create_testdb
);

sub create_testdb {
    my $dbh = DBI->connect('dbi:SQLite::memory:','','',{RaiseError => 1, PrintError => 0, AutoCommit => 1});

    $dbh->do(q{
        CREATE TABLE test_table (
            id integer not null,
            name varchar(255),
            primary key (id)
        )
    });

    my $db = TestDB::Model->new(dbh => $dbh, suppress_row_objects => 0);
    return $db;
}

1;
