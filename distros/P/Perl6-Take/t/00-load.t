#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Perl6::Take' );
}

diag( "Testing Perl6::Take $Perl6::Take::VERSION, Perl $], $^X" );
