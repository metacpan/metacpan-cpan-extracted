#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use TestTmp;
use Monitoring::Sneck::Checks;
use Monitoring::Sneck::Checks::base;
use Monitoring::Sneck::Checks::thermal_throttle;

# t/data/thermal_throttle has four CPUs in one package, cpu0 and cpu2 sharing core 0, cpu1 and cpu3 core 1
local $Monitoring::Sneck::Checks::base::OS        = 'linux';
local $Monitoring::Sneck::Checks::base::STATE_DIR = TestTmp::dir() . '/state';
my $run = sub {
	my ( $tree, @args ) = @_;
	local $Monitoring::Sneck::Checks::thermal_throttle::CPU_DIR = $FindBin::Bin . '/data/thermal_throttle/' . $tree;
	return Monitoring::Sneck::Checks->run( check => 'thermal_throttle', args => \@args );
};

is(
	$run->('before')->{stdout},
	"THERMAL_THROTTLE OK - first check, 150 core and 160 package throttle events since boot\n",
	'first check, siblings and the package counted once'
);
is(
	$run->('after')->{stdout},
	"THERMAL_THROTTLE WARNING - 15 core and 15 package throttle events since the last check, 36 ms and 40 ms throttled,"
		. " 165 core and 175 package since boot"
		. " | core_events=15;0;;0 core_time=36ms;;;0 package_events=15;0;;0 package_time=40ms;;;0\n",
	'new events'
);
is(
	$run->('after')->{stdout},
	"THERMAL_THROTTLE OK - 0 core and 0 package throttle events since the last check, 0 ms and 0 ms throttled,"
		. " 165 core and 175 package since boot"
		. " | core_events=0;0;;0 core_time=0ms;;;0 package_events=0;0;;0 package_time=0ms;;;0\n",
	'none since'
);
$run->('before');
is( $run->( 'after', '-w', '20' )->{code}, 0, 'under --warning' );
$run->('before');
is( $run->( 'after', '-w', '20', '-c', '10' )->{code}, 2, 'over --critical' );
is(
	$run->('rebooted')->{stdout},
	"THERMAL_THROTTLE OK - first check, 3 core and 3 package throttle events since boot\n",
	'lower counts are a reboot, starting over'
);
is(
	$run->('old')->{stdout},
	"THERMAL_THROTTLE WARNING - 7 core and 6 package throttle events since the last check, 10 core and 9 package since boot"
		. " | core_events=7;0;;0 package_events=6;0;;0\n",
	'no time counters, as on older kernels'
);
is( $run->('none')->{stdout},    "THERMAL_THROTTLE OK - no thermal throttle counters\n", 'no counters' );
is( $run->('missing')->{stdout}, "THERMAL_THROTTLE OK - no thermal throttle counters\n", 'no CPU dir' );
{
	local $Monitoring::Sneck::Checks::base::OS = 'freebsd';
	like( $run->('before')->{combined}, qr/not supported on freebsd/, 'not Linux' );
}

done_testing();
