#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;
use Test::Deep;
use Util::H2O::More qw//;

# build and load subroutines
use OpenMP::Simple;
use OpenMP::Environment;

use Inline (
    C                 => 'DATA',
    with              => qw/OpenMP::Simple/,
);

my $env = OpenMP::Environment->new();

my $aref_orig = [
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
  [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.01],
];

my $expected = [ '1.10000002384186', '2.20000004768372', '3.29999995231628', '4.40000009536743', '5.5', '6.59999990463257', '7.69999980926514', '8.80000019073486', '9.89999961853027', '10.0100002288818' ];

foreach my $thread_count (qw/1 4 8/) {
  $env->omp_num_threads($thread_count);

  foreach my $row_orig (@$aref_orig)  {
    my $aref_new      = omp_get_renew_aref($row_orig);
    my $seen_elements = shift @$aref_new;
    my $seen_threads  = shift @$aref_new;
    is $seen_elements, scalar @$row_orig, q{PerlOMP_1D_Array_NUM_ELEMENTS works on original ARRAY reference};
    is $seen_threads, $thread_count, qq{OMP_NUM_THREADS=$thread_count is respected inside of the, omp parallel section, as expected};
    cmp_deeply $aref_new, $expected, qq{Row summed array ref returned as expected from $thread_count OpenMP threads};
    cmp_deeply $aref_new, $expected, qq{PerlOMP_1D_Array_TO_1D_FLOAT_ARRAY worked to convert original ARRAY reference to raw C 1D array of floats};
  }
}

done_testing;

__DATA__
__C__

/* Custom driver */
AV* omp_get_renew_aref(SV *ARRAY) {

  /* boilerplate - updates number of threads to use with what's in $ENV{OMP_NUM_THREADS} */
  PerlOMP_UPDATE_WITH_ENV__NUM_THREADS

  /* boilerplate - creates an array to return back to perl, named "ret" */
  /* note, "ret" can contain anything, when added via "av_push"         */
  PerlOMP_RET_ARRAY_REF_ret

  /* non-boilerplate (for the test, we want this to apply to all rows, though) */
  int num_elements = PerlOMP_1D_Array_NUM_ELEMENTS(ARRAY);
  av_push(ret, newSViv(num_elements));

  /* get 1d array ref into a 1d C array */
  float raw_array[num_elements];                                      // create native 2D array as target
  PerlOMP_1D_Array_TO_1D_FLOAT_ARRAY(ARRAY, num_elements, raw_array); // call macro to put AoA into native "nodes" array

  float sum[num_elements];
  #pragma omp parallel shared(raw_array,num_elements,sum)
  #pragma omp master
    av_push(ret, newSViv(omp_get_num_threads()));
  #pragma omp for
    for(int i=0; i<num_elements; i++) {
      sum[i] = raw_array[i];
    }

  for(int i=0; i<num_elements; i++) {
    av_push(ret, newSVnv(sum[i]));
  }

  // AV* 'ret' comes from "PerlOMP_RET_ARRAY_REF_ret" macro called above
  return ret;
}
