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

my $error_data = [ 43000,43000,43000,43000,43000 ];

my $spc = new Statistics::SPC;
$spc->n(5);
ok($spc->n == 5, "n set to " . $spc->n);
$spc->Uspec(50000);
ok($spc->Uspec == 50000, "Uspec set to " . $spc->Uspec);
$spc->Lspec(40000);
ok($spc->Lspec == 40000, "Lspec set to ". $spc->Lspec);
$does_not_meet_spec = $spc->history($test_data);
ok($does_not_meet_spec == 0, "history: [". $spc->LCLXbar . "," .  $spc->UCLXbar . "]");
$return = $spc->test($error_data);
ok($return == 0, "check() returns:" . $return);
