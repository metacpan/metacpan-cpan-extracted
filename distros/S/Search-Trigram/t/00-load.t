#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Search::Trigram' ) || print "Bail out!\n";
}

diag( "Testing Search::Trigram $Search::Trigram::VERSION, Perl $], $^X" );
