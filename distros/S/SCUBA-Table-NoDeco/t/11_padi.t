#!/usr/bin/perl -w
use strict;
use Test::More tests => 92;

# Tests specific to the PADI tables.  I only have a copy of these
# in feet, hence all the tests are in feet as well.  This is good,
# since the module uses metres internally.

BEGIN { use_ok("SCUBA::Table::NoDeco"); }

my $sdt = SCUBA::Table::NoDeco->new(table => "PADI");

is($sdt->table,"PADI","Using correct tables");

# Boundry cases in table.

is($sdt->dive(feet => 110, minutes => 13),"I"); $sdt->clear;
is($sdt->dive(feet => 110, minutes => 14),"K"); $sdt->clear;

is($sdt->dive(feet => 120, minutes => 11),"H"); $sdt->clear;
is($sdt->dive(feet => 120, minutes => 12),"J"); $sdt->clear;

is($sdt->dive(feet => 130, minutes =>  7),"D"); $sdt->clear;
is($sdt->dive(feet => 130, minutes =>  8),"F"); $sdt->clear;

foreach (1..4) {
	is($sdt->dive(feet => 140, minutes =>  $_),"B"); $sdt->clear;
}


# Some typical dive profiles.  These are by no means comprehensive
# tests.

is($sdt->dive(feet => 20, minutes => 32),"E");
$sdt->surface(minutes => 39);
is($sdt->group,"B");
is($sdt->max_time(feet => 50),67);
is($sdt->rnt(feet => 60), 11);

is($sdt->dive(feet => 60, minutes => 40),"U","Second dive in series");
$sdt->surface(minutes => 29);
is($sdt->group,"N");

# These tests take us to a particular group, and then have a surface
# of just enough time to almost take us to group A, leaving us in B .
# We also try one minute more than that time, and ensure that we're in
# group A.  Since the surface tables are automatically generated, this
# is a good way to tell

# We always dive to 35 feet, this gives us the full range of groups.

foreach my $time (
    [ 25, "C", 1*60+ 9 ], [ 29, "D", 1*60+18 ],
    [ 32, "E", 1*60+27 ], [ 36, "F", 1*60+34 ],
    [ 40, "G", 1*60+41 ], [ 44, "H", 1*60+47 ],
    [ 48, "I", 1*60+53 ], [ 52, "J", 1*60+59 ],
    [ 57, "K", 2*60+ 4 ], [ 62, "L", 2*60+ 9 ],
    [ 67, "M", 2*60+14 ], [ 73, "N", 2*60+18 ],
    [ 79, "O", 2*60+23 ], [ 85, "P", 2*60+27 ],
    [ 92, "Q", 2*60+30 ], [100, "R", 2*60+34 ],
    [108, "S", 2*60+38 ], [117, "T", 2*60+41 ],
    [127, "U", 2*60+44 ], [139, "V", 2*60+47 ],
    [152, "W", 2*60+50 ], [168, "X", 2*60+53 ],
    [188, "Y", 2*60+56 ], [205, "Z", 2*60+59 ] ) {

	$sdt->clear;
	is($sdt->dive(feet => 35, minutes => $time->[0]),$time->[1],
	   "Dive for $time->[0] minutes to 35ft gives group $time->[1]");
	
	$sdt->surface(minutes => $time->[2]);
	is($sdt->group,"B","Group $time->[1] with $time->[2] minutes surface makes us group B");

	$sdt->surface(minutes => 1);
	is($sdt->group,"A","Group $time->[1] surface interval to exactly reach A");

}

# Completely de-sat test.
$sdt->clear;
is($sdt->dive(feet => 40, minutes => 22),"C");
$sdt->surface(minutes => 4*60+11);
is($sdt->group,"","4:11 from group C is completely de-sat");
