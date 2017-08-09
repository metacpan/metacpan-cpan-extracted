#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Shannon::Entropy' ) || print "Bail out!\n";
}

diag( "Testing Shannon::Entropy $Shannon::Entropy::VERSION, Perl $], $^X" );
