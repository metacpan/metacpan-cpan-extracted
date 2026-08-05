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

plan tests => 17;

my $base_dir = tempdir( CLEANUP => 1 );
my $obj      = OSLV::Monitor->new( base_dir => $base_dir );

sub new_backend {
	my %opts = @_;
	return OSLV::Monitor::Backends::cgroups->new( base_dir => $base_dir, obj => $obj, %opts );
}

#
# anything not in the counters list is a gauge and is returned as is
#

my $backend = new_backend();
is( $backend->cache_process( 'cgroup-/foo', 'anon', 12345 ), 12345, 'a gauge is returned as is' );
ok( !defined( $backend->{new_cache}{'cgroup-/foo'} ), 'a gauge is not saved to the cache' );

#
# missing args
#

{
	local $SIG{__WARN__} = sub { };
	is( $backend->cache_process( 'cgroup-/foo', 'rbytes', undef ), 0, 'a undef value returns 0' );
	is( $backend->cache_process( undef,         'rbytes', 1 ),     0, 'a undef name returns 0' );
}

#
# a counter with nothing cached for it yet... the raw value is always saved for
# the next run to compute a delta against
#

$backend = new_backend();
is( $backend->cache_process( 'cgroup-/foo', 'rbytes', 600 ), 0, 'a new counter of unknown age returns 0' );
is( $backend->{new_cache}{'cgroup-/foo'}{rbytes}, 600, 'the raw value for a new counter is cached' );

$backend = new_backend();
is( $backend->cache_process( 'cgroup-/foo', 'rbytes', 600, 400 ), 0, 'a new counter older than 300 returns 0' );

$backend = new_backend();
is( $backend->cache_process( 'cgroup-/foo', 'rbytes', 600, 100 ), 2, 'a new counter younger than 300 is a rate' );

#
# a counter with a previous value is the delta over the 300 second interval
#

$backend = new_backend();
$backend->{cache}{'cgroup-/foo'}{rbytes} = 100;
is( $backend->cache_process( 'cgroup-/foo', 'rbytes', 400 ), 1, 'a counter delta is per second over 300' );
is( $backend->{new_cache}{'cgroup-/foo'}{rbytes}, 400, 'the raw value and not the delta is cached' );

$backend = new_backend();
$backend->{cache}{'cgroup-/foo'}{rbytes} = 400;
is( $backend->cache_process( 'cgroup-/foo', 'rbytes', 400 ), 0, 'a counter that did not move returns 0' );

# went backwards, so the cgroup was recreated and the raw value is what has
# accrued since then
$backend = new_backend();
$backend->{cache}{'cgroup-/foo'}{rbytes} = 1000;
is( $backend->cache_process( 'cgroup-/foo', 'rbytes', 300 ), 1, 'a reset counter uses the raw value' );

#
# usec counters are converted to seconds with the time divider
#

$backend = new_backend();
$backend->{cache}{'cgroup-/foo'}{'cpu-time'} = 0;
is( $backend->cache_process( 'cgroup-/foo', 'cpu-time', 300000000 ), 1, 'cpu-time is divided by the time divider' );

$backend = new_backend( time_divider => 1000 );
$backend->{cache}{'cgroup-/foo'}{'cpu-time'} = 0;
is( $backend->cache_process( 'cgroup-/foo', 'cpu-time', 300000 ), 1, 'a non default time divider is used' );

#
# garbage is discarded, but the raw value is still cached so the delta for the
# next run is sane
#

$backend = new_backend();
$backend->{cache}{'cgroup-/foo'}{rbytes} = 0;
is( $backend->cache_process( 'cgroup-/foo', 'rbytes', 10000000000000000 ), 0, 'a garbage value returns 0' );
is( $backend->{new_cache}{'cgroup-/foo'}{rbytes}, 10000000000000000, 'the raw garbage value is still cached' );

#
# the cache is per name, so two names do not step on each other
#

$backend = new_backend();
$backend->{cache}{'cgroup-/foo'}{rbytes} = 100;
$backend->{cache}{'cgroup-/bar'}{rbytes} = 700;
$backend->cache_process( 'cgroup-/foo', 'rbytes', 400 );
is( $backend->cache_process( 'cgroup-/bar', 'rbytes', 1000 ), 1, 'each name has its own cached value' );
