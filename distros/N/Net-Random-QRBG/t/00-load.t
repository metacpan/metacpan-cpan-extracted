#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Random::QRBG' );
}

diag( "Testing Net::Random::QRBG $Net::Random::QRBG::VERSION, Perl $], $^X" );
