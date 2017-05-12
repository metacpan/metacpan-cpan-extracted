#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::DNS::RR::SRV::Helper' );
}

diag( "Testing Net::DNS::RR::SRV::Helper $Net::DNS::RR::SRV::Helper::VERSION, Perl $], $^X" );
