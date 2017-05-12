#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::PMP::Client' ) || print "Bail out!\n";
}

diag( "Testing Net::PMP::Client $Net::PMP::Client::VERSION, Perl $], $^X" );
