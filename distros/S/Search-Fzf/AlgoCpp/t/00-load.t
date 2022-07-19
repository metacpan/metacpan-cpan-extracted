use strict;
use warnings;
use Test::More tests => 1;

BEGIN { 
  use_ok('Search::Fzf::AlgoCpp') || print "Bail out!\n"; 
};

diag( "Testing Search::Fzf::AlgoCpp $Search::Fzf::AlgoCpp::VERSION, Perl $], $^X" );

