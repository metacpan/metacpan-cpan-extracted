#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Output::Rewrite' );
}

diag( "Testing Output::Rewrite $Output::Rewrite::VERSION, Perl $], $^X" );
