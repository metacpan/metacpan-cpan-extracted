#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use LWP::Online ':skip_all';
BEGIN {
	unless ( $^O eq 'MSWin32' ) {
		plan( skip_all => 'Not on Win32' );
		exit(0);
	}
	unless ( $ENV{RELEASE_TESTING} ) {
		plan( skip_all => 'No RELEASE_TESTING: Skipping very long test' );
		exit(0);
	}
	plan( tests => 6 );
}

use Perl::Dist::Vanilla   ();
use t::lib::Test          ();





#####################################################################
# Complete Generation Run

my $dist = Perl::Dist::Vanilla->new(
	t::lib::Test->paths(15),
);
isa_ok( $dist, 'Perl::Dist::Vanilla' );
ok( $dist->run, '->run ok' );
