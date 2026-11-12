#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use Monitoring::Sneck::Checks;
use Monitoring::Sneck::Checks::time_sync;

# the fake chronyc, ntpq, and timedatectl print t/data/time_sync/$TIME_SYNC_TEST_SET/output, times in it relative to now
my $daemon = $FindBin::Bin . '/data/time_sync/daemon';
local $Monitoring::Sneck::Checks::time_sync::CHRONYC     = $daemon;
local $Monitoring::Sneck::Checks::time_sync::NTPQ        = $daemon;
local $Monitoring::Sneck::Checks::time_sync::TIMEDATECTL = $daemon;
my $run = sub {
	my ( $set, @args ) = @_;
	local $ENV{TIME_SYNC_TEST_SET} = $set;
	return Monitoring::Sneck::Checks->run( check => 'time_sync', args => \@args );
};

# chrony, found first
like(
	$run->('chrony_ok')->{stdout},
	qr/\ATIME_SYNC OK - chrony synchronised to 192\.0\.2\.123, stratum 2, offset -0\.000156 seconds, updated 30[01] seconds ago \| offset=0\.000156s;0\.1;1;0 since_update=30[01]s;;;0\n\z/,
	'chrony synchronised'
);
is( $run->( 'chrony_ok', '--since-warning',  '100' )->{code}, 1, 'chrony, over --since-warning' );
is( $run->( 'chrony_ok', '--since-critical', '100' )->{code}, 2, 'chrony, over --since-critical' );
is( $run->('chrony_unsynced')->{stdout}, "TIME_SYNC CRITICAL - chrony not synchronised\n", 'chrony not synchronised' );
like(
	$run->('chrony_local')->{stdout},
	qr/\ATIME_SYNC WARNING - chrony synchronised to the local clock, stratum 10,/,
	'chrony on its local stratum'
);
like(
	$run->('chrony_offset')->{stdout},
	qr/\ATIME_SYNC WARNING - chrony synchronised to 192\.0\.2\.1, stratum 3, offset 0\.512346 seconds,/,
	'chrony, offset over --warning'
);
is( $run->( 'chrony_offset', '-c', '0.5' )->{code}, 2, 'chrony, offset over --critical' );
is(
	$run->('chrony_down')->{stdout},
	"TIME_SYNC CRITICAL - chrony is not answering, 506 Cannot talk to daemon\n",
	'chronyd down'
);

# ntpd
like(
	$run->( 'ntpd_ok', '-d', 'ntpd' )->{stdout},
	qr/\ATIME_SYNC OK - ntpd synchronised to 192\.0\.2\.123, stratum 3, offset -0\.000123 seconds, updated 20[01] seconds ago \| offset=0\.000123s;0\.1;1;0 since_update=20[01]s;;;0\n\z/,
	'ntpd synchronised, offset from milliseconds'
);
is(
	$run->( 'ntpd_unsynced', '-d', 'ntpd' )->{stdout},
	"TIME_SYNC CRITICAL - ntpd not synchronised\n",
	'ntpd not synchronised'
);
is(
	$run->( 'ntpd_down', '-d', 'ntpd' )->{stdout},
	"TIME_SYNC CRITICAL - ntpd is not answering, ntpq: read: Connection refused\n",
	'ntpd down'
);

# timesyncd
is(
	$run->( 'timesyncd_ok', '-d', 'timesyncd' )->{stdout},
	"TIME_SYNC OK - timesyncd synchronised\n",
	'timesyncd synchronised'
);
is(
	$run->( 'timesyncd_off', '-d', 'timesyncd' )->{stdout},
	"TIME_SYNC CRITICAL - timesyncd not synchronised, NTP is off\n",
	'timesyncd off'
);

# finding the daemon
{
	local $Monitoring::Sneck::Checks::time_sync::CHRONYC;
	local @Monitoring::Sneck::Checks::time_sync::CHRONYC_PATHS = ();
	like( $run->('ntpd_ok')->{stdout}, qr/\ATIME_SYNC OK - ntpd /, 'ntpd used without chronyc' );
	local $Monitoring::Sneck::Checks::time_sync::NTPQ;
	local @Monitoring::Sneck::Checks::time_sync::NTPQ_PATHS = ();
	like( $run->('timesyncd_ok')->{stdout}, qr/\ATIME_SYNC OK - timesyncd /, 'timesyncd used without either' );
	local $Monitoring::Sneck::Checks::time_sync::TIMEDATECTL;
	local @Monitoring::Sneck::Checks::time_sync::TIMEDATECTL_PATHS = ();
	is( $run->('x')->{stdout}, "TIME_SYNC UNKNOWN - none of chronyc, ntpq, or timedatectl found\n", 'none there' );
	is( $run->( 'x', '-d', 'ntpd' )->{stdout}, "TIME_SYNC UNKNOWN - no tool for ntpd found\n", 'forced, not there' );
}
like( $run->( 'x', '-d', 'openntpd' )->{combined}, qr/--daemon must be chrony, ntpd, or timesyncd/, 'bad --daemon' );

done_testing();
