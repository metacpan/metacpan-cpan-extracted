#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Statistics::SDT' );
}

diag( "Testing Statistics::SDT $Statistics::SDT::VERSION, Perl $], $^X" );
