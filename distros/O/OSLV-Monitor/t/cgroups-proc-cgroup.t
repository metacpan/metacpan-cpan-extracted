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

if ( !-r '/proc/' . $$ . '/cgroup' ) {
	plan skip_all => '/proc/<pid>/cgroup is not readable';
}

plan tests => 6;

my $base_dir = tempdir( CLEANUP => 1 );
my $obj      = OSLV::Monitor->new( base_dir => $base_dir );
my $backend  = OSLV::Monitor::Backends::cgroups->new( base_dir => $base_dir, obj => $obj );

#
# the unified line for this proc, if it is under the unified hierarchy at all
#

my $raw;
{
	open( my $fh, '<', '/proc/' . $$ . '/cgroup' ) || die($!);
	local $/;
	$raw = <$fh>;
	close($fh);
}
my @unified = grep( /^0\:\:\//, split( /\n/, $raw ) );

my $found = $backend->proc_cgroup($$);
if ( !@unified ) {
	is( $found, undef, 'no unified cgroup for this proc, so undef' );
} elsif ( $unified[0] eq '0::/' ) {
	is( $found, undef, 'this proc is in the root cgroup, so undef' );
} else {
	is( $found, $unified[0], 'the unified cgroup line for this proc is returned as is' );
}

# whatever is returned must be usable both for mapping and as a path
if ( defined($found) ) {
	like( $found, qr{^0\:\:/.}, 'what is returned is a unified cgroup path' );
	my ( $name, $stat_dir ) = $backend->cgroup_mapping($found);
	ok( defined($name) && $name ne '', 'what is returned maps to a name' );
} else {
	ok( 1, 'nothing returned to check the path of' );
	ok( 1, 'nothing returned to map' );
}

#
# bad and missing PIDs
#

is( $backend->proc_cgroup(undef), undef, 'a undef PID returns undef' );
is( $backend->proc_cgroup('foo'), undef, 'a non numeric PID returns undef' );

# reap a child so its PID is known to be gone
my $pid = fork();
if ( !defined($pid) ) {
	die('fork failed');
} elsif ( $pid == 0 ) {
	exit(0);
}
waitpid( $pid, 0 );
is( $backend->proc_cgroup($pid), undef, 'a PID that has exited returns undef' );
