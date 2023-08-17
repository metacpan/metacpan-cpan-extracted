#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Sort::unsorted' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort::unsorted $Net::Connection::Sort::unsorted::VERSION, Perl $], $^X" );
