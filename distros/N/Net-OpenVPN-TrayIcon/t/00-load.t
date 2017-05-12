#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::OpenVPN::TrayIcon' ) || print "Bail out!\n";
}

diag( "Testing Net::OpenVPN::TrayIcon $Net::OpenVPN::TrayIcon::VERSION, Perl $], $^X" );
