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

my $filenames = ['lib/Sah/Schema/byte.pm','lib/Sah/Schema/even.pm','lib/Sah/Schema/int128.pm','lib/Sah/Schema/int16.pm','lib/Sah/Schema/int32.pm','lib/Sah/Schema/int64.pm','lib/Sah/Schema/int8.pm','lib/Sah/Schema/natnum.pm','lib/Sah/Schema/negeven.pm','lib/Sah/Schema/negint.pm','lib/Sah/Schema/negodd.pm','lib/Sah/Schema/nonnegint.pm','lib/Sah/Schema/nonposint.pm','lib/Sah/Schema/odd.pm','lib/Sah/Schema/poseven.pm','lib/Sah/Schema/posint.pm','lib/Sah/Schema/posodd.pm','lib/Sah/Schema/uint.pm','lib/Sah/Schema/uint128.pm','lib/Sah/Schema/uint16.pm','lib/Sah/Schema/uint32.pm','lib/Sah/Schema/uint64.pm','lib/Sah/Schema/uint8.pm','lib/Sah/SchemaR/byte.pm','lib/Sah/SchemaR/even.pm','lib/Sah/SchemaR/int128.pm','lib/Sah/SchemaR/int16.pm','lib/Sah/SchemaR/int32.pm','lib/Sah/SchemaR/int64.pm','lib/Sah/SchemaR/int8.pm','lib/Sah/SchemaR/natnum.pm','lib/Sah/SchemaR/negeven.pm','lib/Sah/SchemaR/negint.pm','lib/Sah/SchemaR/negodd.pm','lib/Sah/SchemaR/nonnegint.pm','lib/Sah/SchemaR/nonposint.pm','lib/Sah/SchemaR/odd.pm','lib/Sah/SchemaR/poseven.pm','lib/Sah/SchemaR/posint.pm','lib/Sah/SchemaR/posodd.pm','lib/Sah/SchemaR/uint.pm','lib/Sah/SchemaR/uint128.pm','lib/Sah/SchemaR/uint16.pm','lib/Sah/SchemaR/uint32.pm','lib/Sah/SchemaR/uint64.pm','lib/Sah/SchemaR/uint8.pm','lib/Sah/Schemas/Int.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
