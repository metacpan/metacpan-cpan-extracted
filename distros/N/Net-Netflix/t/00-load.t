#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Netflix' );
}

diag( "Testing Net::Netflix $Net::Netflix::VERSION, Perl $], $^X" );
