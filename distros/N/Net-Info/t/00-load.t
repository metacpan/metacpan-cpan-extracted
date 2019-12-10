#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Info' ) || print "Bail out!\n";
}

diag( "Testing Net::Info $Net::Info::VERSION, Perl $], $^X" );
