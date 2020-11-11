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

my $filenames = ['lib/Sah/Schema/perl/tables/modname.pm','lib/Sah/Schema/perl/tables/modname_with_optional_args.pm','lib/Sah/Schema/perl/tables/modnames.pm','lib/Sah/Schema/perl/tables/modnames_with_optional_args.pm','lib/Sah/SchemaR/perl/tables/modname.pm','lib/Sah/SchemaR/perl/tables/modname_with_optional_args.pm','lib/Sah/SchemaR/perl/tables/modnames.pm','lib/Sah/SchemaR/perl/tables/modnames_with_optional_args.pm','lib/Sah/Schemas/Tables.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
