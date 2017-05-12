# -*- perl -*-

# t/02_tables.t - basic table methods

use Test::More tests => 7; 
use SQLite::Abstract;

my $database = q/__testDATABASE__/;
my $tablename = q/__testTABLE__/;

my $object = SQLite::Abstract->new ({
	DB => $database,
	DSN => 'dbi:SQLite2:dbname',
	attrs => {
		AutoCommit => 0,
		PrintError => 1,
		RaiseError => 1,
	},
});

is($object->create_table($tablename, q/
    id INTEGER PRIMARY KEY,
    lname VARCHAR(255),
    fname VARCHAR(255),
    address VARCHAR(255),
    age INT(3)
/), q/0E0/, "CREATE TABLE create_table method");

is($object->do(qq/
CREATE TABLE second_$tablename (
    id INTEGER PRIMARY KEY,
    lname VARCHAR(255),
    fname VARCHAR(255),
    address VARCHAR(255),
    age INT(3)
)
/), q/0E0/, "CREATE TABLE 'do' method");

is($object->table("test_table_1"), "test_table_1", "tablename setter");
is($object->table, "test_table_1", "tablename getter");

is($object->drop_table($tablename), q/0E0/, "DROP TABLE 'drop_table' method");
is($object->do("DROP TABLE second_$tablename"), q/0E0/, "DROP TABLE 'do' method");

is($object->create_table($tablename, q/
    id INTEGER PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    account VARCHAR(255) DEFAULT NULL
/), q/0E0/, "CREATE TABLE create_table method");
	
