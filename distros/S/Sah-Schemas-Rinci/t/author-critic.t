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

my $filenames = ['lib/Sah/Schema/rinci/function_meta.pm','lib/Sah/Schema/rinci/meta.pm','lib/Sah/Schema/rinci/result_meta.pm','lib/Sah/SchemaR/rinci/function_meta.pm','lib/Sah/SchemaR/rinci/meta.pm','lib/Sah/SchemaR/rinci/result_meta.pm','lib/Sah/Schemas/Rinci.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
