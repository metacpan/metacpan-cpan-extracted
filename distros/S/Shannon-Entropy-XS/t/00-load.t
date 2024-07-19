#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Shannon::Entropy::XS' ) || print "Bail out!\n";
}

diag( "Testing Shannon::Entropy::XS $Shannon::Entropy::XS::VERSION, Perl $], $^X" );
