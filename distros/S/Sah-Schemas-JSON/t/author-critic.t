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

my $filenames = ['lib/Data/Sah/Filter/perl/JSON/check_decode.pm','lib/Data/Sah/Filter/perl/JSON/decode.pm','lib/Data/Sah/Filter/perl/JSON/decode_str.pm','lib/Sah/Schema/any_from_json.pm','lib/Sah/Schema/array_from_json.pm','lib/Sah/Schema/hash_from_json.pm','lib/Sah/Schema/json_str.pm','lib/Sah/SchemaR/any_from_json.pm','lib/Sah/SchemaR/array_from_json.pm','lib/Sah/SchemaR/hash_from_json.pm','lib/Sah/SchemaR/json_str.pm','lib/Sah/Schemas/JSON.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
