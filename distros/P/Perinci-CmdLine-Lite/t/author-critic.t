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

my $filenames = ['lib/Perinci/CmdLine/Base.pm','lib/Perinci/CmdLine/Lite.pm','lib/Perinci/CmdLine/Plugin/Debug/DumpArgs.pm','lib/Perinci/CmdLine/Plugin/Debug/DumpR.pm','lib/Perinci/CmdLine/Plugin/Debug/DumpRes.pm','lib/Perinci/CmdLine/Plugin/Flow/Exit.pm','lib/Perinci/CmdLine/Plugin/Plugin/Disable.pm','lib/Perinci/CmdLine/Plugin/Run/Completion.pm','lib/Perinci/CmdLine/Plugin/Run/DebugCompletion.pm','lib/Perinci/CmdLine/Plugin/Run/DumpObject.pm','lib/Perinci/CmdLine/Plugin/Run/Normal.pm','lib/Perinci/CmdLine/PluginBase.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
