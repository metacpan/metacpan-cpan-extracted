#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Duowan::DNS' ) || print "Bail out!\n";
}

diag( "Testing Net::Duowan::DNS $Net::Duowan::DNS::VERSION, Perl $], $^X" );
