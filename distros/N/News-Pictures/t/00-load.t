#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Tk' );
	
}

diag( "Testing News::Pictures $News::Pictures::VERSION, Perl $], $^X" );