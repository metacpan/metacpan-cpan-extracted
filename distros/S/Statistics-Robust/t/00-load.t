#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Statistics::Robust' );
}

diag( "Testing Statistics::Robust $Statistics::Robust::VERSION, Perl $], $^X" );
