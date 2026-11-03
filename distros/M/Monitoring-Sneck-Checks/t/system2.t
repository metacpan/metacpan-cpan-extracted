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
use Monitoring::Sneck::Checks::swraid;
use Monitoring::Sneck::Checks::conntrack;
use Monitoring::Sneck::Checks::systemd_failed;
use Monitoring::Sneck::Checks::service;

my $dir   = TestTmp::dir();
my $data  = $FindBin::Bin . '/data';
my $write = sub {
	my ( $name, $content ) = @_;
	my $path = $dir . '/' . $name;
	make_path( $path =~ s{/[^/]+\z}{}r );
	open( my $fh, '>', $path ) or die($!);
	print $fh $content;
	close($fh);
	return $path;
};
local $Monitoring::Sneck::Checks::base::OS        = 'linux';
local $Monitoring::Sneck::Checks::base::PROC      = $dir . '/proc';
local $Monitoring::Sneck::Checks::base::STATE_DIR = $dir . '/state';
my $run = sub {
	my ( $check, @args ) = @_;
	return Monitoring::Sneck::Checks->run( check => $check, args => \@args );
};

# swraid
my $mdstat = sub {
	$write->(
		'proc/mdstat',
		"Personalities : [raid1] [raid6] [raid5] [raid0]\n" . join( "\n", @_ ) . "\nunused devices: <none>\n"
	);
};
$mdstat->(
	"md0 : active raid1 sdb1[1] sda1[0]\n      1048512 blocks super 1.2 [2/2] [UU]\n",
	"md1 : active raid0 sdc1[1] sdd1[0]\n      2097024 blocks super 1.2 512k chunks\n",
	"md2 : active raid6 sde1[3] sdf1[2] sdg1[1] sdh1[0]\n      4190208 blocks super 1.2 level 6, 512k chunk, algorithm 2 [4/4] [UUUU]\n      [==>..................]  check = 12.5% (262144/2095104) finish=1.2min speed=20000K/sec\n",
);
is(
	$run->('swraid')->{stdout},
	"SWRAID OK - md0 raid1 ok, md1 raid0 ok, md2 raid6 ok, check 12.5%\n",
	'all fine, a check running'
);
$mdstat->(
	"md0 : active raid1 sdb1[1](F) sda1[0]\n      1048512 blocks super 1.2 [2/1] [U_]\n",
	"md1 : active (auto-read-only) raid1 sdd1[2] sdc1[0]\n      1048512 blocks super 1.2 [2/1] [U_]\n      [=>...................]  recovery =  8.5% (89600/1048512) finish=0.5min speed=29866K/sec\n",
	"md2 : active raid5 sdf1[1] sde1[0] sdg1[2]\n      2095104 blocks super 1.2 level 5, 512k chunk, algorithm 2 [3/3] [UUU]\n      [===>.................]  resync = 17.3% (181248/1047552) finish=0.4min speed=36249K/sec\n",
	"md3 : inactive sdh1[0](S)\n      1048576 blocks super 1.2\n",
);
is(
	$run->( 'swraid', '-a', 'md9' )->{stdout},
	"SWRAID CRITICAL - md9 is not there, md0 raid1 degraded, 1 of 2 working, failed sdb1, md1 raid1 degraded, 1 of 2 working, recovery 8.5%, md2 raid5 resync 17.3%, md3 is inactive\n",
	'degraded, failed, rebuilding, resyncing, inactive, missing'
);
$mdstat->(
	"md2 : active raid5 sdf1[1] sde1[0] sdg1[2]\n      2095104 blocks [3/3] [UUU]\n      [===>.................]  resync = 17.3% (181248/1047552)\n"
);
is( $run->('swraid')->{code}, 1, 'resyncing alone is WARNING' );
unlink( $dir . '/proc/mdstat' );
is( $run->('swraid')->{stdout}, "SWRAID OK - no software RAID arrays\n", 'no md at all' );
{
	local $Monitoring::Sneck::Checks::base::OS        = 'freebsd';
	local $Monitoring::Sneck::Checks::swraid::GMIRROR = $data . '/swraid/gmirror';
	local $Monitoring::Sneck::Checks::swraid::GRAID   = $data . '/swraid/graid';
	is(
		$run->('swraid')->{stdout},
		"SWRAID CRITICAL - mirror/gm0 complete, mirror/gm1 degraded, ada3 synchronizing, 45%, mirror/gm2 degraded\n",
		'gmirror, graid not loaded'
	);
	$Monitoring::Sneck::Checks::swraid::GMIRROR = $data . '/swraid/nope';
	$Monitoring::Sneck::Checks::swraid::GRAID   = $data . '/swraid/graid_ok';
	is( $run->( 'swraid', '-a', 'raid/r0' )->{stdout}, "SWRAID OK - raid/r0 optimal\n", 'graid, gmirror not there' );
}

