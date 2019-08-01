#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Sort::host_fl' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort::host_fl $Net::Connection::Sort::host_fl::VERSION, Perl $], $^X" );
