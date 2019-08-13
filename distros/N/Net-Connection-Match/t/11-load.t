#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Match::WChan' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Match::WChan $Net::Connection::Match::WChan::VERSION, Perl $], $^X" );
