#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Scaffold' );
}

diag( "Testing Scaffold $Scaffold::VERSION, Perl $], $^X" );
