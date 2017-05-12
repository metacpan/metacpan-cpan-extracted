#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Semantics3' ) || print "Bail out!\n";
}

diag( "Testing Net::Semantics3 $Net::Semantics3::VERSION, Perl $], $^X" );
