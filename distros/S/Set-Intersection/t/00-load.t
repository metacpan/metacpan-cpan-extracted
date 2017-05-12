#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Set::Intersection' );
}

ok $Set::Intersection::VERSION;

diag( "Testing Set::Intersection $Set::Intersection::VERSION, Perl $], $^X" );

