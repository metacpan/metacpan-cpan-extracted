#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Joker::DMAPI' ) || print "Bail out!\n";
}

diag( "Testing Net::Joker::DMAPI $Net::Joker::DMAPI::VERSION, Perl $], $^X" );
