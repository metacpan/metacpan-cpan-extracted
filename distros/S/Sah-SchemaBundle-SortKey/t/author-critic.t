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

my $filenames = ['lib/Perinci/Sub/XCompletion/perl_sortkey_modname_with_optional_args.pm','lib/Sah/Schema/perl/sortkey/modname.pm','lib/Sah/Schema/perl/sortkey/modname_with_optional_args.pm','lib/Sah/Schema/perl/sortkey/modnames.pm','lib/Sah/Schema/perl/sortkey/modnames_with_optional_args.pm','lib/Sah/SchemaBundle/SortKey.pm','lib/Sah/SchemaR/perl/sortkey/modname.pm','lib/Sah/SchemaR/perl/sortkey/modname_with_optional_args.pm','lib/Sah/SchemaR/perl/sortkey/modnames.pm','lib/Sah/SchemaR/perl/sortkey/modnames_with_optional_args.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
