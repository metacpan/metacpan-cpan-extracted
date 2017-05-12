#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sphinx::Manager' );
}

diag( "Testing Sphinx::Manager $Sphinx::Manager::VERSION, Perl $], $^X" );
