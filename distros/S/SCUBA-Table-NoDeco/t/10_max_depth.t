#!/usr/bin/perl -w
use strict;
use Test::More tests => 12;

# Test max_depth functionality.

BEGIN { use_ok('SCUBA::Table::NoDeco') };

my $stn = SCUBA::Table::NoDeco->new(tables => "SSI");

# Tests with a fresh diver.  Max depth should be max table depth.
is($stn->max_depth(units => "metres"),39);
is($stn->max_depth(units => "feet"), 130);
is($stn->max_depth(units => "metres"), $stn->max_table_depth(units => "metres"));

is($stn->max_depth(minutes => 20, units => "metres"),30);
is($stn->max_depth(minutes => 20, units => "feet"),100);

is($stn->dive(metres => 24, minutes => 30), "G");
is($stn->surface(minutes => 30),30,"Short surface, remain in group G");

is($stn->max_depth(units => "metres"),21);
is($stn->max_depth(units => "metres", minutes => 30), 12);

eval { $stn->max_depth() };
like($@, qr/Mandatory argument/, "Exception on missing arguments");

eval { $stn->max_depth(minutes => -30) };
like($@, qr/Negative minutes/, "Exception on bad minutes argument");
