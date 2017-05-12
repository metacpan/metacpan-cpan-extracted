# -*- perl -*-

# t/05_delete.t - delete tests

use Test::More tests => 2;
use SQLite::Abstract;

my $database = q/__testDATABASE__/;
my $tablename = q/__testTABLE__/;

my @data = ();

my $sql = SQLite::Abstract->new($database);

$sql->table($tablename);

is($sql->delete(q/where id <= 100 /), 100, "delete test 1");
is($sql->delete(q/where id <= 200/), 100, "delete test 2");
	 
