#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Parser::AAMVA::License' ) || print "Bail out!\n";
}

diag( "Testing Parser::AAMVA::License $Parser::AAMVA::License::VERSION, Perl $], $^X" );
