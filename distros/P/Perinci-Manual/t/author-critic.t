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

my $filenames = ['lib/Perinci/Manual.pm','lib/Perinci/Manual/HowTo/FunctionMetadata.pod','lib/Perinci/Manual/HowTo/FunctionMetadata/Examples.pod','lib/Perinci/Manual/Reference/FunctionMetadata/Arguments/PropertyAttributeIndex.pod','lib/Perinci/Manual/Reference/FunctionMetadata/Examples/PropertyAttributeIndex.pod','lib/Perinci/Manual/Reference/FunctionMetadata/PropertyAttributeIndex.pod'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
