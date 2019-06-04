#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Search::ESsearcher::Templates::httpAccess' ) || print "Bail out!\n";
}

diag( "Testing Search::ESsearcher::Templates::httpAccess $Search::ESsearcher::Templates::httpAccess::VERSION, Perl $], $^X" );
