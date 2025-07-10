#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Firewall::BlockerHelper::backends::ipfw' ) || print "Bail out!\n";
}

diag( "Testing Net::Firewall::BlockerHelper::backends::ipfw $Net::Firewall::BlockerHelper::backends::ipfw::VERSION, Perl $], $^X" );
