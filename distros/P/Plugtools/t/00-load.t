#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Plugtools' );
}

diag( "Testing Plugtools $Plugtools::VERSION, Perl $], $^X" );
