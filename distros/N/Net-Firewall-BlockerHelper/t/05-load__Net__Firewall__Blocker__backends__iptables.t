#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Firewall::BlockerHelper::backends::iptables' ) || print "Bail out!\n";
}

diag( "Testing Net::Firewall::BlockerHelper::backends::iptables $Net::Firewall::BlockerHelper::backends::iptables::VERSION, Perl $], $^X" );
