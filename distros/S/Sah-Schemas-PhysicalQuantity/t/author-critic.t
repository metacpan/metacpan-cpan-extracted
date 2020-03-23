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

my $filenames = ['lib/Data/Sah/Filter/perl/PhysicalQuantity/check_type.pm','lib/Data/Sah/Filter/perl/PhysicalQuantity/convert_from_str.pm','lib/Data/Sah/Filter/perl/PhysicalQuantity/convert_unit.pm','lib/Sah/Schema/physical/distance.pm','lib/Sah/Schema/physical/mass.pm','lib/Sah/Schema/physical/mass_in_kg.pm','lib/Sah/Schema/physical/quantity.pm','lib/Sah/SchemaR/physical/distance.pm','lib/Sah/SchemaR/physical/mass.pm','lib/Sah/SchemaR/physical/mass_in_kg.pm','lib/Sah/SchemaR/physical/quantity.pm','lib/Sah/Schemas/PhysicalQuantity.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
