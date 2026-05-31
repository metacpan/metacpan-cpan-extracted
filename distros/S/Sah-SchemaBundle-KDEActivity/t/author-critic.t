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

my $filenames = ['lib/Perinci/Sub/XCompletion/kdeactivity_guid.pm','lib/Perinci/Sub/XCompletion/kdeactivity_name.pm','lib/Sah/Schema/kdeactivity/guid.pm','lib/Sah/Schema/kdeactivity/name.pm','lib/Sah/SchemaBundle/KDEActivity.pm','lib/Sah/SchemaR/kdeactivity/guid.pm','lib/Sah/SchemaR/kdeactivity/name.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
