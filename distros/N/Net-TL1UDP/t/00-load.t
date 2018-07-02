#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::TL1UDP' ) || print "Bail out!\n";
}

diag( "Testing Net::TL1UDP $Net::TL1UDP::VERSION, Perl $], $^X" );
