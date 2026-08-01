#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Linux_ss' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Linux_ss $Net::Connection::Linux_ss::VERSION, Perl $], $^X" );
