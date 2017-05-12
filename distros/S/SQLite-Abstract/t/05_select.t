# -*- perl -*-

# t/06_select.t - select tests

use Test::More tests => 16;
use SQLite::Abstract;

my $database = q/__testDATABASE__/;
my $tablename = q/__testTABLE__/;

my @data = ();

my $sql = SQLite::Abstract->new($database);
my $time = (localtime(time))[5]+1900;
my $min_ahead = 15;
my $sec_ahead = 35;
my $ahead = sprintf("%02d:%02d:%02d", (localtime(time + ($min_ahead*60) + $sec_ahead))[2,1,0]);

$sql->table($tablename);

is(local$_ = $sql->select_name(q/limit 100, 1/), 'guest', "select test 1");
is(local$_ = $sql->select(q/all limit 100, 10/)->[1], 'guest', "select test 2");
is(local$_ = $sql->select_name(q/where name = 'aa'/), 'aa', "select test 3");
is(local$_ = $sql->select(q/all where name = 'aa'/)->[1], 'aa', "select test 4");
is((local@_ = $sql->select_name(q/where name = 'aa'/))[0], 'aa', "select test 5");
is((local@_ = $sql->select(q/all where name = 'aa'/))[0]->[1], 'aa', "select test 6");
is(local$_ = $sql->select->[0], 1, "select test 7");
is(local$_ = $sql->select('*')->[0], 1, "select test 8");
is(local$_ = $sql->last->[0], 1, "select test 9");
is(local$_ = $sql->count, 1404, "select test 9");
is($sql->localtime(1), scalar CORE::localtime(), "localtime method perl style");
like($sql->localtime(), qr/^$time/, "localtime method SQLite style");
is($sql->time(), CORE::time(), "time method");
like($sql->time_ahead(qq/"+$min_ahead minutes", "+$sec_ahead seconds"/), qr/$ahead$/, "time_ahead method");

$sql->{q{dbh}}->{q{PrintError}}++;

$sql->create_view("test_view",qq/
	SELECT id FROM $tablename
	   WHERE name == 'system'
/);

$sql->table = "test_view";

is($sql->sum, 100, "view test");
ok($sql->drop_view("test_view"), "drop view");


   
