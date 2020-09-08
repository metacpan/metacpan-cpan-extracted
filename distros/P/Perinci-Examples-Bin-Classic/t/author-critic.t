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

my $filenames = ['lib/Perinci/Examples/Bin/Classic.pm','script/peri-eg-append-file','script/peri-eg-complete-fruits','script/peri-eg-demo-cli-opts','script/peri-eg-gen-random-bytes','script/peri-eg-read-file','script/peri-eg-test-binary-files','script/peri-eg-test-common-opts','script/peri-eg-test-completion','script/peri-eg-write-file'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
