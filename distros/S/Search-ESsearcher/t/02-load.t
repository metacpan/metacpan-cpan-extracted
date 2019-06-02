#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Search::ESsearcher::Templates::bf2b' ) || print "Bail out!\n";
}

diag( "Testing Search::ESsearcher::Templates::bf2b $Search::ESsearcher::Templates::bf2b::VERSION, Perl $], $^X" );
