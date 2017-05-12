#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Wireless::802_11::WPA::CLI::Helper' ) || print "Bail out!
";
}

diag( "Testing Net::Wireless::802_11::WPA::CLI::Helper $Net::Wireless::802_11::WPA::CLI::Helper::VERSION, Perl $], $^X" );