# conntrack
is( $run->('conntrack')->{stdout}, "CONNTRACK OK - conntrack is not loaded\n", 'not loaded' );
$write->( 'proc/sys/net/netfilter/nf_conntrack_count', "55000\n" );
$write->( 'proc/sys/net/netfilter/nf_conntrack_max',   "65536\n" );
is( $run->('conntrack')->{stdout},
	"CONNTRACK WARNING - conntrack 83.9% used, 55000 of 65536 | used=83.9%;80;90;0;100 entries=55000;;;0;65536\n",
	'Linux' );
{
	local $Monitoring::Sneck::Checks::base::OS         = 'freebsd';
	local $Monitoring::Sneck::Checks::conntrack::PFCTL = $data . '/conntrack/pfctl';
	is( $run->('conntrack')->{code}, 2, 'FreeBSD pf states' );
	like(
		$run->('conntrack')->{stdout},
		qr/\ACONNTRACK CRITICAL - pf states 95.0% used, 95000 of 100000/,
		'FreeBSD message'
	);
	$Monitoring::Sneck::Checks::conntrack::PFCTL = $data . '/conntrack/pfctl_off';
	is( $run->('conntrack')->{stdout}, "CONNTRACK OK - pf is not enabled\n", 'FreeBSD pf off' );
}

# oom
$write->( 'proc/vmstat', "nr_free_pages 1000\noom_kill 3\n" );
is( $run->('oom')->{stdout}, "OOM OK - first check, 3 OOM kills since boot | kills=0;0;;0\n", 'first check' );
is( $run->('oom')->{stdout}, "OOM OK - 0 OOM kills since the last check, 3 since boot | kills=0;0;;0\n", 'none since' );
$write->( 'proc/vmstat', "oom_kill 5\n" );
is( $run->( 'oom', '-H', 600 )->{stdout},
	"OOM WARNING - 2 OOM kills since the last check, 5 since boot | kills=2;0;;0\n", 'kills' );
like( $run->( 'oom', '-H', 600 )->{stdout},
	qr/\AOOM WARNING - 2 OOM kills since the last check, held from \d+ seconds ago, 5 since boot \|/, 'held' );
is( $run->('oom')->{code}, 0, 'not held without --hold' );
$write->( 'proc/vmstat', "oom_kill 1\n" );
like( $run->('oom')->{stdout}, qr/\AOOM OK - first check/, 'a reboot starts over' );
$write->( 'proc/vmstat', "nr_free_pages 1000\n" );
like( $run->('oom')->{stderr}, qr/does not count OOM kills/, 'old kernel' );

# systemd_failed
local $Monitoring::Sneck::Checks::systemd_failed::SYSTEMCTL = $data . '/systemd_failed/systemctl';
is(
	$run->('systemd_failed')->{stdout},
	"SYSTEMD_FAILED CRITICAL - 2 failed units, systemd-journal-flush.service, nginx.service | failed=2;;0;0\n",
	'failed units'
);
is( $run->( 'systemd_failed', '-x', 'flush', '-x', '^nginx' )->{stdout},
	"SYSTEMD_FAILED OK - 0 failed units | failed=0;;0;0\n", '--exclude' );
{
	local $Monitoring::Sneck::Checks::systemd_failed::SYSTEMCTL = $data . '/systemd_failed/systemctl_down';
	is(
		$run->('systemd_failed')->{stdout},
		qq{SYSTEMD_FAILED UNKNOWN - systemctl --failed exited 1, "System has not been booted with systemd"\n},
		'no systemd'
	);
}

# service
local $Monitoring::Sneck::Checks::service::SYSTEMCTL = $data . '/service/systemctl';
is( $run->( 'service', '-s', 'nginx', '-e' )->{stdout}, "SERVICE OK - nginx active\n", 'running and enabled' );
is(
	$run->( 'service', '-s', 'nginx', '-s', 'php8.4-fpm', '-s', 'web', '-s', 'nope' )->{stdout},
	"SERVICE CRITICAL - php8.4-fpm is failed, web is inactive, nope is not there\n",
	'not running'
);
{
	local $Monitoring::Sneck::Checks::service::SYSTEMCTL = $data . '/service/systemctl_not_enabled';
	is(
		$run->( 'service', '-s', 'cron', '-e' )->{stdout},
		"SERVICE CRITICAL - cron is running but not enabled\n",
		'not enabled'
	);
}
{
	local $Monitoring::Sneck::Checks::base::OS         = 'freebsd';
	local $Monitoring::Sneck::Checks::service::SERVICE = $data . '/service/service';
	is( $run->( 'service', '-s', 'sshd', '-e' )->{stdout}, "SERVICE OK - sshd running\n", 'FreeBSD' );
	is(
		$run->( 'service', '-s', 'nginx', '-s', 'nope' )->{stdout},
		"SERVICE CRITICAL - nginx is not running, nope is not there\n",
		'FreeBSD not running'
	);
	is(
		$run->( 'service', '-s', 'nginx', '-j', 'www' )->{stdout},
		"SERVICE OK - nginx running in jail www\n",
		'FreeBSD jail'
	);
}
like( $run->( 'service', '-s', 'nginx', '-j', 'www' )->{stderr}, qr/--jail is only for freebsd/, '--jail on Linux' );

done_testing();
