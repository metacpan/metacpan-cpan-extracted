#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use OSLV::Monitor;
use OSLV::Monitor::Backends::FreeBSD;

# nothing here shells out to anything, so it is checkable regardless of the OS

plan tests => 8;

my $base_dir = tempdir( CLEANUP => 1 );
my $obj = OSLV::Monitor->new( base_dir => $base_dir, backend => 'FreeBSD' );

#
# obj is required and must be a OSLV::Monitor
#

my $backend;
eval { $backend = OSLV::Monitor::Backends::FreeBSD->new( base_dir => $base_dir ); };
ok( $@ ne '', 'new dies when obj is undef' );

eval { $backend = OSLV::Monitor::Backends::FreeBSD->new( base_dir => $base_dir, obj => $base_dir ); };
ok( $@ ne '', 'new dies when obj is not a OSLV::Monitor' );

#
# defaults
#

$backend = OSLV::Monitor::Backends::FreeBSD->new( base_dir => $base_dir, obj => $obj );
isa_ok( $backend, 'OSLV::Monitor::Backends::FreeBSD', 'new returns a backend' );
is( $backend->{proc_cache}, $base_dir . '/freebsd_proc_cache.json', 'proc_cache is under base_dir' );
is( $backend->{version},    1,                                     'version is 1' );
is( $backend->{obj},        $obj,                                  'the OSLV::Monitor object is saved' );

$backend = OSLV::Monitor::Backends::FreeBSD->new( obj => $obj );
is( $backend->{proc_cache}, '/var/cache/oslv_monitor/freebsd_proc_cache.json',
	'base_dir defaults to /var/cache/oslv_monitor' );

#
# time_divider is not used by this backend, but OSLV::Monitor->load always passes
# it, so it must not choke on it
#

eval {
	$backend = OSLV::Monitor::Backends::FreeBSD->new( base_dir => $base_dir, obj => $obj, time_divider => 1000000 );
};
is( $@, '', 'new does not die when passed a time_divider' );
