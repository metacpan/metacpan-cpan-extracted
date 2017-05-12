#!/usr/bin/perl

use Test::Simple tests=> 5;
use Statistics::SPC;

my $test_data = [
	[49920,49920,44052,43364,43364],
	[49920,49920,42980,42980,42980],
	[42980,42980,43364,43364,43364],
	[43364,43364,44976,43364,43364],
	[43364,43364,43364,43364,43364],
	[43364,43364,43364,43364,43364],
	[43364,43364,49920,43364,43364],
	[43364,43364,43364,43364,43364],
	[43364,43364,44976,43364,43364],
	[43364,43364,43364,43364,43364],
	[43364,43364,49920,43364,43364],
	[43364,43748,43748,44976,47908],
	[44052,44052,44052,44052,44052],
	[44052,44052,44052,44052,44052],
	[44052,44052,44052,44052,44976]
];

my $error_data = [ 39,43,43,43,43];

my $spc = new Statistics::SPC;
$spc->n(5);
$spc->Uspec(50000);
$spc->Lspec(40000);
$does_not_meet_spec = $spc->history($test_data);
ok($does_not_meet_spec == 0, "history: [". $spc->LCLXbar . "," .  $spc->UCLXbar . "]");
$return = $spc->test($error_data);
ok($return >= 0, "check() returns:" . $return);
ok($spc->Xbar < $spc->LCLXbar, "Xbar is less than LCL");
$error_data = [ 3900000,4300000,4300000,4300000,43];
$return = $spc->test($error_data);
ok($return >= 0, "check() returns:" . $return);
ok($spc->Xbar > $spc->UCLXbar, "Xbar is greater than UCL");
