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

my $dir   = TestTmp::dir();
my $write = sub {
	my ( $name, $content ) = @_;
	open( my $fh, '>', $dir . '/' . $name ) or die($!);
	print $fh $content;
	close($fh);
};
my $run = sub {
	my ( $check, @args ) = @_;
	return Monitoring::Sneck::Checks->run( check => $check, args => \@args );
};

# a fake /proc
make_path( $dir . '/spl/kstat/zfs' );
$write->( 'loadavg', "3.50 2.25 1.00 2/345 6789\n" );
$write->( 'cpuinfo', "processor\t: 0\nmodel name\t: x\n\nprocessor\t: 1\nmodel name\t: x\n" );
$write->( 'meminfo', "MemTotal:        8388608 kB\nMemFree:          524288 kB\nMemAvailable:    1048576 kB\n" );
$write->( 'spl/kstat/zfs/arcstats',
	"13 1 0x01 123 33456 1 2\nname type data\nsize 4 3221225472\nc_min 4 1073741824\n" );
local $Monitoring::Sneck::Checks::base::PROC = $dir;
local $Monitoring::Sneck::Checks::base::OS   = 'linux';

# load
my $return = $run->('load');
is( $return->{code}, 0, 'load OK' );
is( $return->{stdout},
	"LOAD OK - load average 3.50, 2.25, 1.00 | load1=3.50;15;30;0 load5=2.25;10;25;0 load15=1.00;5;20;0\n",
	'output' );
is( $run->( 'load', '-w', '3,9,9' )->{code}, 1, 'over the 1 minute warning' );
is( $run->( 'load', '-w', '1,1,1', '-c', '9,2,9' )->{code}, 2, 'over the 5 minute critical' );
like( $run->( 'load', '-r', '-w', '1.5,1,1' )->{stdout},
	qr/\ALOAD WARNING - load average 1.75, 1.12, 0.50 per CPU, of 2 \|/, '--per-cpu' );
is( $run->( 'load', '-w', '1,2' )->{code}, 3, 'bad limits' );

# memory
$return = $run->('memory');
is( $return->{code}, 0, '87.5% used is OK' );
is( $return->{stdout},
	"MEMORY OK - 87.5% used, 7168 of 8192 MiB | used=87.5%;90;95;0;100 used_bytes=7516192768B;;;0;8589934592\n",
	'output' );
is( $run->( 'memory', '-w', 80 )->{code}, 1, 'over 80% is WARNING' );
like( $run->( 'memory', '-a', '-w', 80 )->{stdout},
	qr/\AMEMORY OK - 62.5% used, 5120 of 8192 MiB, ARC over its minimum as available \|/, '--arc' );
$write->(
	'meminfo',
	"MemTotal:        8388608 kB\nMemFree:          524288 kB\nBuffers:          524288 kB\nCached:          1048576 kB\n"
);
like( $run->('memory')->{stdout}, qr/ - 75.0% used/, 'no MemAvailable' );

# FreeBSD, through a fake BSD::Sysctl
my %sysctl = (
	'vm.loadavg'                    => [ 0.5, 0.25, 0.125 ],
	'hw.ncpu'                       => 4,
	'hw.pagesize'                   => 4096,
	'hw.physmem'                    => 4294967296,
	'vm.stats.vm.v_free_count'      => 131072,
	'vm.stats.vm.v_inactive_count'  => 131072,
	'kstat.zfs.misc.arcstats.size'  => 2147483648,
	'kstat.zfs.misc.arcstats.c_min' => 536870912,
);
{
	no warnings 'once';
	$INC{'BSD/Sysctl.pm'} = __FILE__;
	*BSD::Sysctl::sysctl = sub { return $sysctl{ $_[0] } };
}
{
	local $Monitoring::Sneck::Checks::base::OS = 'freebsd';
	like( $run->( 'load', '-r' )->{stdout},   qr/ - load average 0.12, 0.06, 0.03 per CPU, of 4 \|/, 'FreeBSD load' );
	like( $run->('memory')->{stdout},         qr/\AMEMORY OK - 75.0% used, 3072 of 4096 MiB \|/,     'FreeBSD memory' );
	like( $run->( 'memory', '-a' )->{stdout}, qr/ - 37.5% used/,                                     'FreeBSD --arc' );
	delete( $sysctl{'hw.ncpu'} );
	like( $run->( 'load', '-r' )->{stderr}, qr/\ALOAD UNKNOWN - no sysctl hw.ncpu/, 'missing sysctl' );
}
{
	local $Monitoring::Sneck::Checks::base::OS = 'solaris';
	like( $run->('load')->{stderr}, qr/\ALOAD UNKNOWN - not supported on solaris/, 'other OSes' );
}

# swap, on Linux
$write->( 'meminfo', "MemTotal:        8388608 kB\nSwapTotal:       2097152 kB\nSwapFree:         524288 kB\n" );
$return = $run->('swap');
is( $return->{code}, 0, '75% swap used is OK' );
is( $return->{stdout},
	"SWAP OK - 75.0% used, 1536 of 2048 MiB | used=75.0%;80;90;0;100 used_bytes=1610612736B;;;0;2147483648\n",
	'output' );
