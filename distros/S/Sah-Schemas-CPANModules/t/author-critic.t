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

my $filenames = ['lib/Sah/Schema/cpanmodules/entry.pm','lib/Sah/Schema/cpanmodules/list.pm','lib/Sah/SchemaR/cpanmodules/entry.pm','lib/Sah/SchemaR/cpanmodules/list.pm','lib/Sah/Schemas/CPANModules.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
