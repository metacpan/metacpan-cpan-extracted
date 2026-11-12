#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use Monitoring::Sneck::Checks;
use Monitoring::Sneck::Checks::zfs;

# the fake zpool prints t/data/zfs/$ZFS_TEST_SET/list or status, dates in it being relative to now
local $Monitoring::Sneck::Checks::zfs::ZPOOL = $FindBin::Bin . '/data/zfs/zpool';
my $run = sub {
	my ( $set, @args ) = @_;
	local $ENV{ZFS_TEST_SET} = $set;
	return Monitoring::Sneck::Checks->run( check => 'zfs', args => \@args );
};

my $tank_perf = 'tank_capacity=45%;80;90;0;100 tank_fragmentation=12%;;;0;100 tank_scrub_age=3.00;40;;0';
my $tank      = 'tank ONLINE, 45% full, 12% fragmented, scrubbed 3 days ago';

is(
	$run->('ok')->{stdout},
	"ZFS OK - 2 pools ok | boot_capacity=20%;80;90;0;100 boot_fragmentation=3%;;;0;100 "
		. $tank_perf . "\n"
		. "boot ONLINE, 20% full, 3% fragmented, scrubbing 45.67%\n"
		. $tank . "\n",
	'healthy, a scrub running, logs, cache, and a spare'
);
is(
	$run->( 'ok', '-p', 'tank', '-p', 'nope' )->{stdout},
	"ZFS CRITICAL - nope is not there; 1 other ok | " . $tank_perf . "\n" . $tank . "\n",
	'--pool, one not there'
);
like(
	$run->( 'ok', '--frag-warning', '10' )->{stdout},
	qr/\AZFS WARNING - tank 12% fragmented; 1 other ok \|/,
	'over --frag-warning'
);
is(
	$run->('bad')->{stdout},
	"ZFS CRITICAL - backup 85% full, no finished scrub; tank DEGRADED, resilvering 12.34%,"
		. " sda with 3 checksum errors, sdb FAULTED with 2 read, 41 write errors, sde UNAVAIL, 2 data errors"
		. " | backup_capacity=85%;80;90;0;100 tank_capacity=45%;80;90;0;100 tank_fragmentation=12%;;;0;100\n"
		. "backup ONLINE, 85% full, no finished scrub\n"
		. "tank DEGRADED, 45% full, 12% fragmented, resilvering 12.34%\n",
	'degraded, resilvering, device errors, data errors, full, and never scrubbed'
);
is( $run->( 'bad', '-p', 'backup', '-w', '90', '--scrub-warning', '~:' )->{code},
	0, 'under --warning, scrub age not checked' );
is(
	$run->('old')->{stdout},
	"ZFS CRITICAL - tank 92% full, resilvered 50 days ago"
		. " | tank_capacity=92%;80;90;0;100 tank_fragmentation=55%;;;0;100 tank_scrub_age=50.00;40;;0\n"
		. "tank ONLINE, 92% full, 55% fragmented, resilvered 50 days ago\n",
	'over --critical, old scrub'
);
like(
	$run->( 'old', '-c', '95', '--scrub-critical', '45' )->{stdout},
	qr/\AZFS CRITICAL - tank 92% full, resilvered 50 days ago \|/,
	'over --scrub-critical'
);
is( $run->( 'old', '-c', '95', '--scrub-warning', '60' )->{code}, 1, 'under --scrub-warning, still over --warning' );
is( $run->('none')->{stdout},                                     "ZFS OK - no pools\n", 'no pools' );
is(
	$run->('failing')->{stdout},
	"ZFS UNKNOWN - zpool list exited 1, Permission denied the ZFS utilities must be run as root.\n",
	'zpool failing'
);
{
	local $Monitoring::Sneck::Checks::zfs::ZPOOL = $FindBin::Bin . '/data/zfs/nope';
	like( $run->('ok')->{stdout}, qr/\AZFS UNKNOWN - \S+nope is not there\n\z/, 'zpool not there' );
}

done_testing();
