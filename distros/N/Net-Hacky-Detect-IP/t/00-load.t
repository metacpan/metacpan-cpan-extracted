#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Hacky::Detect::IP' ) || print "Bail out!\n";
}

diag( "Testing Net::Hacky::Detect::IP $Net::Hacky::Detect::IP::VERSION, Perl $], $^X" );
