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

my $filenames = ['lib/Perinci/Examples.pm','lib/Perinci/Examples/ArgsAs.pm','lib/Perinci/Examples/CLI.pm','lib/Perinci/Examples/CSV.pm','lib/Perinci/Examples/CmdLineResMeta.pm','lib/Perinci/Examples/CmdLineSrc.pm','lib/Perinci/Examples/Coercion.pm','lib/Perinci/Examples/Completion.pm','lib/Perinci/Examples/FilePartial.pm','lib/Perinci/Examples/FileStream.pm','lib/Perinci/Examples/NoMeta.pm','lib/Perinci/Examples/ResultNaked.pm','lib/Perinci/Examples/RiapSub.pm','lib/Perinci/Examples/Stream.pm','lib/Perinci/Examples/SubMeta.pm','lib/Perinci/Examples/Table.pm','lib/Perinci/Examples/Tiny.pm','lib/Perinci/Examples/Tiny/Args.pm','lib/Perinci/Examples/Tiny/Result.pm','lib/Perinci/Examples/Tx.pm','lib/Perinci/Examples/Version.pm','lib/Perinci/Examples/rimetadb/ExcludedPackage.pm','lib/Perinci/Examples/rimetadb/IncludedPackage.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
