use strict;
use warnings;
use Test::More;
use Otogiri;
use Otogiri::Plugin;
#use DBIx::QueryLog;

my $dbfile  = ':memory:';

my $db = Otogiri->new( connect_info => ["dbi:SQLite:dbname=$dbfile", '', '', { RaiseError => 1, PrintError => 0 }] );
$db->load_plugin('DeleteCascade');

ok( $db->can('delete_cascade') );

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

$db->fast_insert('person', {
    name => 'Sherlock Shellingford',
    age  => 15,
});
my $person_id = $db->last_insert_id();
$db->fast_insert('detective', {
    person_id => $person_id,
    toys      => 'psychokinesis',
});

my $affected_rows = $db->delete_cascade('person', { id => $person_id });
ok( !defined $db->single('person',    { id => $person_id }) );
ok( !defined $db->single('detective', { person_id => $person_id }) );
is( $affected_rows, 2 );

done_testing;
