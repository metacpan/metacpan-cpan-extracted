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
use Monitoring::Sneck::Checks::containers;
use Monitoring::Sneck::Checks::jails;
use Monitoring::Sneck::Checks::swap;

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
my %sysctl;
{
	no warnings 'once';
	$INC{'BSD/Sysctl.pm'} = __FILE__;
	*BSD::Sysctl::sysctl = sub { return $sysctl{ $_[0] } };
}

# pressure
my $psi = sub {
	my ( $resource, $some, $full ) = @_;
	$write->(
		'proc/pressure/' . $resource,
		"some avg10=$some avg60=$some avg300=1.00 total=1000\nfull avg10=$full avg60=$full avg300=0.50 total=500\n"
	);
};
$psi->( 'cpu',    '5.00',  '0.00' );
$psi->( 'memory', '25.50', '10.00' );
$psi->( 'io',     '1.00',  '0.50' );
is(
	$run->('pressure')->{stdout},
	"PRESSURE WARNING - some stalled over 60 seconds, cpu 5.00%, memory 25.50%, io 1.00% | cpu_some=5.00%;20;50;0;100 memory_some=25.50%;20;50;0;100 io_some=1.00%;20;50;0;100\n",
	'some, avg60'
);
is(
	$run->( 'pressure', '-k', 'full', '-w', 5, '-c', 9 )->{stdout},
	"PRESSURE CRITICAL - full stalled over 60 seconds, memory 10.00%, io 0.50% | memory_full=10.00%;5;9;0;100 io_full=0.50%;5;9;0;100\n",
	'full leaves out cpu'
);
is(
	$run->( 'pressure', '-r', 'memory', '--memory-warning', 30, '-a', 300 )->{stdout},
	"PRESSURE OK - some stalled over 300 seconds, memory 1.00% | memory_some=1.00%;30;50;0;100\n",
	'one resource, its own range, avg300'
);
is( $run->( 'pressure', '-r', 'disk' )->{code}, 3, 'bad --resource' );
is( $run->( 'pressure', '-a', 5 )->{code},      3, 'bad --average' );
is(
	$run->( 'pressure', '-r', 'cpu', '-k', 'full' )->{stderr},
	"PRESSURE UNKNOWN - nothing to check, as full is left out for cpu\n",
	'full with only cpu is nothing to check'
);
is(
	$run->( 'pressure', '-r', 'cpu', '-r', 'io', '-k', 'full' )->{stdout},
	"PRESSURE OK - full stalled over 60 seconds, io 0.50% | io_full=0.50%;20;50;0;100\n",
	'full with cpu and io checks io'
);
unlink( $dir . '/proc/pressure/io' );
like( $run->('pressure')->{stderr}, qr/no pressure stall information/, 'no PSI' );

# neighbors
my $neighbors = sub {
	my ( $arp_entries, $arp_fulls ) = @_;
	my $header
		= "entries  allocs   destroys hash_grows lookups  hits     res_failed rcv_probes_mcast rcv_probes_ucast periodic_gc_runs forced_gc_runs unresolved_discards table_fulls\n";
	my $row = sub {
		sprintf(
			'%08x 000000a9 0000005f 00000000 00643730 00109f4c 00000056 00000000 00000000 00083eb0 00000000 00000000 %08x',
			@_ ) . "\n";
	};
	$write->( 'proc/net/stat/arp_cache',   $header . $row->( $arp_entries, $arp_fulls ) . $row->( $arp_entries, 0 ) );
	$write->( 'proc/net/stat/ndisc_cache', $header . $row->( 10,           0 ) );
}; ## end $neighbors = sub
$neighbors->( 900, 0 );
$write->( 'proc/sys/net/ipv4/neigh/default/gc_thresh3', "1024\n" );
$write->( 'proc/sys/net/ipv6/neigh/default/gc_thresh3', "1024\n" );
is(
	$run->('neighbors')->{stdout},
	"NEIGHBORS WARNING - arp 900 of 1024, ndp 10 of 1024 | arp=87.9%;80;90;0;100 ndp=1.0%;80;90;0;100\n",
	'how full'
);
$neighbors->( 100, 3 );
is(
	$run->('neighbors')->{stdout},
	"NEIGHBORS CRITICAL - arp 100 of 1024, full 3 times since the last check, ndp 10 of 1024 | arp=9.8%;80;90;0;100 ndp=1.0%;80;90;0;100\n",
	'table fulls since the last check'
);
is( $run->('neighbors')->{code}, 0, 'no new fulls' );

# swap rates
$write->( 'proc/meminfo', "MemTotal: 8388608 kB\nSwapTotal: 2097152 kB\nSwapFree: 2097152 kB\n" );
$write->( 'proc/vmstat',  "pswpin 100\npswpout 200\n" );
like(
	$run->( 'swap', '-W', 10 )->{stdout},
	qr/\ASWAP OK - 0.0% used, 0 of 2048 MiB, no swap rate yet \|/,
	'no rate the first time'
);
$write->( 'proc/vmstat', "pswpin 1000100\npswpout 2000200\n" );
like( $run->( 'swap', '-W', 10 )->{stdout},
	qr/\ASWAP WARNING - .*, swapping [0-9.]+ pages\/s in and [0-9.]+ out \| swap_in=/, 'swapping' );
