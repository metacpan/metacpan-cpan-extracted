# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 20-options.t'

use strict;
use warnings;
use Test::More tests => 51;
BEGIN { use_ok('ZOOM') };

my $val1 = "foo";
my $val2 = "$val1\0bar";

my $o1 = new ZOOM::Options();
$o1->option(surname => "Taylor");
$o1->option(firstname => "Mike");
ok($o1->option("surname") eq "Taylor", "get 1");
ok($o1->option("firstname") eq "Mike", "get 2");

my $val;

$o1->option(xyz => $val2);
$val = $o1->option_binary("xyz");
ok($val eq $val1,
   "set/getl treats values as NUL-terminated, val='$val'");

$o1->option_binary(xyz => $val2);
$val = $o1->option("xyz");
ok($val eq $val1,
   "setl/get treats values as NUL-terminated, val='$val'");

$o1->option_binary(xyz => $val2);
$val = $o1->option_binary("xyz");
ok($val eq $val2,
   "setl/getl treats values as opaque, val='$val'");

my $o2 = new ZOOM::Options($o1);
ok($o2->option("surname") eq "Taylor",
   "get via parent 1");
ok($o2->option("firstname") eq "Mike",
   "get via parent 2");

$o1->option(surname => "Parrish");
ok($o2->option("surname") eq "Parrish",
   "get via parent after replacement");
$o2->option(surname => "Taylor");
ok($o2->option("surname") eq "Taylor",
   "get via parent after overwrite");
ok($o1->option("surname") eq "Parrish",
   "get from parent after child overwrite");

my $o3 = new ZOOM::Options();
$o3->option(firstname => "Fiona");

my $o4 = new ZOOM::Options($o3, $o2);
$val = $o4->option("firstname");
ok($val eq "Fiona",
   "get via first parent overrides second '$val'");
ok($o4->option("surname") eq "Taylor",
   "get via first parent");
$o1->option(initial => "P");
ok($o4->option("initial") eq "P",
   "get via grandparent");

$o1->destroy();
ok(1, "grandparent destroyed");
$val = $o4->option("initial");
ok($val eq "P", "referenced object survived destruction");

$o4->destroy();
ok(1, "grandchild destroyed");
$o3->destroy();
ok(1, "first parent destroyed");
$o2->destroy();
ok(1, "second parent destroyed");

$o1 = new ZOOM::Options();
# Strange but true: only "T" and "1" are considered true.
check_bool($o1, y => 0);
check_bool($o1, Y => 0);
check_bool($o1, t => 0);
check_bool($o1, T => 1);
check_bool($o1, n => 0);
check_bool($o1, N => 0);
check_bool($o1, 0 => 0);
check_bool($o1, 1 => 1);
check_bool($o1, 2 => 0);
check_bool($o1, 3 => 0);
check_bool($o1, yes => 0);
check_bool($o1, YES => 0);
check_bool($o1, true => 0);
check_bool($o1, TRUE => 0);
ok($o1->bool("undefined", 1),
   "bool() defaulted to true");
ok(!$o1->bool("undefined", 0),
   "bool() defaulted to false");

sub check_bool {
    my($o, $val, $truep) = @_;
    $o->option(x => $val);
    ok($o->bool("x", 1) eq $truep,
       "bool() considers $val to be " . ($truep ? "true" : "false"));
}

check_int($o1, 0 => 0);
check_int($o1, 1 => 1);
check_int($o1, 2 => 2);
check_int($o1, 3 => 3);
check_int($o1, -17 => -17);
check_int($o1, "012" => 12);
check_int($o1, "0000003" => 3);
check_int($o1, "    3" => 3);
check_int($o1, "     34" => 34);
check_int($o1, "      3 4" => 3);
check_int($o1, "      3,456" => 3);
ok($o1->int("undefined", 42) == 42,
   "int() defaulted to 42");

sub check_int {
    my($o, $val, $expected) = @_;
    $o->option(x => $val);
    my $nval = $o->int("x", 1);
    ok($nval == $expected,
       "int() considers $val to be $nval, expected $expected");
}

check_set_int($o1, 0 => 0);
check_set_int($o1, 3 => 3);
check_set_int($o1, -17 => -17);
check_set_int($o1, "     34" => 34);

sub check_set_int {
    my($o, $val, $expected) = @_;
    $o->set_int(x => $val);
    my $nval = $o->int("x", 1);
    ok($nval == $expected,
       "int() considers $val to be $nval, expected $expected");
}

