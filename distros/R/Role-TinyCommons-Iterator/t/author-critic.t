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

my $filenames = ['lib/Role/TinyCommons/Iterator.pm','lib/Role/TinyCommons/Iterator/Basic.pm','lib/Role/TinyCommons/Iterator/Bidirectional.pm','lib/Role/TinyCommons/Iterator/Circular.pm','lib/Role/TinyCommons/Iterator/Resettable.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
