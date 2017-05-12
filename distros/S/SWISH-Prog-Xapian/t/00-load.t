#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'SWISH::Prog::Xapian' );
}

diag( "Testing SWISH::Prog::Xapian $SWISH::Prog::Xapian::VERSION, Perl $], $^X" );
