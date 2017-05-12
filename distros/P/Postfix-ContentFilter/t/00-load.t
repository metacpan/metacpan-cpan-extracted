#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Postfix::ContentFilter' );
}

diag( "Testing Postfix::ContentFilter $Postfix::ContentFilter::VERSION, Perl $], $^X" );
