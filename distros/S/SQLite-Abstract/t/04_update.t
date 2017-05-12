# -*- perl -*-

# t/04_update.t - update tests

use Test::More tests => 2;
use SQLite::Abstract;

my $database = q/__testDATABASE__/;
my $tablename = q/__testTABLE__/;

my @data = ();

my $sql = SQLite::Abstract->new($database);

$sql->table($tablename);

is($sql->update(q/name = 'system' WHERE id >= 1 and id <= 100/), 100, "update test 1");
is($sql->update(q/name = 'guest' WHERE id >= 101 and id <= 200/), 100, "update test 2");
	 
