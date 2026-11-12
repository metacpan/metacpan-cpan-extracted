#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use Monitoring::Sneck::Checks;
use Monitoring::Sneck::Checks::base;
use Monitoring::Sneck::Checks::bond;

my $data = $FindBin::Bin . '/data/bond';

# Linux, t/data/bond/linux/$set standing in for /proc
local $Monitoring::Sneck::Checks::base::OS = 'linux';
my $linux = sub {
	my ( $set, @args ) = @_;
	local $Monitoring::Sneck::Checks::base::PROC = $data . '/linux/' . $set;
	return Monitoring::Sneck::Checks->run( check => 'bond', args => \@args );
};

is(
	$linux->( 'ok', '-b', 'bond0', '-m', '2' )->{stdout},
	"BOND OK - bond0 802.3ad 2 of 2 members up; bond1 active-backup 2 of 2 members up"
		. " | 'bond0 members'=2;;;0;2 'bond1 members'=2;;;0;2\n",
	'all up'
);
my $return = $linux->('degraded');
is( $return->{code}, 2, 'a bond down is CRITICAL' );
is(
	$return->{stdout},
	"BOND CRITICAL - bond0 802.3ad 1 of 2 members up, eth1 not in the active aggregator;"
		. " bond1 active-backup 1 of 2 members up, eth3 down;"
		. " bond2 active-backup down, 0 of 2 members up, eth2 down, eth3 down;"
		. " bond3 802.3ad 2 of 2 members up, no LACP partner"
		. " | 'bond0 members'=1;;;0;2 'bond1 members'=1;;;0;2 'bond2 members'=0;;;0;2 'bond3 members'=2;;;0;2\n",
	'out of the aggregator, a member down, a bond down, no partner'
);
is(
	$linux->( 'ok', '-b', 'bond9', '-m', '3' )->{stdout},
	"BOND CRITICAL - bond9 is not there; bond0 802.3ad 2 of 2 members up, wanted 3;"
		. " bond1 active-backup 2 of 2 members up, wanted 3"
		. " | 'bond0 members'=2;;;0;2 'bond1 members'=2;;;0;2\n",
	'--bond not there, under --members'
);
is( $linux->('none')->{stdout},                  "BOND OK - no bonds\n",                 'bonding not loaded' );
is( $linux->( 'none', '-b', 'bond0' )->{stdout}, "BOND CRITICAL - bond0 is not there\n", 'not loaded, one wanted' );

# FreeBSD, the fake ifconfig printing t/data/bond/freebsd/$BOND_TEST_SET/output
local $Monitoring::Sneck::Checks::base::OS       = 'freebsd';
local $Monitoring::Sneck::Checks::bond::IFCONFIG = $data . '/ifconfig';
my $freebsd = sub {
	my ( $set, @args ) = @_;
	local $ENV{BOND_TEST_SET} = $set;
	return Monitoring::Sneck::Checks->run( check => 'bond', args => \@args );
};

is(
	$freebsd->( 'ok', '-b', 'lagg1' )->{stdout},
	"BOND OK - lagg0 lacp 2 of 2 members up; lagg1 failover 2 of 2 members up"
		. " | 'lagg0 members'=2;;;0;2 'lagg1 members'=2;;;0;2\n",
	'laggs, the idle failover port counted as up'
);
$return = $freebsd->('degraded');
is( $return->{code}, 1, 'a member not up alone is WARNING' );
is(
	$return->{stdout},
	"BOND WARNING - lagg0 lacp 1 of 2 members up, igb1 not aggregating;"
		. " lagg1 failover 1 of 2 members up, igb2 no carrier"
		. " | 'lagg0 members'=1;;;0;2 'lagg1 members'=1;;;0;2\n",
	'LACP not negotiated, a link down'
);
is( $freebsd->( 'degraded', '-m', '2' )->{code}, 2, 'under --members is CRITICAL' );
is(
	$freebsd->('failed')->{stdout},
	"BOND CRITICAL - lagg0 lacp down, 0 of 2 members up, igb0 no carrier, igb1 no carrier | 'lagg0 members'=0;;;0;2\n",
	'every member down'
);
is( $freebsd->('none')->{stdout},   "BOND OK - no bonds\n",                  'no laggs' );
is( $freebsd->('broken')->{stderr}, "BOND UNKNOWN - ifconfig -a exited 1\n", 'ifconfig failing' );

$Monitoring::Sneck::Checks::base::OS = 'openbsd';
is( $freebsd->('ok')->{stderr}, "BOND UNKNOWN - not supported on openbsd\n", 'other OSes' );

done_testing();
