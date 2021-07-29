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

my $filenames = ['lib/Data/Sah/Filter/perl/IntRange/check_int_range.pm','lib/Data/Sah/Filter/perl/IntRange/check_simple_int_range.pm','lib/Data/Sah/Filter/perl/IntRange/check_simple_uint_range.pm','lib/Data/Sah/Filter/perl/IntRange/check_uint_range.pm','lib/Sah/Schema/int_range.pm','lib/Sah/Schema/simple_int_range.pm','lib/Sah/Schema/simple_int_seq.pm','lib/Sah/Schema/simple_uint_range.pm','lib/Sah/Schema/simple_uint_seq.pm','lib/Sah/Schema/uint_range.pm','lib/Sah/SchemaR/int_range.pm','lib/Sah/SchemaR/simple_int_range.pm','lib/Sah/SchemaR/simple_int_seq.pm','lib/Sah/SchemaR/simple_uint_range.pm','lib/Sah/SchemaR/simple_uint_seq.pm','lib/Sah/SchemaR/uint_range.pm','lib/Sah/Schemas/IntRange.pm','lib/Sah/Schemas/IntSeq.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
