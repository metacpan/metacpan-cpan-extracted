#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Params::Clean' );
}

diag( "Testing Params::Clean $Params::Clean::VERSION, Perl $], $^X" );
