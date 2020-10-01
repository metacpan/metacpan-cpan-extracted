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

my $filenames = ['lib/Data/Sah/Coerce/perl/To_str/From_str/to_isbn.pm','lib/Data/Sah/Coerce/perl/To_str/From_str/to_isbn10.pm','lib/Data/Sah/Coerce/perl/To_str/From_str/to_isbn13.pm','lib/Sah/Schema/isbn.pm','lib/Sah/Schema/isbn10.pm','lib/Sah/Schema/isbn13.pm','lib/Sah/SchemaR/isbn.pm','lib/Sah/SchemaR/isbn10.pm','lib/Sah/SchemaR/isbn13.pm','lib/Sah/Schemas/ISBN.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
