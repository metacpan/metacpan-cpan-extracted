use strict;
use warnings;
use Test::More;
use Otogiri;
use Otogiri::Plugin;
#use DBIx::QueryLog;

my $dbfile  = ':memory:';

subtest 'count', sub {
    my $db = _setup();
    $db->load_plugin('Count');
    $db->fast_insert('person', { name => 'Sherlock Shellingford', age => 15 });
    $db->fast_insert('person', { name => 'Nero Yuzurizaki',       age => 15 });
    $db->fast_insert('person', { name => 'Hercule Barton',        age => 16 });
    $db->fast_insert('person', { name => 'Cordelia Glauca',       age => 17 });

    my $count_all = $db->count('person');
    is( $count_all, 4 );

    my $count_with_cond = $db->count('person', '*', { age => 15 });
    is( $count_with_cond, 2 );
};

subtest 'cond in 2nd argument', sub {
    my $db = _setup();
    $db->load_plugin('Count');
    $db->fast_insert('person', { name => 'Sherlock Shellingford', age => 15 });
    $db->fast_insert('person', { name => 'Nero Yuzurizaki',       age => 15 });
    $db->fast_insert('person', { name => 'Hercule Barton',        age => 16 });
    $db->fast_insert('person', { name => 'Cordelia Glauca',       age => 17 });

    my $count_with_cond= $db->count('person', { name => { like => '%e%' } }, { group_by => 'age', having => { age => 17 } });
    is( $count_with_cond, 1);
};


done_testing;


sub _setup {
    my $db = Otogiri->new(
        connect_info => ["dbi:SQLite:dbname=$dbfile", '', '', { RaiseError => 1, PrintError => 0 }],
        strict       => 0,
    );

    my @sql_statements = split /\n\n/, <<EOSQL;
PRAGMA foreign_keys = ON;

CREATE TABLE person (
  id   INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT    NOT NULL,
  age  INTEGER NOT NULL DEFAULT 20
);

CREATE TABLE detective (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  person_id INTEGER NOT NULL,
  toys      TEXT  NOT NULL,
  FOREIGN KEY(person_id) REFERENCES person(id)
);
EOSQL
    $db->do($_) for @sql_statements;
    return $db;
}
