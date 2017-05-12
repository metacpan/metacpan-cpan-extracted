#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'SNA::Network' );
}

diag( "Testing SNA::Network $SNA::Network::VERSION, Perl $], $^X" );
