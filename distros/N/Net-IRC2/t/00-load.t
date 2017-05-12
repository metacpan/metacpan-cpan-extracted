#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::IRC2' );
}

diag( "Testing Net::IRC2 $Net::IRC2::VERSION, Perl $], $^X" );
