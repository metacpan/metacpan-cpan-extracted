#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Firewall::BlockerHelper' ) || print "Bail out!\n";
}

diag( "Testing Net::Firewall::BlockerHelper $Net::Firewall::BlockerHelper::VERSION, Perl $], $^X" );
