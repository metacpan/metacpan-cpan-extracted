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

my $filenames = ['lib/RHC.pm','lib/Require/HookChain.pm','lib/Require/HookChain/log/logger.pm','lib/Require/HookChain/log/stderr.pm','lib/Require/HookChain/munge/prepend.pm','lib/Require/HookChain/test/fail.pm','lib/Require/HookChain/test/noop.pm','lib/Require/HookChain/test/noop_all.pm','lib/Require/HookChain/test/random_fail.pm','lib/Require/HookChain/timestamp/hires.pm','lib/Require/HookChain/timestamp/std.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
