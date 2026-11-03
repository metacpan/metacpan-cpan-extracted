#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use TestTmp;
use File::Path qw(make_path);
use Monitoring::Sneck::Checks;
use Monitoring::Sneck::Checks::base;
use Monitoring::Sneck::Checks::sensors;

my $dir = TestTmp::dir();

# makes a hwmon device from file names to contents
my $device = sub {
	my ( $name, %files ) = @_;
	my $path = $dir . '/' . $name;
	make_path($path);
	foreach my $file ( keys(%files) ) {
		open( my $fh, '>', $path . '/' . $file ) or die($!);
		print $fh $files{$file} . "\n";
		close($fh);
	}
}; ## end $device = sub
$device->(
	'hwmon0',
	name             => 'coretemp',
	temp1_input      => 45000,
	temp1_label      => 'Package id 0',
	temp1_max        => 84000,
	temp1_crit       => 100000,
	temp1_crit_alarm => 0,
	temp2_input      => 47000,
	temp2_label      => 'Core 0',
	temp2_max        => 84000,
	temp2_crit       => 100000,
	temp10_input     => 40000,
);
$device->(
	'hwmon1',
	name       => 'nct6775',
	fan1_input => 1200,
	fan1_min   => 300,
	in0_input  => 1104,
	in0_min    => 1000,
	in0_max    => 1200,
	in1_input  => 0
);
local $Monitoring::Sneck::Checks::sensors::HWMON = $dir;
local $Monitoring::Sneck::Checks::base::OS       = 'linux';
my $run = sub { return Monitoring::Sneck::Checks->run( check => 'sensors', args => [@_] ) };

my $return = $run->();
is( $return->{code}, 0, 'all OK' );
is(
	$return->{stdout},
	"SENSORS OK - 6 sensors | 'coretemp Package id 0'=45;84;100 'coretemp Core 0'=47;84;100 'coretemp temp10'=40 'nct6775 fan1'=1200;;300: 'nct6775 in0'=1.104;1:1.2 'nct6775 in1'=0\n",
	'output, temp10 after temp2, fan and voltage limits as ranges'
) || diag( $return->{stdout} );
is(
	$run->( '-s', '^coretemp', '-x', 'Core' )->{stdout},
	"SENSORS OK - 2 sensors | 'coretemp Package id 0'=45;84;100 'coretemp temp10'=40\n",
	'--sensor and --exclude'
);
like(
	$run->( '-s', 'Core', '-w', 46, '-c', 50 )->{stdout},
	qr/\ASENSORS WARNING - 1 sensors, coretemp Core 0 is 47 C \| 'coretemp Core 0'=47;46;50\n\z/,
	'--warning and --critical in place of the chip'
);

$device->( 'hwmon0', temp2_input => 90000 );
like(
	$run->()->{stdout},
	qr/\ASENSORS WARNING - 6 sensors, coretemp Core 0 is 90 C, max is 84 \|/,
	'over max is WARNING'
);
$device->( 'hwmon0', temp2_input => 101000 );
like(
	$run->()->{stdout},
	qr/\ASENSORS CRITICAL - 6 sensors, coretemp Core 0 is 101 C, crit is 100 \|/,
	'over crit is CRITICAL'
);
$device->( 'hwmon0', temp2_input => 47000, temp1_crit_alarm => 1 );
like(
	$run->()->{stdout},
	qr/\ASENSORS CRITICAL - .*coretemp Package id 0 is 45 C, its crit alarm is set/,
	'crit alarm'
);
$device->( 'hwmon0', temp1_crit_alarm => 0 );
$device->( 'hwmon1', fan1_input       => 0 );
like( $run->()->{stdout}, qr/\ASENSORS CRITICAL - .*nct6775 fan1 is 0 RPM, min is 300/, 'stopped fan' );
$device->( 'hwmon1', fan1_input => 1200, in0_input => 1300 );
like( $run->()->{stdout}, qr/\ASENSORS WARNING - .*nct6775 in0 is 1.3 V, max is 1.2/, 'voltage over' );
$device->( 'hwmon1', in0_input => 1104, in1_fault => 1 );
like( $run->()->{stdout}, qr/\ASENSORS UNKNOWN - .*nct6775 in1 has a fault/, 'fault' );
is( $run->('-i')->{code}, 0, '--ignore-fault' );
unlink( $dir . '/hwmon1/in1_fault' );
unlink( $dir . '/hwmon1/in1_input' );
$device->( 'hwmon1', in1_label => 'GPU' );
like( $run->()->{stdout}, qr/\ASENSORS OK - 5 sensors/, 'a input that is not there is left out' );
is( $run->( '-s', 'nothing' )->{stdout}, "SENSORS UNKNOWN - no sensors found\n", 'none' );
is( $run->( '-s', '(' )->{code},         3,                                      'bad --sensor' );

# FreeBSD
my %sysctl = (
	'hw.ncpu'                         => 2,
	'dev.cpu.0.temperature'           => '52.0C',
	'dev.cpu.0.coretemp.tjmax'        => '100.0C',
	'dev.cpu.1.temperature'           => 3271,
	'hw.acpi.thermal.tz0.temperature' => '27.9C',
	'hw.acpi.thermal.tz0._CRT'        => '105.0C',
	'hw.acpi.thermal.tz0._HOT'        => -1,
);
{
	no warnings 'once';
	$INC{'BSD/Sysctl.pm'} = __FILE__;
	*BSD::Sysctl::sysctl = sub { return $sysctl{ $_[0] } };
}
{
	local $Monitoring::Sneck::Checks::base::OS = 'freebsd';
	is(
		$run->()->{stdout},
		"SENSORS OK - 3 sensors | cpu0=52;;100 cpu1=54 tz0=27.9;;105\n",
		'FreeBSD, text and deci-Kelvin'
	);
	$sysctl{'dev.cpu.0.temperature'} = '101.0C';
	like( $run->()->{stdout}, qr/\ASENSORS CRITICAL - 3 sensors, cpu0 is 101 C, crit is 100 \|/, 'FreeBSD over tjmax' );
}

done_testing();
