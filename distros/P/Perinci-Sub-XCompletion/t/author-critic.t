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

my $filenames = ['lib/Perinci/Sub/XCompletion.pm','lib/Perinci/Sub/XCompletion/comma_sep.pm','lib/Perinci/Sub/XCompletion/dirname.pm','lib/Perinci/Sub/XCompletion/dirname_curdir.pm','lib/Perinci/Sub/XCompletion/filename.pm','lib/Perinci/Sub/XCompletion/filename_curdir.pm','lib/Perinci/Sub/XCompletion/pathname_curdir.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
