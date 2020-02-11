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

my $filenames = ['lib/Data/Sah/Filter/perl/Path/expand_tilde.pm','lib/Data/Sah/Filter/perl/Path/expand_tilde_when_on_unix.pm','lib/Data/Sah/Filter/perl/Path/strip_slashes.pm','lib/Data/Sah/Filter/perl/Path/strip_slashes_when_on_unix.pm','lib/Sah/Schema/dirname.pm','lib/Sah/Schema/dirname/unix.pm','lib/Sah/Schema/filename.pm','lib/Sah/Schema/filename/unix.pm','lib/Sah/Schema/pathname.pm','lib/Sah/Schema/pathname/unix.pm','lib/Sah/SchemaR/dirname.pm','lib/Sah/SchemaR/dirname/unix.pm','lib/Sah/SchemaR/filename.pm','lib/Sah/SchemaR/filename/unix.pm','lib/Sah/SchemaR/pathname.pm','lib/Sah/SchemaR/pathname/unix.pm','lib/Sah/Schemas/Path.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
