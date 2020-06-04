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

my $filenames = ['lib/Data/Sah/Filter/perl/Firefox/check_profile_name_exists.pm','lib/Perinci/Sub/XCompletion/firefox_profile_name.pm','lib/Sah/Schema/firefox/local_profile_name.pm','lib/Sah/Schema/firefox/profile_name.pm','lib/Sah/SchemaR/firefox/local_profile_name.pm','lib/Sah/SchemaR/firefox/profile_name.pm','lib/Sah/Schemas/Firefox.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
