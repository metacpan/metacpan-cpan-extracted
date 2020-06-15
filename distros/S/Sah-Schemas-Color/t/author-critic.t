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

my $filenames = ['lib/Data/Sah/Coerce/perl/To_str/From_str/rgb24_from_colorname_X_or_code.pm','lib/Sah/Schema/color/ansi16.pm','lib/Sah/Schema/color/ansi256.pm','lib/Sah/Schema/color/rgb24.pm','lib/Sah/SchemaR/color/ansi16.pm','lib/Sah/SchemaR/color/ansi256.pm','lib/Sah/SchemaR/color/rgb24.pm','lib/Sah/Schemas/Color.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
