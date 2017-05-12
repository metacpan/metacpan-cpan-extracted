#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::CallFlow' );
}

diag( "Testing Test::CallFlow $Test::CallFlow::VERSION, Perl $], $^X" );
