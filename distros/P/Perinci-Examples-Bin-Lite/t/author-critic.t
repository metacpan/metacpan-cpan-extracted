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

my $filenames = ['lib/Perinci/Examples/Bin/Lite.pm','script/peri-eg-append-file-lite','script/peri-eg-demo-cli-opts-lite','script/peri-eg-gen-random-bytes-lite','script/peri-eg-hello-lite','script/peri-eg-read-file-lite','script/peri-eg-write-file-lite'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
