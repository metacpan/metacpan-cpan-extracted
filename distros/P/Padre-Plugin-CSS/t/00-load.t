#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::CSS' );
}

diag( "Testing Padre::Plugin::CSS $Padre::Plugin::CSS::VERSION, Perl $], $^X" );
