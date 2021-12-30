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

my $filenames = ['lib/Rinci.pm','lib/Rinci.pod','lib/Rinci/FAQ.pod','lib/Rinci/Transaction.pod','lib/Rinci/Undo.pod','lib/Rinci/Upgrading.pod','lib/Rinci/function.pod','lib/Rinci/package.pod','lib/Rinci/resmeta.pod','lib/Rinci/variable.pod'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
