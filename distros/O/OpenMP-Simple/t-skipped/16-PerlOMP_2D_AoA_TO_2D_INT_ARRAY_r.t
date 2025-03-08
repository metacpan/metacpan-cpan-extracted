#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;
use Test::Deep;

# build and load subroutines
use OpenMP::Simple;
use OpenMP::Environment;

use Inline (
    C                 => 'DATA',
    with              => qw/OpenMP::Simple/,
);

my $env = OpenMP::Environment->new();

my $aref_orig = [
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
  [1 .. 10],
];

my $expected = [ 55, 55, 55, 55, 55, 55, 55, 55, 55, 55,
                 55, 55, 55, 55, 55, 55, 55, 55, 55, 55,
                 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, ];

foreach my $thread_count (qw/2/) {
  $env->omp_num_threads($thread_count);
  my $aref_new     = omp_get_renew_aref( $aref_orig, scalar @{$aref_orig->[0]} );
  my $seen_rows    = shift @$aref_new;
  my $seen_threads = shift @$aref_new;
  is $seen_rows, scalar @$aref_orig, q{PerlOMP_1D_Array_NUM_ELEMENTS works on original ARRAY reference};
  is $seen_threads, $thread_count, qq{OMP_NUM_THREADS=$thread_count is respected inside of the, omp parallel section, as expected};
  cmp_deeply $aref_new, $expected, qq{Row summed array ref returned as expected from $thread_count OpenMP threads};
  cmp_deeply $aref_new, $expected, qq{PerlOMP_2D_AoA_TO_2D_INT_ARRAY worked to convert original ARRAY reference to raw C 2D array of ints};
}

done_testing;

__DATA__
__C__

/* Custom driver */
AV* omp_get_renew_aref(SV *AoA, int row_size) {

  /* boilerplate - updates number of threads to use with what's in $ENV{OMP_NUM_THREADS} */
  PerlOMP_UPDATE_WITH_ENV__NUM_THREADS

  /* boilerplate - creates an array to return back to perl, named "ret" */
  /* note, "ret" can contain anything, when added via "av_push"         */
  PerlOMP_RET_ARRAY_REF_ret

  /* non-boilerplate (for the test, we want this to apply to all rows, though) */
  int num_rows = PerlOMP_1D_Array_NUM_ELEMENTS(AoA);
  av_push(ret, newSViv(num_rows));

  /* get 2d array ref into a 2d C array */
  int raw_array[num_rows][row_size];                                  // create native 2D array as target
  PerlOMP_2D_AoA_TO_2D_INT_ARRAY_r(AoA, num_rows, row_size, raw_array); // call macro to put AoA into native elements

  int sum[num_rows];
  #pragma omp parallel shared(raw_array,num_rows,row_size,sum)
  #pragma omp master
    av_push(ret, newSViv(omp_get_num_threads()));
  #pragma omp for
    for(int i=0; i<num_rows; i++) {
      sum[i] = 0.0;
      for(int j=0; j<row_size; j++) {
        sum[i] += raw_array[i][j];
      }
    }

  for(int i=0; i<num_rows; i++) {
    av_push(ret, newSViv(sum[i]));
  }

  // AV* 'ret' comes from "PerlOMP_RET_ARRAY_REF_ret" macro called above
  return ret;
}
