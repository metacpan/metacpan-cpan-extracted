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

my $filenames = ['lib/Perinci/Object.pm','lib/Perinci/Object/EnvResult.pm','lib/Perinci/Object/EnvResultMulti.pm','lib/Perinci/Object/EnvResultTable.pm','lib/Perinci/Object/Function.pm','lib/Perinci/Object/Metadata.pm','lib/Perinci/Object/Package.pm','lib/Perinci/Object/ResMeta.pm','lib/Perinci/Object/Variable.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
