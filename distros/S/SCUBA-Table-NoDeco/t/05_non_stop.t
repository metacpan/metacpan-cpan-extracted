#!/usr/bin/perl -w

# Test two dives in quick succession a less than 10 minute surface
# interval.  These should be treated as the *same dive*.

use strict;
use Test::More tests => 4;

BEGIN { use_ok('SCUBA::Table::NoDeco') };

my $sdt = SCUBA::Table::NoDeco->new(table => "SSI");

$sdt->dive(metres => 15, minutes => 25);
is($sdt->group,"D");
$sdt->dive(metres => 15, minutes => 5);
is($sdt->group,"E");

# Because this counts as one dive, the 10 minutes accure at
# the 15 metre dive depth.
$sdt->dive(metres => 5, minutes => 10);
is($sdt->group,"F");
