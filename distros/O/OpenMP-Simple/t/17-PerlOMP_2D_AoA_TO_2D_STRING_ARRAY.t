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
    [ "apple",    "banana", "cherry",   "date",   "elder",    "fig",    "grape",    "honey",  "iris",     "jack" ],
    [ "kite",     "lemon",  "mango",    "nectar", "olive",    "pear",   "quince",   "rose",   "straw",    "tulip" ],
    [ "umbrella", "violet", "water",    "xenon",  "yellow",   "zebra",  "apple",    "banana", "cherry",   "date" ],
    [ "elder",    "fig",    "grape",    "honey",  "iris",     "jack",   "kite",     "lemon",  "mango",    "nectar" ],
    [ "olive",    "pear",   "quince",   "rose",   "straw",    "tulip",  "umbrella", "violet", "water",    "xenon" ],
    [ "yellow",   "zebra",  "apple",    "banana", "cherry",   "date",   "elder",    "fig",    "grape",    "honey" ],
    [ "iris",     "jack",   "kite",     "lemon",  "mango",    "nectar", "olive",    "pear",   "quince",   "rose" ],
    [ "straw",    "tulip",  "umbrella", "violet", "water",    "xenon",  "yellow",   "zebra",  "apple",    "banana" ],
    [ "cherry",   "date",   "elder",    "fig",    "grape",    "honey",  "iris",     "jack",   "kite",     "lemon" ],
    [ "mango",    "nectar", "olive",    "pear",   "quince",   "rose",   "straw",    "tulip",  "umbrella", "violet" ],
    [ "water",    "xenon",  "yellow",   "zebra",  "apple",    "banana", "cherry",   "date",   "elder",    "fig" ],
    [ "grape",    "honey",  "iris",     "jack",   "kite",     "lemon",  "mango",    "nectar", "olive",    "pear" ],
    [ "quince",   "rose",   "straw",    "tulip",  "umbrella", "violet", "water",    "xenon",  "yellow",   "zebra" ],
    [ "apple",    "banana", "cherry",   "date",   "elder",    "fig",    "grape",    "honey",  "iris",     "jack" ],
    [ "kite",     "lemon",  "mango",    "nectar", "olive",    "pear",   "quince",   "rose",   "straw",    "tulip" ],
    [ "umbrella", "violet", "water",    "xenon",  "yellow",   "zebra",  "apple",    "banana", "cherry",   "date" ],
    [ "elder",    "fig",    "grape",    "honey",  "iris",     "jack",   "kite",     "lemon",  "mango",    "nectar" ],
    [ "olive",    "pear",   "quince",   "rose",   "straw",    "tulip",  "umbrella", "violet", "water",    "xenon" ],
    [ "yellow",   "zebra",  "apple",    "banana", "cherry",   "date",   "elder",    "fig",    "grape",    "honey" ],
    [ "iris",     "jack",   "kite",     "lemon",  "mango",    "nectar", "olive",    "pear",   "quince",   "rose" ],
    [ "straw",    "tulip",  "umbrella", "violet", "water",    "xenon",  "yellow",   "zebra",  "apple",    "banana" ],
    [ "cherry",   "date",   "elder",    "fig",    "grape",    "honey",  "iris",     "jack",   "kite",     "lemon" ],
    [ "mango",    "nectar", "olive",    "pear",   "quince",   "rose",   "straw",    "tulip",  "umbrella", "violet" ],
    [ "water",    "xenon",  "yellow",   "zebra",  "apple",    "banana", "cherry",   "date",   "elder",    "fig" ],
    [ "grape",    "honey",  "iris",     "jack",   "kite",     "lemon",  "mango",    "nectar", "olive",    "pear" ],
    [ "quince",   "rose",   "straw",    "tulip",  "umbrella", "violet", "water",    "xenon",  "yellow",   "zebra" ],
];

foreach my $thread_count (qw/1 4 8/) {
  $env->omp_num_threads($thread_count);
  
  my $aref_new = omp_get_renew_aref($aref_orig);
  my $seen_elements = shift @$aref_new;
  my $seen_threads  = shift @$aref_new;
  
  is $seen_elements, scalar(@$aref_orig) * scalar(@{$aref_orig->[0]}), q{PerlOMP_2D_AoA_NUM_ELEMENTS works correctly};
  is $seen_threads, $thread_count, qq{OMP_NUM_THREADS=$thread_count respected inside omp parallel section};
  if ($has_test_deep) {
    cmp_deeply $aref_new, $aref_orig, qq{2D Array passed by reference matches the array returned};
  }
  else {
    SKIP: { skip "Skipping cmp_deeply tests because Perl is below 5.12 or Test::Deep is unavailable", 1; }
  }
}

done_testing;

__DATA__
__C__

/* Custom driver */
AV* omp_get_renew_aref(SV *AoA) {
  
  PerlOMP_UPDATE_WITH_ENV__NUM_THREADS
  PerlOMP_RET_ARRAY_REF_ret
  
  int numRows = PerlOMP_1D_Array_NUM_ELEMENTS(AoA);
  int rowSize = 10;
  av_push(ret, newSViv(numRows * rowSize));
  
  char *raw_array[numRows][rowSize];
  PerlOMP_2D_AoA_TO_2D_STRING_ARRAY(AoA, numRows, rowSize, raw_array);
  
  char *processed[numRows][rowSize];

  #pragma omp parallel shared(raw_array, numRows, rowSize, processed)
  #pragma omp master
    av_push(ret, newSViv(omp_get_num_threads()));
  #pragma omp for collapse(2)
    for (int i = 0; i < numRows; i++) {
      for (int j = 0; j < rowSize; j++) {
        processed[i][j] = strdup(raw_array[i][j]);
      }
    }
  
  for (int i = 0; i < numRows; i++) {
    AV *row = newAV();
    for (int j = 0; j < rowSize; j++) {
      av_push(row, newSVpv(processed[i][j], 0));
      free(processed[i][j]);
    }
    av_push(ret, newRV_noinc((SV*)row));
  }
  
  return ret;
}
