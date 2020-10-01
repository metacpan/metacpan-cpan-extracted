#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'SPVM::AI::Util' ) || print "Bail out!\n";
}

diag( "Testing SPVM::AI::Util $SPVM::AI::Util::VERSION, Perl $], $^X" );
