# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 10-options.t'

use strict;
use warnings;
use Test::More tests => 51;
BEGIN { use_ok('Net::Z3950::ZOOM') };

my $val1 = "foo";
my $val2 = "$val1\0bar";

my $o1 = Net::Z3950::ZOOM::options_create();
Net::Z3950::ZOOM::options_set($o1, surname => "Taylor");
Net::Z3950::ZOOM::options_set($o1, firstname => "Mike");
ok(Net::Z3950::ZOOM::options_get($o1, "surname") eq "Taylor", "get 1");
ok(Net::Z3950::ZOOM::options_get($o1, "firstname") eq "Mike", "get 2");

my ($len, $val) = (29168);

Net::Z3950::ZOOM::options_set($o1, xyz => $val2);
$val = Net::Z3950::ZOOM::options_getl($o1, "xyz", $len);
ok($val eq $val1,
   "set/getl treats values as NUL-terminated, val='$val' len=$len");

Net::Z3950::ZOOM::options_setl($o1, xyz => $val2, length($val2));
$val = Net::Z3950::ZOOM::options_get($o1, "xyz");
ok($val eq $val1,
   "setl/get treats values as NUL-terminated, val='$val'");

Net::Z3950::ZOOM::options_setl($o1, xyz => $val2, length($val2));
$val = Net::Z3950::ZOOM::options_getl($o1, "xyz", $len);
ok($val eq $val2,
   "setl/getl treats values as opaque, val='$val' len=$len");

my $o2 = Net::Z3950::ZOOM::options_create_with_parent($o1);
ok(Net::Z3950::ZOOM::options_get($o2, "surname") eq "Taylor",
   "get via parent 1");
ok(Net::Z3950::ZOOM::options_get($o2, "firstname") eq "Mike",
   "get via parent 2");

Net::Z3950::ZOOM::options_set($o1, surname => "Parrish");
ok(Net::Z3950::ZOOM::options_get($o2, "surname") eq "Parrish",
   "get via parent after replacement");
Net::Z3950::ZOOM::options_set($o2, surname => "Taylor");
ok(Net::Z3950::ZOOM::options_get($o2, "surname") eq "Taylor",
   "get via parent after overwrite");
ok(Net::Z3950::ZOOM::options_get($o1, "surname") eq "Parrish",
   "get from parent after child overwrite");

my $o3 = Net::Z3950::ZOOM::options_create();
Net::Z3950::ZOOM::options_set($o3, firstname => "Fiona");

my $o4 = Net::Z3950::ZOOM::options_create_with_parent2($o3, $o2);
$val = Net::Z3950::ZOOM::options_get($o4, "firstname");
ok($val eq "Fiona",
   "get via first parent overrides second '$val'");
ok(Net::Z3950::ZOOM::options_get($o4, "surname") eq "Taylor",
   "get via first parent");
Net::Z3950::ZOOM::options_set($o1, initial => "P");
ok(Net::Z3950::ZOOM::options_get($o4, "initial") eq "P",
   "get via grandparent");

Net::Z3950::ZOOM::options_destroy($o1);
ok(1, "grandparent destroyed");
$val = Net::Z3950::ZOOM::options_get($o4, "initial");
ok($val eq "P", "referenced object survived destruction");

Net::Z3950::ZOOM::options_destroy($o4);
ok(1, "grandchild destroyed");
Net::Z3950::ZOOM::options_destroy($o3);
ok(1, "first parent destroyed");
Net::Z3950::ZOOM::options_destroy($o2);
ok(1, "second parent destroyed");

$o1 = Net::Z3950::ZOOM::options_create();
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
ok(Net::Z3950::ZOOM::options_get_bool($o1, "undefined", 1),
   "get_bool() defaulted to true");
ok(!Net::Z3950::ZOOM::options_get_bool($o1, "undefined", 0),
   "get_bool() defaulted to false");

sub check_bool {
    my($o, $val, $truep) = @_;
    Net::Z3950::ZOOM::options_set($o, x => $val);
    ok(Net::Z3950::ZOOM::options_get_bool($o, "x", 1) eq $truep,
       "get_bool() considers $val to be " . ($truep ? "true" : "false"));
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
ok(Net::Z3950::ZOOM::options_get_int($o1, "undefined", 42) == 42,
   "get_int() defaulted to 42");

sub check_int {
    my($o, $val, $expected) = @_;
    Net::Z3950::ZOOM::options_set($o, x => $val);
    my $nval = Net::Z3950::ZOOM::options_get_int($o, "x", 1);
    ok($nval == $expected,
       "get_int() considers $val to be $nval, expected $expected");
}

check_set_int($o1, 0 => 0);
check_set_int($o1, 3 => 3);
check_set_int($o1, -17 => -17);
check_set_int($o1, "     34" => 34);

sub check_set_int {
    my($o, $val, $expected) = @_;
    Net::Z3950::ZOOM::options_set_int($o, x => $val);
    my $nval = Net::Z3950::ZOOM::options_get_int($o, "x", 1);
    ok($nval == $expected,
       "get_int() considers $val to be $nval, expected $expected");
}

