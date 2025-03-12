#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;

my $has_test_deep = 1;
BEGIN {
  if ($] < 5.012) {
    $has_test_deep = 0;
  }
  else {
    eval { require Test::Deep; Test::Deep->import(); 1 } or $has_test_deep = 0;
  }
  # mock cmp_deeply
  if (not $has_test_deep) {
    no warnings qw/redefine/;
    eval { *cmp_deeply = sub { 1 } };
  }
}

# build and load subroutines
use OpenMP::Simple;
use OpenMP::Environment;

use Inline (
    C                 => 'DATA',
    with              => qw/OpenMP::Simple/,
);

my $env = OpenMP::Environment->new();

my $aref_orig = [
  [ "apple", "banana", "cherry", "date", "elder", "fig", "grape", "honey", "iris", "jack" ],
  [ "kite", "lemon", "mango", "nectar", "olive", "pear", "quince", "rose", "straw", "tulip" ],
  [ "umbrella", "violet", "water", "xenon", "yellow", "zebra", "apple", "banana", "cherry", "date" ],
  [ "elder", "fig", "grape", "honey", "iris", "jack", "kite", "lemon", "mango", "nectar" ],
  [ "olive", "pear", "quince", "rose", "straw", "tulip", "umbrella", "violet", "water", "xenon" ],
  [ "yellow", "zebra", "apple", "banana", "cherry", "date", "elder", "fig", "grape", "honey" ],
  [ "iris", "jack", "kite", "lemon", "mango", "nectar", "olive", "pear", "quince", "rose" ],
  [ "straw", "tulip", "umbrella", "violet", "water", "xenon", "yellow", "zebra", "apple", "banana" ],
  [ "cherry", "date", "elder", "fig", "grape", "honey", "iris", "jack", "kite", "lemon" ],
  [ "mango", "nectar", "olive", "pear", "quince", "rose", "straw", "tulip", "umbrella", "violet" ],
  [ "water", "xenon", "yellow", "zebra", "apple", "banana", "cherry", "date", "elder", "fig" ],
  [ "grape", "honey", "iris", "jack", "kite", "lemon", "mango", "nectar", "olive", "pear" ],
  [ "quince", "rose", "straw", "tulip", "umbrella", "violet", "water", "xenon", "yellow", "zebra" ],
  [ "apple", "banana", "cherry", "date", "elder", "fig", "grape", "honey", "iris", "jack" ],
  [ "kite", "lemon", "mango", "nectar", "olive", "pear", "quince", "rose", "straw", "tulip" ],
  [ "umbrella", "violet", "water", "xenon", "yellow", "zebra", "apple", "banana", "cherry", "date" ],
  [ "elder", "fig", "grape", "honey", "iris", "jack", "kite", "lemon", "mango", "nectar" ],
  [ "olive", "pear", "quince", "rose", "straw", "tulip", "umbrella", "violet", "water", "xenon" ],
  [ "yellow", "zebra", "apple", "banana", "cherry", "date", "elder", "fig", "grape", "honey" ],
  [ "iris", "jack", "kite", "lemon", "mango", "nectar", "olive", "pear", "quince", "rose" ],
  [ "straw", "tulip", "umbrella", "violet", "water", "xenon", "yellow", "zebra", "apple", "banana" ],
  [ "cherry", "date", "elder", "fig", "grape", "honey", "iris", "jack", "kite", "lemon" ],
  [ "mango", "nectar", "olive", "pear", "quince", "rose", "straw", "tulip", "umbrella", "violet" ],
  [ "water", "xenon", "yellow", "zebra", "apple", "banana", "cherry", "date", "elder", "fig" ],
  [ "grape", "honey", "iris", "jack", "kite", "lemon", "mango", "nectar", "olive", "pear" ],
  [ "quince", "rose", "straw", "tulip", "umbrella", "violet", "water", "xenon", "yellow", "zebra" ],
];

my $expected = [qw/1 2 3 4 5 6 7 8 9 10/];

foreach my $thread_count (qw/1 4 8/) {
  $env->omp_num_threads($thread_count);

  foreach my $row_orig (@$aref_orig)  {
    my $aref_new      = omp_get_renew_aref($row_orig);
    my $seen_elements = shift @$aref_new;
    my $seen_threads  = shift @$aref_new;
    is $seen_elements, scalar @$row_orig, q{PerlOMP_1D_Array_NUM_ELEMENTS works on original ARRAY reference};
    is $seen_threads, $thread_count, qq{OMP_NUM_THREADS=$thread_count is respected inside of the, omp parallel section, as expected};
    if ($has_test_deep) {
      cmp_deeply $aref_new, $row_orig, qq{Row passed by reference matches the row constructed and returned by reference};;
    }
    else {
      SKIP: { skip "Skipping cmp_deeply tests because Perl is below 5.12 or Test::Deep is unavailable", 1; }
    }
  }
}

done_testing;

__DATA__
__C__

/* Custom driver */
AV* omp_get_renew_aref(SV *ARRAY) {
      
  /* Boilerplate - updates number of threads based on $ENV{OMP_NUM_THREADS} */
  PerlOMP_UPDATE_WITH_ENV__NUM_THREADS

  /* Boilerplate - creates an array to return back to Perl, named "ret" */
  PerlOMP_RET_ARRAY_REF_ret

  /* Determine number of elements in the input 1D Perl array */
  int num_elements = PerlOMP_1D_Array_NUM_ELEMENTS(ARRAY);
  av_push(ret, newSViv(num_elements));

  /* Get 1D Perl array into a C array of strings */
  char *raw_array[num_elements];                                           // Create native C string array
  PerlOMP_1D_Array_TO_1D_STRING_ARRAY(ARRAY, num_elements, raw_array);     // Convert Perl array to C array of strings
    
  /* Allocate space for processed strings */
  char *processed[num_elements];

  #pragma omp parallel shared(raw_array, num_elements, processed)
  #pragma omp master
    av_push(ret, newSViv(omp_get_num_threads()));
  #pragma omp for
    for (int i = 0; i < num_elements; i++) {
      // Example processing: Duplicate the string for demonstration
      processed[i] = strdup(raw_array[i]);
    }

  /* Push processed strings back to the return array */
  for (int i = 0; i < num_elements; i++) {
    av_push(ret, newSVpv(processed[i], 0));  // Add processed string back to Perl array
    free(processed[i]);  // Free allocated memory
  }

  // AV* 'ret' comes from "PerlOMP_RET_ARRAY_REF_ret" macro called above
  return ret;
}
