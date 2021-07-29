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

my $filenames = ['lib/Sah/Schema/sah/array_schema.pm','lib/Sah/Schema/sah/clause_set.pm','lib/Sah/Schema/sah/defhash_example.pm','lib/Sah/Schema/sah/nondefhash_example.pm','lib/Sah/Schema/sah/nschema.pm','lib/Sah/Schema/sah/schema.pm','lib/Sah/Schema/sah/schema_modname.pm','lib/Sah/Schema/sah/str_schema.pm','lib/Sah/Schema/sah/type_name.pm','lib/Sah/SchemaR/sah/array_schema.pm','lib/Sah/SchemaR/sah/clause_set.pm','lib/Sah/SchemaR/sah/defhash_example.pm','lib/Sah/SchemaR/sah/nondefhash_example.pm','lib/Sah/SchemaR/sah/nschema.pm','lib/Sah/SchemaR/sah/schema.pm','lib/Sah/SchemaR/sah/schema_modname.pm','lib/Sah/SchemaR/sah/str_schema.pm','lib/Sah/SchemaR/sah/type_name.pm','lib/Sah/Schemas/Sah.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
