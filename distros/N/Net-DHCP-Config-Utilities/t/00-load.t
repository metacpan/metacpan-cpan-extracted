#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::DHCP::Config::Utilities' ) || print "Bail out!\n";
}

diag( "Testing Net::DHCP::Config::Utilities $Net::DHCP::Config::Utilities::VERSION, Perl $], $^X" );
