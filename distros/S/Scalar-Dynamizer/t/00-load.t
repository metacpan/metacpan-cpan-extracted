#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Scalar::Dynamizer' ) || print "Bail out!\n";
    use_ok( 'Scalar::Dynamizer::Tie' ) || print "Bail out!\n";
}

diag( "Testing Scalar::Dynamizer $Scalar::Dynamizer::VERSION, Perl $], $^X" );
