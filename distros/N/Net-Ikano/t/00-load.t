#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Ikano' );
}

diag( "Testing Net::Ikano $Net::Ikano::VERSION, Perl $], $^X" );
