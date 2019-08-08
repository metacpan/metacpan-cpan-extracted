#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Match::UID' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Match::UID $Net::Connection::Match::UID::VERSION, Perl $], $^X" );
