#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Firewall::BlockerHelper::backends::pf' ) || print "Bail out!\n";
}

diag( "Testing Net::Firewall::BlockerHelper::backends::pf $Net::Firewall::BlockerHelper::backends::pf::VERSION, Perl $], $^X" );
