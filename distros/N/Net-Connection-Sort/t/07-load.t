#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Sort::uid' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort::uid $Net::Connection::Sort::uid::VERSION, Perl $], $^X" );
