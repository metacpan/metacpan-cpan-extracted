#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::FreeBSD_sockstat' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::FreeBSD_sockstat $Net::Connection::FreeBSD_sockstat::VERSION, Perl $], $^X" );
