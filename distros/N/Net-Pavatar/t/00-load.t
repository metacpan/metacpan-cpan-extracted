#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Pavatar' );
}

diag( "Testing Net::Pavatar $Net::Pavatar::VERSION, Perl $], $^X" );
