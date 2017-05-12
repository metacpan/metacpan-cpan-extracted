#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Saasu' ) || print "Bail out!\n";
}

diag( "Testing Net::Saasu $Net::Saasu::VERSION, Perl $], $^X" );
