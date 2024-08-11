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

my $filenames = ['lib/Perinci/Sub/XCompletion/perl_perl_sah_filter_modname_with_optional_args.pm','lib/Sah/Schema/perl/perl_sah_filter/modname.pm','lib/Sah/Schema/perl/perl_sah_filter/modname_with_optional_args.pm','lib/Sah/SchemaBundle/Data/Sah.pm','lib/Sah/SchemaR/perl/perl_sah_filter/modname.pm','lib/Sah/SchemaR/perl/perl_sah_filter/modname_with_optional_args.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
