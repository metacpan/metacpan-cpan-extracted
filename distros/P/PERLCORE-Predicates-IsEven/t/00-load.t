#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'PERLCORE::Predicates::IsEven' ) || print "Bail out!\n";
}

diag( "Testing PERLCORE::Predicates::IsEven $PERLCORE::Predicates::IsEven::VERSION, Perl $], $^X" );
