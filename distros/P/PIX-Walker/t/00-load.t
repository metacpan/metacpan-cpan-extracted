#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'PIX::Walker' );
}

diag( "Testing PIX::Walker $PIX::Walker::VERSION, Perl $], $^X" );
