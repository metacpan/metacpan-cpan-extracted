#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.003

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Data/Sah/Coerce/perl/To_str/From_str/strip_slashes.pm','lib/Sah/Schema/dirname.pm','lib/Sah/Schema/dirname/unix.pm','lib/Sah/Schema/filename.pm','lib/Sah/Schema/filename/unix.pm','lib/Sah/Schema/pathname.pm','lib/Sah/Schema/pathname/unix.pm','lib/Sah/SchemaR/dirname.pm','lib/Sah/SchemaR/dirname/unix.pm','lib/Sah/SchemaR/filename.pm','lib/Sah/SchemaR/filename/unix.pm','lib/Sah/SchemaR/pathname.pm','lib/Sah/SchemaR/pathname/unix.pm','lib/Sah/Schemas/Path.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
