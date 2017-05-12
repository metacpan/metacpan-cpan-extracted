#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::FSP' );
}

diag( "Testing Net::FSP $Net::FSP::VERSION, Perl $], $^X" );
