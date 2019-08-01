#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Sort' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort $Net::Connection::Sort::VERSION, Perl $], $^X" );
