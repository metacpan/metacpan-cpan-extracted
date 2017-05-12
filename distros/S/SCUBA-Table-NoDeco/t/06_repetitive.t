#!/usr/bin/perl -w

# Test a series of repetitive dives.

use strict;
use Test::More tests => 12;

BEGIN { use_ok('SCUBA::Table::NoDeco') };

my $sdt = SCUBA::Table::NoDeco->new(table => "SSI");

# Dives from PJF's logbook, #3-#6

$sdt->dive(metres => 16.1, minutes => 23);
is($sdt->group,"E");

$sdt->surface(minutes => 3*60+17);
is($sdt->group,"C");
is($sdt->rnt(metres => 10.1), 25);
$sdt->dive(metres => 10.1, minutes => 34);
is($sdt->group,"G");

$sdt->surface(minutes => 3*60+34);
is($sdt->group,"C");
is($sdt->rnt(metres => 11.5),25);
$sdt->dive(metres => 11.5, minutes => 33);
is($sdt->group,"G");

$sdt->surface(minutes => 2*60+20);
is($sdt->group,"D");
is($sdt->rnt(metres => 10.2), 37);
$sdt->dive(metres => 10.2, minutes => 30);
is($sdt->group,"G");

# After a day on the surface, we should have no group.
$sdt->surface(minutes => 24*60);
ok(! $sdt->group, "Completely off-gassed");