like( $run->('swap')->{stdout}, qr/\ASWAP OK - 0.0% used, 0 of 2048 MiB \|/, 'no rate without the options' );
{
	local $Monitoring::Sneck::Checks::base::OS       = 'freebsd';
	local $Monitoring::Sneck::Checks::swap::SWAPINFO = $data . '/swap/swapinfo';
	%sysctl = ( 'vm.stats.vm.v_swappgsin' => 5, 'vm.stats.vm.v_swappgsout' => 7 );
	like( $run->( 'swap', '-C', 1 )->{stdout}, qr/no swap rate yet/, 'FreeBSD, a reboot starts over' );
}

# procs open files, through a fake /proc for a child
my $marker = 'sneck_checks_fds_' . $$;
my $pid    = fork();
die($!)                                if !defined($pid);
exec( $^X, '-e', 'sleep 30', $marker ) if !$pid;
END { kill( 'TERM', $pid ) if $pid }
select( undef, undef, undef, 0.3 );
$write->( 'proc/' . $pid . '/fd/' . $_, '' ) foreach 0 .. 8;
$write->(
	'proc/' . $pid . '/limits',
	"Limit                     Soft Limit           Hard Limit           Units\nMax open files            10                   4096                 files\n"
);
is(
	$run->( 'procs', '-r', $marker, '--fd-warning', 80, '--fd-critical', 95 )->{stdout},
	"PROCS WARNING - 1 process matching /$marker/, most of its open file limit 90.0% by $pid, 9 of 10 | procs=1;;1:;0 fd_max=90.0%;80;95;0\n",
	'--fd-warning'
);
unlink( $dir . '/proc/' . $pid . '/limits' );
like( $run->( 'procs', '-r', $marker, '--fd-warning', 80 )->{stdout},
	qr/, 1 could not be read for open files \|/, 'unreadable' );
{
	local $Monitoring::Sneck::Checks::base::OS = 'freebsd';
	like( $run->( 'procs', '--fd-warning', 80 )->{stderr}, qr/only for linux/, 'not on FreeBSD' );
}

# containers
local $Monitoring::Sneck::Checks::containers::RUNTIMES{docker} = $data . '/containers/docker';
local $Monitoring::Sneck::Checks::containers::RUNTIMES{podman} = $data . '/containers/nope';
is(
	$run->( 'containers', '-n', 'web', '-n', 'old', '-n', 'cache', '-x', '^build' )->{stdout},
	"CONTAINERS CRITICAL - 3 of 5 containers running, old is exited, cache is not there, db is unhealthy, worker is restarting | running=3;;;0\n",
	'containers'
);
is( $run->( 'containers', '-n', 'web', '-x', '^(build|db|worker)' )->{code}, 0, 'OK' );
is(
	$run->( 'containers', '-r', 'podman' )->{stdout},
	"CONTAINERS UNKNOWN - podman is not there\n",
	'runtime not there'
);
{
	local $Monitoring::Sneck::Checks::containers::RUNTIMES{docker} = $data . '/containers/docker_denied';
	like(
		$run->('containers')->{stdout},
		qr/\ACONTAINERS UNKNOWN - docker ps exited 1, "permission denied/,
		'no access'
	);
}

# jails
{
	local $Monitoring::Sneck::Checks::base::OS           = 'freebsd';
	local $Monitoring::Sneck::Checks::jails::JLS         = $data . '/jails/jls';
	local $Monitoring::Sneck::Checks::jails::VM          = $data . '/jails/vm';
	local $Monitoring::Sneck::Checks::jails::JAIL_CONF   = $data . '/jails/jail.conf';
	local $Monitoring::Sneck::Checks::jails::JAIL_CONF_D = $data . '/jails/jail.conf.d';
	is_deeply(
		[ Monitoring::Sneck::Checks::jails->new( args => ['-a'] )->configured ],
		[ 'db', 'mail', 'www' ],
		'jail.conf parsed'
	);
	is( $run->( 'jails', '-j', 'www', '-j', 'db' )->{stdout}, "JAILS OK - 2 jails running\n", 'jails running' );
	is(
		$run->( 'jails', '-a' )->{stdout},
		"JAILS CRITICAL - 2 jails running, jail mail is not running\n",
		'--all-configured'
	);
	is( $run->( 'jails', '-a', '-x', 'mail' )->{code}, 0, '--exclude' );
	is( $run->( 'jails', '-v', 'router', '-v', 'nas', '-v', 'gone' )->{stdout},
		"JAILS CRITICAL - 1 VMs running, VM nas is stopped, VM gone is not there\n", 'VMs' );
	is(
		$run->( 'jails', '-a', '-x', 'mail', '-x', 'www', '-x', 'db' )->{stdout},
		"JAILS UNKNOWN - every configured jail is excluded\n",
		'everything excluded'
	);
	{
		local $Monitoring::Sneck::Checks::jails::JAIL_CONF   = $data . '/jails/empty.conf';
		local $Monitoring::Sneck::Checks::jails::JAIL_CONF_D = $data . '/jails/empty.d';
		is(
			$run->( 'jails', '-a' )->{stdout},
			"JAILS UNKNOWN - no jails configured in $data/jails/empty.conf or $data/jails/empty.d\n",
			'nothing configured'
		);
		is(
			$run->( 'jails', '-a', '-v', 'router' )->{stdout},
			"JAILS UNKNOWN - 1 VMs running, no jails configured in $data/jails/empty.conf or $data/jails/empty.d\n",
			'nothing configured, but a VM to check'
		);
	}
}
like( $run->( 'jails', '-j', 'www' )->{stderr}, qr/not supported on linux/, 'Linux' );
is( $run->('jails')->{code}, 3, 'nothing to check' );

done_testing();
