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

my $filenames = ['lib/Sah/Schema/perl/borderstyle/modname.pm','lib/Sah/Schema/perl/borderstyle/modname_with_optional_args.pm','lib/Sah/SchemaBundle/BorderStyle.pm','lib/Sah/SchemaR/perl/borderstyle/modname.pm','lib/Sah/SchemaR/perl/borderstyle/modname_with_optional_args.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
