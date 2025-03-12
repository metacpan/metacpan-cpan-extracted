#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;

# build and load subroutines
use OpenMP::Simple;
use OpenMP::Environment;

use Inline (
    C                 => 'DATA',
    with              => qw/OpenMP::Simple/,
);

my $env = OpenMP::Environment->new();

my $aref_orig = [
  [ 1 .. 25 ],
  [ 1 .. 25 ],
  [ 1 .. 25 ],
  [ 1 .. 25 ],
  [ 1 .. 25 ],
  [ 1 .. 25 ],
  [ 1 .. 25 ],
  [ 1 .. 25 ],
  [ 1 .. 25 ],
  [ 1 .. 25 ],
];

my $expected = [qw/1 2 3 4 5 6 7 8 9 10/];

foreach my $thread_count (qw/1 4 8/) {
  $env->omp_num_threads($thread_count);
  my $ele_count = omp_elements_count($aref_orig);
  is $ele_count, scalar @$aref_orig;

  my $row_count = omp_elements_row_count($aref_orig);
  is $row_count, scalar @$aref_orig;

  my $col_count = omp_elements_col_count($aref_orig);
  is $col_count, scalar @{$aref_orig->[0]};
}

done_testing;

__DATA__
__C__

/* Custom driver */
int omp_elements_count(SV *ARRAY) {

  /* boilerplate - updates number of threads to use with what's in $ENV{OMP_NUM_THREADS} */
  PerlOMP_UPDATE_WITH_ENV__NUM_THREADS

  int count = PerlOMP_1D_Array_NUM_ELEMENTS(ARRAY);

  return count;
}

int omp_elements_row_count(SV *ARRAY) {

  /* boilerplate - updates number of threads to use with what's in $ENV{OMP_NUM_THREADS} */
  PerlOMP_UPDATE_WITH_ENV__NUM_THREADS

  int count = PerlOMP_2D_AoA_NUM_ROWS(ARRAY);

  return count;
}

int omp_elements_col_count(SV *ARRAY) {

  /* boilerplate - updates number of threads to use with what's in $ENV{OMP_NUM_THREADS} */
  PerlOMP_UPDATE_WITH_ENV__NUM_THREADS

  int count = PerlOMP_2D_AoA_NUM_COLS(ARRAY);

  return count;
}

