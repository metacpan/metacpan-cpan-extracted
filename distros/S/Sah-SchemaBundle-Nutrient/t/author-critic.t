#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.006

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Data/Sah/Filter/perl/Nutrient/canonicalize_nutrient_symbol.pm','lib/Perinci/Sub/XCompletion/nutrient_symbol.pm','lib/Sah/Schema/nutrient/symbol.pm','lib/Sah/SchemaBundle/Nutrient.pm','lib/Sah/SchemaR/nutrient/symbol.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
