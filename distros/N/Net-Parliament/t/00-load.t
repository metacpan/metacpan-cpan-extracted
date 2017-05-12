#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Parliament' );
}

diag( "Testing Net::Parliament $Net::Parliament::VERSION, Perl $], $^X" );
