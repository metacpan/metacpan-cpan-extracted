#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::XMPP::Client::GTalk' ) || print "Bail out!\n";
}

diag( "Testing Net::XMPP::Client::GTalk $Net::XMPP::Client::GTalk::VERSION, Perl $], $^X" );
