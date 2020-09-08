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

my $filenames = ['lib/Perinci/Examples/Bin/Any.pm','lib/Perinci/Examples/Bin/Any/Multi.pm','script/peri-eg-cmdline-src-file-any','script/peri-eg-cmdline-src-stdin-or-args-any','script/peri-eg-cmdline-src-stdin-or-file-any','script/peri-eg-cmdline-src-stdin-or-files-any','script/peri-eg-complete-fruits-any','script/peri-eg-demo-cli-opts-any','script/peri-eg-gen-random-bytes-any','script/peri-eg-multi-any','script/peri-eg-multi-embedded-any','script/peri-eg-single-embedded-any','script/peri-eg-test-completion-any','script/peri-eg-test-dry-run-any'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
