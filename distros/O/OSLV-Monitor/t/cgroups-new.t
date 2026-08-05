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

plan tests => 10;

my $base_dir = tempdir( CLEANUP => 1 );
my $obj = OSLV::Monitor->new( base_dir => $base_dir );

#
# obj is required and must be a OSLV::Monitor
#

my $backend;
eval { $backend = OSLV::Monitor::Backends::cgroups->new( base_dir => $base_dir ); };
ok( $@ ne '', 'new dies when obj is undef' );

eval { $backend = OSLV::Monitor::Backends::cgroups->new( base_dir => $base_dir, obj => $base_dir ); };
ok( $@ ne '', 'new dies when obj is not a OSLV::Monitor' );

#
# defaults
#

$backend = OSLV::Monitor::Backends::cgroups->new( base_dir => $base_dir, obj => $obj );
isa_ok( $backend, 'OSLV::Monitor::Backends::cgroups', 'new returns a backend' );
is( $backend->{cache_file},   $base_dir . '/linux_cache.json', 'cache_file is under base_dir' );
is( $backend->{time_divider}, 1000000,                         'time_divider defaults to 1000000' );

$backend = OSLV::Monitor::Backends::cgroups->new( obj => $obj );
is( $backend->{cache_file}, '/var/cache/oslv_monitor/linux_cache.json', 'base_dir defaults to /var/cache/oslv_monitor' );

#
# time_divider
#

$backend = OSLV::Monitor::Backends::cgroups->new( base_dir => $base_dir, obj => $obj, time_divider => 1000 );
is( $backend->{time_divider}, 1000, 'time_divider is settable' );

eval {
	$backend = OSLV::Monitor::Backends::cgroups->new( base_dir => $base_dir, obj => $obj, time_divider => 'foo' );
};
ok( $@ ne '', 'new dies when time_divider is not a number' );

#
# usable
#

$backend = OSLV::Monitor::Backends::cgroups->new( base_dir => $base_dir, obj => $obj );
my $usable;
eval { $usable = $backend->usable; };
is( $usable, 1,  'usable returns 1 on linux' );
is( $@,      '', 'usable does not die on linux' );
