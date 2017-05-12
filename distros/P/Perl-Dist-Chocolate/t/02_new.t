#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	unless ( $^O eq 'MSWin32' ) {
		plan( skip_all => 'Not on Win32' );
		exit(0);
	}
	plan( tests => 8 );
}

use File::Spec::Functions ':ALL';
use Perl::Dist::Chocolate ();
use t::lib::Test          ();

ok( -d catdir(qw{ t data cpan }), 'Found CPAN data directory' );





#####################################################################
# Constructor Test

my $dist = t::lib::Test->new1(2);
isa_ok( $dist, 'Perl::Dist::Chocolate' );
