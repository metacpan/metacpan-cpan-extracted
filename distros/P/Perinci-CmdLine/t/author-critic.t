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

my $filenames = ['lib/Perinci/CmdLine.pm','lib/Perinci/CmdLine/Manual.pod','lib/Perinci/CmdLine/Manual/Explanation/ArgumentValidation.pod','lib/Perinci/CmdLine/Manual/FAQ.pod','lib/Perinci/CmdLine/Manual/HowTo/99Examples.pod','lib/Perinci/CmdLine/Manual/HowTo/Debugging.pod'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
