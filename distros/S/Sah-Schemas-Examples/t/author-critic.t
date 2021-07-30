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

my $filenames = ['lib/Sah/Schema/array_of_int.pm','lib/Sah/Schema/array_of_posint.pm','lib/Sah/Schema/example/foo.pm','lib/Sah/Schema/example/has_merge.pm','lib/Sah/Schema/example/recurse1.pm','lib/Sah/Schema/example/recurse2a.pm','lib/Sah/Schema/example/recurse2b.pm','lib/Sah/Schema/hash_of_int.pm','lib/Sah/Schema/hash_of_posint.pm','lib/Sah/Schema/ints.pm','lib/Sah/Schema/posints.pm','lib/Sah/SchemaR/array_of_int.pm','lib/Sah/SchemaR/array_of_posint.pm','lib/Sah/SchemaR/example/foo.pm','lib/Sah/SchemaR/example/has_merge.pm','lib/Sah/SchemaR/hash_of_int.pm','lib/Sah/SchemaR/hash_of_posint.pm','lib/Sah/SchemaR/ints.pm','lib/Sah/SchemaR/posints.pm','lib/Sah/Schemas/Examples.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
