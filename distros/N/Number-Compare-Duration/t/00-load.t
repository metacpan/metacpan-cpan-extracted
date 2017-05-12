#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Number::Compare::Duration' );
}

diag( "Testing Number::Compare::Duration $Number::Compare::Duration::VERSION, Perl $], $^X" );
