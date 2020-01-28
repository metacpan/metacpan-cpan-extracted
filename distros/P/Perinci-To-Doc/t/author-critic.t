#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.003

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Perinci/Sub/To/FuncBase.pm','lib/Perinci/Sub/To/POD.pm','lib/Perinci/Sub/To/Text.pm','lib/Perinci/To/Doc.pm','lib/Perinci/To/Doc/Role/Section.pm','lib/Perinci/To/Doc/Role/Section/AddTextLines.pm','lib/Perinci/To/POD.pm','lib/Perinci/To/PackageBase.pm','lib/Perinci/To/Text.pm','script/peri-doc'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
