#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sphinx::Control' );
}

diag( "Testing Sphinx::Control $Sphinx::Control::VERSION, Perl $], $^X" );
