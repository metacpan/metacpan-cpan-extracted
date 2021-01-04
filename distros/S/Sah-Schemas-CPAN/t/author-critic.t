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

my $filenames = ['lib/Sah/Schema/cpan/distname.pm','lib/Sah/Schema/cpan/modname.pm','lib/Sah/Schema/cpan/pause_id.pm','lib/Sah/SchemaR/cpan/distname.pm','lib/Sah/SchemaR/cpan/modname.pm','lib/Sah/SchemaR/cpan/pause_id.pm','lib/Sah/Schemas/CPAN.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
