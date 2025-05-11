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

my $filenames = ['lib/Perinci/Sub/XCompletion/perl_cellfunc_modname_with_optional_args.pm','lib/Sah/Schema/perl/cellfunc/modname.pm','lib/Sah/Schema/perl/cellfunc/modname_with_optional_args.pm','lib/Sah/Schema/perl/cellfunc/modnames.pm','lib/Sah/Schema/perl/cellfunc/modnames_with_optional_args.pm','lib/Sah/SchemaBundle/CellFunc.pm','lib/Sah/SchemaR/perl/cellfunc/modname.pm','lib/Sah/SchemaR/perl/cellfunc/modname_with_optional_args.pm','lib/Sah/SchemaR/perl/cellfunc/modnames.pm','lib/Sah/SchemaR/perl/cellfunc/modnames_with_optional_args.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
