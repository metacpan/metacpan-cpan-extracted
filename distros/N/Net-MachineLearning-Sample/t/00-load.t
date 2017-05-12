#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::MachineLearning::Sample' ) || print "Bail out!\n";
}

diag( "Testing Net::MachineLearning::Sample $Net::MachineLearning::Sample::VERSION, Perl $], $^X" );
