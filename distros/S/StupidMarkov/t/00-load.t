#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'StupidMarkov' );
}

diag( "Testing StupidMarkov $StupidMarkov::VERSION, Perl $], $^X" );
