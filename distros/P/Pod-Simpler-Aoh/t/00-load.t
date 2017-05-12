#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Pod::Simpler::Aoh' ) || print "Bail out!\n";
}

diag( "Testing Pod::Simpler::Aoh $Pod::Simpler::Aoh::VERSION, Perl $], $^X" );
