#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::HTTPS::Any' );
}

diag( "Testing Net::HTTPS::Any $Net::HTTPS::Any::VERSION, Perl $], $^X" );
