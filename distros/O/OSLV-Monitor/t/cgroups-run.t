#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use OSLV::Monitor;
use OSLV::Monitor::Backends::cgroups;

if ( $^O ne 'linux' ) {
	plan skip_all => 'not linux';
}

if ( !-f '/sys/fs/cgroup/cgroup.controllers' ) {
	plan skip_all => 'cgroup v2 is not mounted at /sys/fs/cgroup';
}

my $ps_test = `ps -haxo pid 2> /dev/null`;
if ( $? != 0 || !defined($ps_test) || $ps_test !~ /\d/ ) {
	plan skip_all => 'ps is not usable';
}

plan tests => 15;

my $base_dir = tempdir( CLEANUP => 1 );
my $obj      = OSLV::Monitor->new( base_dir => $base_dir );

#
# every dir under /sys/fs/cgroup is a cgroup that could turn up in
# /proc/<pid>/cgroup, so the name and stat dir for each must be usable... a stat
# dir that does not exist is what the truncated cgroup column from ps produced,
# which meant cpu.stat, memory.stat, and io.stat were never read
#

my $backend = OSLV::Monitor::Backends::cgroups->new( base_dir => $base_dir, obj => $obj );

my @found_dirs;
my @to_check = ('/sys/fs/cgroup');
while ( defined( my $dir = shift(@to_check) ) ) {
	foreach my $item ( glob( $dir . '/*' ) ) {
		if ( -d $item ) {
			push( @found_dirs, $item );
			push( @to_check,   $item );
		}
	}
}

my @no_name;
my @missing_dirs;
foreach my $dir (@found_dirs) {
	my $cgroup = $dir;
	$cgroup =~ s/^\/sys\/fs\/cgroup//;
	my ( $name, $stat_dir ) = $backend->cgroup_mapping( '0::' . $cgroup );
	if ( !defined($name) || $name eq '' ) {
		push( @no_name, $cgroup );
		next;
	}
	if ( !defined($stat_dir) || !-d '/sys/fs/cgroup' . $stat_dir ) {
		push( @missing_dirs, $cgroup . ' -> ' . ( defined($stat_dir) ? $stat_dir : 'undef' ) );
	}
}

ok( scalar(@found_dirs) > 0, 'found cgroups under /sys/fs/cgroup to check' );
is( join( ', ', @no_name ),      '', 'every cgroup maps to a name' );
is( join( ', ', @missing_dirs ), '', 'every cgroup maps to a stat dir that exists' );

#
# the first run has no cache to compute deltas against, so nothing is reported
#

my $data = $backend->run;
is( ref($data),                   'HASH',  'run returns a hash ref' );
is( join( ', ', @{ $data->{errors} } ), '', 'the first run has no errors' );
is( scalar( keys( %{ $data->{oslvms} } ) ), 0, 'the first run reports no oslvms' );
is( $data->{totals}{procs},             0,  'the first run has zeroed totals' );
ok( -f $base_dir . '/linux_cache.json', 'the first run saved the cache' );

#
# the second run has the cache from the first, so it reports for real... a fresh
# backend object is used as that is how it is polled
#

$backend = OSLV::Monitor::Backends::cgroups->new( base_dir => $base_dir, obj => $obj );
$data    = $backend->run;

is( join( ', ', @{ $data->{errors} } ), '', 'the second run has no errors' );
ok( scalar( keys( %{ $data->{oslvms} } ) ) > 0, 'the second run reports oslvms' );

my @bad_names;
my @bad_paths;
my $procs = 0;
foreach my $name ( keys( %{ $data->{oslvms} } ) ) {
	if ( $name eq '' ) {
		push( @bad_names, '<empty>' );
	}
	if (   ref( $data->{oslvms}{$name}{path} ) ne 'ARRAY'
		|| !defined( $data->{oslvms}{$name}{path}[0] ) )
	{
		push( @bad_paths, $name );
	}
	$procs = $procs + $data->{oslvms}{$name}{procs};
}

is( join( ', ', @bad_names ), '', 'no oslvm has a empty name' );
is( join( ', ', @bad_paths ), '', 'every oslvm has a path' );

# every cgroup mapping to a name has its procs summed into that name, so this
# only holds if they are not overwriting each other
is( $procs, $data->{totals}{procs}, 'the procs for each oslvm sum to the total' );

#
# every cgroup the run recorded must be a real cgroup and not a mangled one...
# when the cgroup came from ps it was truncated to 27 characters, which left
# these as paths that do not exist
#

my %current_cgroups;
foreach my $proc ( glob('/proc/[0-9]*') ) {
	my $raw;
	eval {
		open( my $fh, '<', $proc . '/cgroup' ) || die($!);
		local $/;
		$raw = <$fh>;
		close($fh);
	};
	if ( defined($raw) ) {
		foreach my $line ( split( /\n/, $raw ) ) {
			if ( $line =~ /^0\:\:\// ) {
				$current_cgroups{$line} = 1;
			}
		}
	}
} ## end foreach my $proc ( glob('/proc/[0-9]*') )

my @mangled;
my $longest = 0;
foreach my $cgroup ( keys( %{ $backend->{mappings} } ) ) {
	if ( length($cgroup) > $longest ) {
		$longest = length($cgroup);
	}
	my $path = $cgroup;
	$path =~ s/^0\:\://;
	if ( -d '/sys/fs/cgroup' . $path ) {
		next;
	}
	# the dir for it is gone, so either the cgroup went away between the run and
	# now, which is fine, or it was cut short, which shows up as it being the
	# start of a cgroup that is still around
	foreach my $current ( keys(%current_cgroups) ) {
		if ( length($current) > length($cgroup) && index( $current, $cgroup ) == 0 ) {
			push( @mangled, $cgroup . ' is the start of ' . $current );
			last;
		}
	}
} ## end foreach my $cgroup ( keys( %{ $backend->{mappings}...}))

is( join( ', ', @mangled ), '', 'every cgroup that was recorded is a real cgroup' );

# if nothing on this system has a cgroup of over 27 characters then the above
# would pass even with the truncation in place
ok( $longest > 27, 'a cgroup of over 27 characters, where ps truncated, was recorded' );
