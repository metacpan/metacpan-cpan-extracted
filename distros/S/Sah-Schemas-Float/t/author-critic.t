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

my $filenames = ['lib/Data/Sah/Coerce/perl/To_float/From_str/as_percent.pm','lib/Data/Sah/Coerce/perl/To_float/From_str/share.pm','lib/Sah/Schema/inf.pm','lib/Sah/Schema/int_or_inf.pm','lib/Sah/Schema/nan.pm','lib/Sah/Schema/negfloat.pm','lib/Sah/Schema/neginf.pm','lib/Sah/Schema/percent.pm','lib/Sah/Schema/posfloat.pm','lib/Sah/Schema/posinf.pm','lib/Sah/Schema/posint_or_posinf.pm','lib/Sah/Schema/share.pm','lib/Sah/Schema/ufloat.pm','lib/Sah/Schema/uint_or_posinf.pm','lib/Sah/SchemaR/inf.pm','lib/Sah/SchemaR/int_or_inf.pm','lib/Sah/SchemaR/nan.pm','lib/Sah/SchemaR/negfloat.pm','lib/Sah/SchemaR/neginf.pm','lib/Sah/SchemaR/percent.pm','lib/Sah/SchemaR/posfloat.pm','lib/Sah/SchemaR/posinf.pm','lib/Sah/SchemaR/posint_or_posinf.pm','lib/Sah/SchemaR/share.pm','lib/Sah/SchemaR/ufloat.pm','lib/Sah/SchemaR/uint_or_posinf.pm','lib/Sah/Schemas/Float.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
