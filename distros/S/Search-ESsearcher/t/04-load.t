#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Search::ESsearcher::Templates::postfix' ) || print "Bail out!\n";
}

diag( "Testing Search::ESsearcher::Templates::postfix $Search::ESsearcher::Templates::postfix::VERSION, Perl $], $^X" );
