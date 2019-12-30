#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Compare' ) || print "Bail out!\n";
}

diag( "Testing Net::Compare $Net::Compare::VERSION, Perl $], $^X" );
