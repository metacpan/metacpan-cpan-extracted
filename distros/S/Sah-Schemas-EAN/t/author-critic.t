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

my $filenames = ['lib/Data/Sah/Coerce/perl/To_str/From_str/to_ean13.pm','lib/Data/Sah/Coerce/perl/To_str/From_str/to_ean8.pm','lib/Sah/Schema/ean13.pm','lib/Sah/Schema/ean13_unvalidated.pm','lib/Sah/Schema/ean13_without_check_digit.pm','lib/Sah/Schema/ean8.pm','lib/Sah/Schema/ean8_unvalidated.pm','lib/Sah/Schema/ean8_without_check_digit.pm','lib/Sah/SchemaR/ean13.pm','lib/Sah/SchemaR/ean13_unvalidated.pm','lib/Sah/SchemaR/ean13_without_check_digit.pm','lib/Sah/SchemaR/ean8.pm','lib/Sah/SchemaR/ean8_unvalidated.pm','lib/Sah/SchemaR/ean8_without_check_digit.pm','lib/Sah/Schemas/EAN.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
