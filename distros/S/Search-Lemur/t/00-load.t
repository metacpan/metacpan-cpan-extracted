#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Search::Lemur' );
}

diag( "Testing Search::Lemur $Search::Lemur::VERSION, Perl $], $^X" );
