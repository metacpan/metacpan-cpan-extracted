#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Sort::host_l' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort::host_l $Net::Connection::Sort::host_l::VERSION, Perl $], $^X" );
