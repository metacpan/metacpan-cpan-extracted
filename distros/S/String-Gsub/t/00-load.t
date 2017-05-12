#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'String::Gsub' );
}

diag( "Testing String::Gsub $String::Gsub::VERSION, Perl $], $^X" );
