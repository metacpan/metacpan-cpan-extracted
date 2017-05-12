#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sphinx::Config' );
}

diag( "Testing Sphinx::Config $Sphinx::Config::VERSION, Perl $], $^X" );
