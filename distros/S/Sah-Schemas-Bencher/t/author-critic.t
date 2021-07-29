#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.005

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Sah/Schema/bencher/dataset.pm','lib/Sah/Schema/bencher/env_hash.pm','lib/Sah/Schema/bencher/participant.pm','lib/Sah/Schema/bencher/scenario.pm','lib/Sah/SchemaR/bencher/dataset.pm','lib/Sah/SchemaR/bencher/env_hash.pm','lib/Sah/SchemaR/bencher/participant.pm','lib/Sah/SchemaR/bencher/scenario.pm','lib/Sah/Schemas/Bencher.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
