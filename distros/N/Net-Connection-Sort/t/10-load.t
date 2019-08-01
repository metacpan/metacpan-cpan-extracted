#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Sort::ptr_f' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort::ptr_f $Net::Connection::Sort::ptr_f::VERSION, Perl $], $^X" );
