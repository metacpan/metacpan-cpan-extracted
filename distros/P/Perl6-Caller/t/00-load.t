#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Perl6::Caller' );
}

diag( "Testing Perl6::Caller $Perl6::Caller::VERSION, Perl $], $^X" );
