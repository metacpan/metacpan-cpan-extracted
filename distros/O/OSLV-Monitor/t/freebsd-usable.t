#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use OSLV::Monitor;
use OSLV::Monitor::Backends::FreeBSD;

plan tests => 3;

my $base_dir = tempdir( CLEANUP => 1 );
my $obj      = OSLV::Monitor->new( base_dir => $base_dir, backend => 'FreeBSD' );
my $backend  = OSLV::Monitor::Backends::FreeBSD->new( base_dir => $base_dir, obj => $obj );

my $usable;
eval { $usable = $backend->usable; };
my $error = $@;

if ( $^O eq 'freebsd' ) {
	is( $usable, 1,  'usable returns 1 on freebsd' );
	is( $error,  '', 'usable does not die on freebsd' );

	# usable is what decides if the backend gets used, so jls being findable is
	# the whole of what it is checking for past the OS
	my $jls = `/bin/sh -c 'which jls 2> /dev/null'`;
	is( $?, 0, 'jls is in the path' );
} else {
	# anything other than freebsd has no jails, so this must not report as usable
	ok( !defined($usable), 'usable does not return on ' . $^O );
	ok( $error ne '',      'usable dies on ' . $^O );
	like( $error, qr/\Q$^O\E/, 'the death mentions what $^O is' );
}
