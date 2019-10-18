#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::DHCP::Windows::Netsh::Parse' ) || print "Bail out!\n";
}

diag( "Testing Net::DHCP::Windows::Netsh::Parse $Net::DHCP::Windows::Netsh::Parse::VERSION, Perl $], $^X" );
