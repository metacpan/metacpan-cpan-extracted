#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::DHCP::Config::Utilities::INI_loader' ) || print "Bail out!\n";
}

diag( "Testing Net::DHCP::Config::Utilities::INI_loader $Net::DHCP::Config::Utilities::INI_loader::VERSION, Perl $], $^X" );
