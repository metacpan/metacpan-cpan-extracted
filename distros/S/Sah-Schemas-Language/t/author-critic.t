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

my $filenames = ['lib/Sah/Schema/language/code.pm','lib/Sah/Schema/language/code/alpha2.pm','lib/Sah/Schema/language/code/alpha3.pm','lib/Sah/SchemaR/language/code.pm','lib/Sah/SchemaR/language/code/alpha2.pm','lib/Sah/SchemaR/language/code/alpha3.pm','lib/Sah/Schemas/Language.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
