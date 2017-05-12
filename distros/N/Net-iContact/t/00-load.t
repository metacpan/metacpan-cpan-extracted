#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::iContact' );
}

diag( "Testing Net::iContact $Net::iContact::VERSION, Perl $], $^X" );
