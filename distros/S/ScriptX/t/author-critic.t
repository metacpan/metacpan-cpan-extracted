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

my $filenames = ['lib/ScriptX.pm','lib/ScriptX/Debug/DumpStash.pm','lib/ScriptX/DisablePlugin.pm','lib/ScriptX/Exit.pm','lib/ScriptX/Getopt/Long.pm','lib/ScriptX/Getopt/Specless.pm','lib/ScriptX/ModifyPlugin.pm','lib/ScriptX/Noop.pm','lib/ScriptX/Run.pm','lib/ScriptX_Base.pm','lib/ScriptX_Manual.pod','lib/ScriptX_Manual/Cookbook.pod','lib/ScriptX_Manual/FAQ.pod','script/scriptx-eg-getopt-long','script/scriptx-eg-getopt-specless','script/scriptx-eg-noop','script/scriptx-eg-run-code','script/scriptx-eg-run-command','script/scriptx-eg-run-sub'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
