#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Search::Fzf' ) || print "Bail out!\n";
    use_ok( 'Search::Fzf::Tui' ) || print "Bail out!\n";
    use_ok( 'Search::Fzf::AlgoCpp' ) || print "Bail out!\n";
}

diag( "Testing Search::Fzf $Search::Fzf::VERSION, Perl $], $^X" );
