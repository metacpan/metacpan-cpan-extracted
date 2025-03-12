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
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
  [ 1 .. 10 ],
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
      cmp_deeply $aref_new, $expected, qq{Row summed array ref returned as expected from $thread_count OpenMP threads};
      cmp_deeply $aref_new, $expected, qq{PerlOMP_1D_Array_TO_1D_INT_ARRAY worked to convert original ARRAY reference to raw C 1D array of floats};
    }
    else {
      SKIP: { skip "Skipping cmp_deeply tests because Perl is below 5.12 or Test::Deep is unavailable", 2; }
    }
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
  int raw_array[num_elements];                                        // create native 2D array as target
  PerlOMP_1D_Array_TO_1D_INT_ARRAY_r(ARRAY, num_elements, raw_array); // call macro to put AoA into native "nodes" array - threaded version

  int sum[num_elements];
  #pragma omp parallel shared(raw_array,num_elements,sum)
  #pragma omp master
    av_push(ret, newSViv(omp_get_num_threads()));
  #pragma omp for
    for(int i=0; i<num_elements; i++) {
      sum[i] = raw_array[i];
    }

  for(int i=0; i<num_elements; i++) {
    av_push(ret, newSViv(sum[i]));
  }

  // AV* 'ret' comes from "PerlOMP_RET_ARRAY_REF_ret" macro called above
  return ret;
}
