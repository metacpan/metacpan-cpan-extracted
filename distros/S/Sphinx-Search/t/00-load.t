#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sphinx::Search' );
}

diag( "Testing Sphinx::Search $Sphinx::Search::VERSION, Perl $], $^X" );
