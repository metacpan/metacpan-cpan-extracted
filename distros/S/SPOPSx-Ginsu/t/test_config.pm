package test_config;

BEGIN {
	use Log::Log4perl qw( :easy );
	Log::Log4perl->easy_init({ level => $WARN });
}

use strict;

use constant TABLE_CLASSES => qw (
	MyBaseObject
	VehicleImplementation
	Boat
	Anchor
	Aircraft
	Helicopter
	FixedWing
	Seaplane
	Slip
	Boatyard
	Person
	Club
	ClubMembers
);

use Vehicle;
use Boat;
use Anchor;
use Aircraft;
use Helicopter;
use FixedWing;
use Seaplane;
use Slip;
use Boatyard;
use Person;
use Club;
use ClubMembers;

sub create_tables {
	my ($class) = @_;
	map ($_->create_table, $class->TABLE_CLASSES);
}

sub recreate_tables {
	my ($class) = @_;
	map ($_->recreate_table, $class->TABLE_CLASSES);
}
1;