is( $run->( 'swap', '-w', 50 )->{code}, 1, 'over 50% is WARNING' );
$write->( 'meminfo', "MemTotal:        8388608 kB\nSwapTotal:             0 kB\nSwapFree:              0 kB\n" );
is( $run->('swap')->{stdout}, "SWAP OK - no swap\n", 'no swap is OK' );
is( $run->( 'swap', '-n', 'critical' )->{code}, 2, 'or as --no-swap says' );
is( $run->( 'swap', '-n', 'maybe' )->{code},    3, 'bad --no-swap' );

# swap, on FreeBSD, through a stand in for swapinfo
my $swapinfo = sub {
	my ( $name, $exit, $output ) = @_;
	$write->( $name, '#!' . $^X . "\nprint <<'END';\n" . $output . "END\nexit " . $exit . ";\n" );
	chmod( 0755, $dir . '/' . $name );
	return $dir . '/' . $name;
};
{
	local $Monitoring::Sneck::Checks::base::OS       = 'freebsd';
	local $Monitoring::Sneck::Checks::swap::SWAPINFO = $swapinfo->( 'swapinfo', 0, <<'END' );
Device          1K-blocks     Used    Avail Capacity
/dev/ada0p3       2097152  1048576  1048576    50%
/dev/ada1p3       2097152        0  2097152     0%
Total             4194304  1048576  3145728    25%
END
	is(
		$run->('swap')->{stdout},
		"SWAP OK - 25.0% used, 1024 of 4096 MiB | used=25.0%;80;90;0;100 used_bytes=1073741824B;;;0;4294967296\n",
		'FreeBSD, the devices added up, Total skipped'
	);
	$Monitoring::Sneck::Checks::swap::SWAPINFO
		= $swapinfo->( 'swapinfo_none', 0, "Device          1K-blocks     Used    Avail Capacity\n" );
	is( $run->('swap')->{stdout}, "SWAP OK - no swap\n", 'FreeBSD with no swap' );
	$Monitoring::Sneck::Checks::swap::SWAPINFO = $swapinfo->( 'swapinfo_fails', 1, "" );
	like( $run->('swap')->{stderr}, qr/\ASWAP UNKNOWN - \S+swapinfo_fails exited 1\n\z/, 'swapinfo failing' );
	$Monitoring::Sneck::Checks::swap::SWAPINFO = $dir . '/nope';
	like( $run->('swap')->{stderr}, qr/\ASWAP UNKNOWN - can not run \S+nope/, 'swapinfo missing' );
}

# disk, on the temp dir
SKIP: {
	skip( 'needs Filesys::Df', 6 ) if !eval { require Filesys::Df; 1 };
	my $df = Filesys::Df::df( $dir, 1 );
	$return = $run->( 'disk', '-p', $dir, '-w', 100, '-c', 100 );
	is( $return->{code}, 0, 'disk OK' );
	like( $return->{stdout},
		qr/\ADISK OK - \Q$dir\E $df->{per}% used of [0-9.]+ [KMGTP]iB \| '?\Q$dir\E'?=$df->{per}%;100;100;0;100/,
		'output' );
	is( $run->( 'disk', '-p', $dir, '-w', '@0:100' )->{code}, 1, 'WARNING' );
	is( $run->( 'disk', '-p', $dir, '-c', '@0:100' )->{code}, 2, 'CRITICAL' );
	is( $run->( 'disk', '-p', $dir, '-w', 100, '-c', 100, '-K', '@0:100' )->{code}, 2, 'inodes CRITICAL' );
	like(
		$run->( 'disk', '-p', $dir . '/nope' )->{stdout},
		qr/\ADISK CRITICAL - \S+nope can not be looked at/,
		'missing path'
	);
} ## end SKIP:

# procs, with a child to find
my $marker = 'sneck_checks_test_' . $$;
my $pid    = fork();
die($!) if !defined($pid);
if ( !$pid ) {
	exec( $^X, '-e', 'sleep 30', $marker );
}
END { kill( 'TERM', $pid ) if $pid }
select( undef, undef, undef, 0.3 );
$return = $run->( 'procs', '-r', $marker, '-c', '1:1' );
is( $return->{code},   0,                                                                    'found it' );
is( $return->{stdout}, 'PROCS OK - 1 process matching /' . $marker . "/ | procs=1;;1:1;0\n", 'output' );
is( $run->( 'procs', '-r', $marker, '-u', $<, '-s', 'S' )->{code}, 0,                        'user and state' );
is( $run->( 'procs', '-r', $marker, '-s', 'Z' )->{code},           2,                        'not a zombie, so none' );
is( $run->( 'procs', '-r', $marker . 'x' )->{code},                2,                        'none is CRITICAL' );
is( $run->( 'procs', '-r', $marker, '-w', '2:' )->{code},          1,                        'too few is WARNING' );
like(
	$run->( 'procs', '-r', $marker, '--rss-warning', '@0:100000' )->{stdout},
	qr/\APROCS WARNING - 1 process matching \/\Q$marker\E\/, most memory [0-9.]+ MiB by $pid \| procs=1;;1:;0 rss_max=[0-9.]+;\@0:100000;;0\n\z/,
	'--rss-warning'
);
is( $run->( 'procs', '-r', $marker, '--cpu-critical', '@0:100' )->{code},                        2, '--cpu-critical' );
is( $run->( 'procs', '-r', $marker, '--rss-critical', '100000', '--cpu-warning', '99' )->{code}, 0, 'within both' );
is( $run->( 'procs', '--rss-warning', 'x' )->{code}, 3, 'bad --rss-warning' );
is( $run->( 'procs', '-s', 'Q' )->{code},            3, 'bad state' );

done_testing();
