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

my $filenames = ['lib/Data/Sah/Filter/perl/Array/check_elems_int_contiguous.pm','lib/Data/Sah/Filter/perl/Array/check_elems_numeric_monotonically_decreasing.pm','lib/Data/Sah/Filter/perl/Array/check_elems_numeric_monotonically_increasing.pm','lib/Data/Sah/Filter/perl/Array/check_elems_numeric_reverse_sorted.pm','lib/Data/Sah/Filter/perl/Array/check_elems_numeric_sorted.pm','lib/Sah/Schema/array/int/contiguous.pm','lib/Sah/Schema/array/int/monotonically_decreasing.pm','lib/Sah/Schema/array/int/monotonically_increasing.pm','lib/Sah/Schema/array/int/reverse_sorted.pm','lib/Sah/Schema/array/int/sorted.pm','lib/Sah/Schema/array/num/monotonically_decreasing.pm','lib/Sah/Schema/array/num/monotonically_increasing.pm','lib/Sah/Schema/array/num/reverse_sorted.pm','lib/Sah/Schema/array/num/sorted.pm','lib/Sah/SchemaBundle/Array.pm','lib/Sah/SchemaR/array/int/contiguous.pm','lib/Sah/SchemaR/array/int/monotonically_decreasing.pm','lib/Sah/SchemaR/array/int/monotonically_increasing.pm','lib/Sah/SchemaR/array/int/reverse_sorted.pm','lib/Sah/SchemaR/array/int/sorted.pm','lib/Sah/SchemaR/array/num/monotonically_decreasing.pm','lib/Sah/SchemaR/array/num/monotonically_increasing.pm','lib/Sah/SchemaR/array/num/reverse_sorted.pm','lib/Sah/SchemaR/array/num/sorted.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
