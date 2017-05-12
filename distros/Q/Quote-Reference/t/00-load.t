#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Quote::Reference' );
}

diag( "Testing Quote::Reference $Quote::Reference::VERSION, Perl $], $^X" );

