#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Wireless::802_11::WPA::CLI' );
}

diag( "Testing Net::Wireless::802_11::WPA::CLI $Net::Wireless::802_11::WPA::CLI::VERSION, Perl $], $^X" );
