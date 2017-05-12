#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::validMX' );
}

diag( "Testing Net::validMX $Net::validMX::VERSION, Perl $], $^X" );
