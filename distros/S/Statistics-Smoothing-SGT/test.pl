use strict;
use diagnostics;
use Test::More(tests => 3);

use Statistics::Smoothing::SGT;

# build hash of test frequency classes
my %frequencies = (	1 => 20000,
					2 => 10000,
					3 => 9999,
					4 => 7000,
					5 => 5000);

# get new SGT object
my $sgt = new Statistics::Smoothing::SGT(\%frequencies);

# apply some to tests to this object
ok(defined $sgt, "Passed: Constructor working alright");
ok($sgt->isa("Statistics::Smoothing::SGT"), "Passed: Object is in class \"SGT\"!");
can_ok($sgt, "calculateValues");
