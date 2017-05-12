#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'PowerDNS::Backend::MySQL' );
}

diag( "Testing PowerDNS::Backend::MySQL $PowerDNS::Backend::MySQL::VERSION, Perl $], $^X" );
