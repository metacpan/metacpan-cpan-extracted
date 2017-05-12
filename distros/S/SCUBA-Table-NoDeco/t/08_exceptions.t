#!/usr/bin/perl -w

use strict;
use Test::More tests => 15;

BEGIN { use_ok("SCUBA::Table::NoDeco"); }

my $stn;

eval { $stn = SCUBA::Table::NoDeco->new(table => "Non-Existant"); };
ok($@,"Non-existant table used");

$stn = SCUBA::Table::NoDeco->new(table => "SSI");

eval { $stn->dive(metres => 100, minutes => 30) };
ok($@,"Dive outside of table's maximum depth");

eval { $stn->dive(metres => 30, minutes => 30) };
ok($@,"Dive outside of table's maximum no-deco time");

eval { $stn->dive(metres => -1, minutes => 30) };
ok($@,"Negative metric depth supplied");

eval { $stn->dive(feet => -1, minutes => 30) };
ok($@,"Negative imperial depth supplied");

eval { $stn->dive(feet => 10, metres => 20, minutes => 30) };
ok($@,"Both imperial and metric depths supplied");

eval { $stn->dive(metres => 20, minutes => -30) };
ok($@,"Negative time supplied");

eval { $stn->dive(metres => 0, minutes => 30) };
ok($@,"Zero depth supplied");

eval { $stn->dive(metres => 18, minutes => 0) };
ok($@,"Zero time supplied");

eval { $stn->dive(metres => 18) };
ok($@,"No times supplied");

eval { $stn->dive(minutes => 18) };
ok($@,"No depth supplied");

eval { $stn->max_depth(units=>"furlongs") };
ok($@,"Unsupported units supplied");

eval { $stn->max_time(metres => 100) };
ok($@,"Too great a depth for our tables");

eval { local $^W = 0; $stn->surface(123) };	# No minutes argument supplied.
like($@,qr/Mandatory argument/,"No minutes argument supplied");
