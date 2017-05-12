#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'String::Splitter' );
}

diag( "Testing String::Splitter $String::Splitter::VERSION, Perl $], $^X" );
