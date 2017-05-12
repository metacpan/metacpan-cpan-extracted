#!perl -T

# set the minimum version number
use Test::More 0.60;
use Test::More tests => 1;

BEGIN {
	use_ok( 'Pod::PseudoPod::LaTeX' );
}

diag( "Testing Pod::PseudoPod::LaTeX $Pod::PseudoPod::LaTeX::VERSION, Perl $], $^X" );
