#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Nabaztag' );
}

diag( "Testing Nabaztag $Nabaztag::VERSION, Perl $], $^X" );
