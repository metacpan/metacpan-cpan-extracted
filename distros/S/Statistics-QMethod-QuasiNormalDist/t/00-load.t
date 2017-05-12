#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Statistics::QMethod::QuasiNormalDist' );
}

diag( "Testing Statistics::QMethod::QuasiNormalDist $Statistics::QMethod::QuasiNormalDist::VERSION, Perl $], $^X" );
