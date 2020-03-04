#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.003

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Sah/Schema/aoaoms.pm','lib/Sah/Schema/aoaos.pm','lib/Sah/Schema/aohoms.pm','lib/Sah/Schema/aohos.pm','lib/Sah/Schema/aoms.pm','lib/Sah/Schema/aos.pm','lib/Sah/Schema/hoaoms.pm','lib/Sah/Schema/hoaos.pm','lib/Sah/Schema/hohoms.pm','lib/Sah/Schema/hohos.pm','lib/Sah/Schema/homs.pm','lib/Sah/Schema/hos.pm','lib/Sah/SchemaR/aoaoms.pm','lib/Sah/SchemaR/aoaos.pm','lib/Sah/SchemaR/aohoms.pm','lib/Sah/SchemaR/aohos.pm','lib/Sah/SchemaR/aoms.pm','lib/Sah/SchemaR/aos.pm','lib/Sah/SchemaR/hoaoms.pm','lib/Sah/SchemaR/hoaos.pm','lib/Sah/SchemaR/hohoms.pm','lib/Sah/SchemaR/hohos.pm','lib/Sah/SchemaR/homs.pm','lib/Sah/SchemaR/hos.pm','lib/Sah/Schemas/Collection.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
