package OpenMP::Simple;

use strict;
use warnings;
use Alien::OpenMP;

our $VERSION = q{0.2.6};

# This module is a wrapper around a ".h" file that is injected into Alien::OpenMP
# via Inline:C's AUTO_INCLUDE feature. This header file constains C macros for reading
# OpenMP relavent environmental variables via %ENV (set by OpenMP::Environment perhaps)
# and using the standard OpenMP runtime functions to set them.

use File::ShareDir 'dist_dir';

my $share_dir = dist_dir('OpenMP-Simple');

sub Inline {
  my ($self, $lang) = @_;
  my $config = Alien::OpenMP->Inline($lang);
  $config->{INC} = qq{-I$share_dir};
  $config->{AUTO_INCLUDE} .= qq{\n#include "$share_dir/ppport.h"\n#include "$share_dir/openmp-simple.h"\n};
  return $config;
}

1;

__END__

=head1 NAME

OpenMP::Simple - Wrapper around C<Alien::OpenMP> that provides helpful C macros and
runtime C functions

=head1 SYNOPSIS

  use strict;
  use warnings;
  
  use OpenMP::Simple;
  use OpenMP::Environment;
  
  use Inline (
      C    => 'DATA',
      with => qw/OpenMP::Simple/,
  );
  
  my $env = OpenMP::Environment->new;
  
  for my $want_num_threads ( 1 .. 8 ) {
      $env->omp_num_threads($want_num_threads);

      $env->assert_omp_environment; # (optional) validates %ENV

      # call parallelized C function
      my $got_num_threads = _check_num_threads();

      printf "%0d threads spawned in ".
              "the OpenMP runtime, expecting %0d\n",
                $got_num_threads, $want_num_threads;
  }
  
  __DATA__
  __C__

  int _check_num_threads() {
    PerlOMP_GETENV_BASIC
    int ret = 0;
    #pragma omp parallel
    {
      #pragma omp single
      ret = omp_get_num_threads();
    }
    return ret;
  }

See the C<./t> directory for many more examples. It should be obvious,
but C<Test::More> is not required; it's just for show and convenience here.

=head1 DESCRIPTION

This module is a wrapper that provides a custom ".h" file, which is injected
into L<Alien::OpenMP> via C<Inline:C>'s C<AUTO_INCLUDE> hook. This header
file constains C macros for reading OpenMP relavent environmental variables
via C<%ENV> (set preferably using L<OpenMP::Environment>) and by calling
the standard OpenMP runtime functions to set them (e.g., C<OMP_NUM_THREADS>
/ C<set_omp_num_threads>).

C<OpenMP::Simple> is meant to work directly with C<OpenMP::Environment>
in a way that provides the same runtime control experience that OpenMP's
environmental variables provides.

The most common use case is updating the number of OpenMP threads that are
defined via C<OMP_NUM_THREADS>.

=head2 Experimental Parts

There is some attempt at helping to deal with getting data structures
that are very common in the computational domains into and out of these
C<Inline::C>'d routines that are parallized via OpenMP. We are currently
investigating what is actually needed in this regard. It is possible that a lot
of this is unnecessariy and it is likely that a large number of C<read-only>
scenerios involving Perl internal data structures and OpenMP threads are
actually I<thread-safe>. This does not address the potential knowledge gap
for those who are more experienced with C<C> and OpenMP than they are with
the Perl C API for accessing internal Perl data structures inside of C code.

As time advances, the chances that these change will get smaller; but that's
not to say breaking changes will not get introduced. But changes introduced
will be for correctness or reducing the number of parameters that developers
are expected to provide.

=head1 SEE TESTS FOR CODE EXAMPLES

The tests that are distributed with this module are an excellent source to
examine for example uses.

=head1 PROVIDED C MACROS

=head2 Updating Runtime with Environmental Variables

All macros have at least 1 test in the suite. Please look at these in the
Github repository to get an idea of how to use C<OpenMP::Simple>'s macros
with C<OpenMP::Environment>.

=head3 C<PerlOMP_GETENV_BASIC>

Equivalent of using,

  PerlOMP_UPDATE_WITH_ENV__NUM_THREADS
  PerlOMP_UPDATE_WITH_ENV__NUM_SCHEDULE

The purpose of this bundled approach is to make it easier to get started
quickly. This list may be updated between versions. This is the recommended
one to use when starting with this module. See the L<SYNOPSIS> example.

=head3 C<PerlOMP_UPDATE_WITH_ENV__NUM_THREADS>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_NUM_THREADS}>, which is meant to be managed with
L<OpenMP::Environment>.

=head3 C<PerlOMP_UPDATE_WITH_ENV__DEFAULT_DEVICE>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_DEFAULT_DEVICE}>, which is meant to be managed with
L<OpenMP::Environment>.

  use strict;
  use warnings;
  
  use OpenMP::Simple;
  use OpenMP::Environment;
  use Test::More tests => 8;
  
  use Inline (
      C    => 'DATA',
      with => qw/OpenMP::Simple/,
  );
  
  my $env = OpenMP::Environment->new;
  
  note qq{Testing macro provided by OpenMP::Simple, 'PerlOMP_UPDATE_WITH_ENV__DEFAULT_DEVICE'};
  for my $default_device ( 1 .. 8 ) {
      my $current_value = $env->omp_default_device($default_device);
      is _get_default_device(), $default_device, sprintf qq{The number of threads (%0d) spawned in the OpenMP runtime via OMP_DEFAULT_DEVICE, as expected}, $default_device;
  }
  
  __DATA__
  __C__
  int _get_default_device() {
    PerlOMP_UPDATE_WITH_ENV__DEFAULT_DEVICE
    int ret = 0;
    #pragma omp parallel
    {
      #pragma omp single
      ret = omp_get_default_device();
    }
    return ret;
  }
  
  __END__
  
=head3 C<PerlOMP_UPDATE_WITH_ENV__MAX_ACTIVE_LEVELS>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_MAX_ACTIVE_LEVELS}>, which is meant to be managed with L<OpenMP::Environment>.


=head3 C<PerlOMP_UPDATE_WITH_ENV__DYNAMIC>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_DYNAMIC}>, which is meant to be managed with L<OpenMP::Environment>.


=head3 C<PerlOMP_UPDATE_WITH_ENV__NESTED>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_NESTED}>, which is meant to be managed with L<OpenMP::Environment>.

=head3 C<PerlOMP_UPDATE_WITH_ENV__SCHEDULE>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_SCHEDULE}>, which is meant to be managed with L<OpenMP::Environment>.

  use strict;
  use warnings;
  
  use OpenMP::Simple;
  use OpenMP::Environment;
  use Util::H2O::More qw/h2o/;
  use Test::More;
  
  use Inline (
      C                 => 'DATA',
      with              => qw/OpenMP::Simple/,
  );
  
  my $env = OpenMP::Environment->new;
  
  note qq{Testing macro provided by OpenMP::Simple, 'PerlOMP_UPDATE_WITH_ENV__NUM_THREADS'};
  
  # generate schedule value look up
  my $schedules = {};
  foreach my $sched (qw/static dynamic guided auto/) {
    $schedules->{$sched} = _omp_sched_t_to_int($sched);
  }
  h2o $schedules;
  
  foreach my $sched (qw/static dynamic guided auto/) {
    foreach my $chunk (qw/1 10 100 1000 10000/) {
      my $current_value = $env->omp_schedule(qq{$sched,$chunk});
      note $current_value;
      _set_schedule_with_macro();
      my $set_schedule = _get_schedule();
      is $set_schedule, $schedules->$sched, sprintf qq{Schedule '%s' set in the OpenMP runtime, as expected.}, $sched;
      my $set_chunk = _get_chunk();
      is $chunk, $set_chunk, sprintf qq{Chunk size '% 5d' set in the OpenMP runtime, as expected.}, $set_chunk;
    }
  }
  
  done_testing;
  
  __DATA__
  __C__
  void _set_schedule_with_macro() {
    PerlOMP_UPDATE_WITH_ENV__SCHEDULE
  }
  
  int _get_schedule() {
    omp_sched_t *sched;
    int *chunk;
    #pragma omp parallel
    {
      #pragma omp single
      omp_get_schedule(&sched, &chunk);
    }
    return sched;
  }
  
  int _get_chunk() {
    omp_sched_t *sched;
    int *chunk;
    #pragma omp parallel
    {
      #pragma omp single
      omp_get_schedule(&sched, &chunk);
    }
    return chunk;
  }
  
  int _omp_sched_t_to_int(char *schedule) {
    int ret = -1;
    #pragma omp parallel
    {
      #pragma omp single
        if (strcmp(schedule,"static")) {
          ret = omp_sched_static;
        }
        else if (strcmp(schedule,"dynamic")) {
          ret = omp_sched_dynamic;
        }
        else if (strcmp(schedule,"guided")) {
          ret = omp_sched_guided;
        }
        else if (strcmp(schedule,"auto")) {
          ret = omp_sched_auto;
        }
    }
    return ret;
  }
  
  __END__
  
=head3 C<PerlOMP_UPDATE_WITH_ENV__TEAMS_THREAD_LIMIT>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_TEAMS_THREAD_LIMIT}>, which is meant to be managed with L<OpenMP::Environment>.

Note: C<OMP_TEAMS_THREAD_LIMIT> is not supported until GCC 12.3.0

=head3 C<PerlOMP_UPDATE_WITH_ENV__NUM_TEAMS>

Updates the OpenMP runtime with the value of the environmental variable,
C<$ENV{OMP_NUM_TEAMS}>, which is meant to be managed with L<OpenMP::Environment>.

Note: C<OMP_NUM_TEAMS> is not supported until GCC 12.3.0

=head3 C<PerlOMP_RET_ARRAY_REF_ret>

(may not be needed) - creates a new C<AV*> and sets it I<mortal> (doesn't
survive outside of the current scope). Used when wanting to return an array
reference that's been populated via C<av_push>.

  __DATA__
  __C__

  void some_inline_c_function (...
    
    ...

    /* boilerplate - creates an array to return back to perl, named "ret" */
    /* note, "ret" can contain anything, when added via "av_push"         */
    PerlOMP_RET_ARRAY_REF_ret
    
    ...
    
    for(int i=0; i<num_elements; i++) {
      av_push(ret, newSVnv(sum[i]));
    }
     
    // AV* 'ret' comes from "PerlOMP_RET_ARRAY_REF_ret" macro called above
    return ret;
  }

=head1 PROVIDED C FUNCTIONS FOR COUNTING PERL ARRAYS

=head2 C<int PerlOMP_1D_Array_NUM_ELEMENTS (SV *AVref)>

Returns the integer count of number of elements in the array reference. The 
function doesn't care what is in the elements.

=head2 C<int PerlOMP_2D_AoA_NUM_ROWS(SV *AoAref)>

Returns the integer count of number of rows in a 2D array reference. The
function doesn't care what the rows looks like or what is in them

=head2 C<int PerlOMP_2D_AoA_NUM_COLS(SV *AoAref)>

Returns the number of elements in the first row of the provided 2D array
reference. It assumes all rows are the same. It doesn't verify the contents
of each row.

=head2 Examples

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

=head1 PROVIDED C FUNCTIONS FOR CONVERTING 1D PERL ARRAYS TO C ARRAYS

B<Note>: Work is currently focused on finding the true limits of the Perl C
API. It is likely that in a lot of cases, elements in Perl Arrays (AV) and Perl
Hashes (HV) maybe accessed safely without first transferring the entire data
structures into its pure C<C> equivalent.

=head2 C<void PerlOMP_1D_Array_TO_1D_FLOAT_ARRAY>

  void PerlOMP_1D_Array_TO_1D_FLOAT_ARRAY(SV *AVref, int numElements, float retArray[numElements]);

Converts a 1D Perl Array Reference (C<AV*>) into a 1D C array of floats. This function assumes the Perl array contains numeric floating point values.

=head2 C<void PerlOMP_1D_Array_TO_1D_FLOAT_ARRAY_r>

  void PerlOMP_1D_Array_TO_1D_FLOAT_ARRAY_r(SV *AVref, int numElements, float retArray[numElements]);

The parallelized version of C<void PerlOMP_1D_Array_TO_1D_FLOAT_ARRAY> using OpenMP. This function performs the same operation, but the array conversion is parallelized with OpenMP.

=head2 C<void PerlOMP_1D_Array_TO_1D_INT_ARRAY>

  void PerlOMP_1D_Array_TO_1D_INT_ARRAY(SV *AVref, int numElements, int retArray[numElements]);

Converts a 1D Perl Array Reference (C<AV*>) into a 1D C array of integers. This function assumes the Perl array contains integer values.

=head2 C<void PerlOMP_1D_Array_TO_1D_INT_ARRAY_r>

  void PerlOMP_1D_Array_TO_1D_INT_ARRAY_r(SV *AVref, int numElements, int retArray[numElements]);

The parallelized version of C<void PerlOMP_1D_Array_TO_1D_INT_ARRAY> using OpenMP. This function performs the same operation, but the array conversion is parallelized with OpenMP.

=head2 C<void PerlOMP_1D_Array_TO_1D_STRING_ARRAY>

  void PerlOMP_1D_Array_TO_1D_STRING_ARRAY(SV *AVref, int numElements, char *retArray[numElements]);

Converts a 1D Perl Array Reference (C<AV*>) into a 1D C array of strings. The Perl array should contain string values.

=head2 C<void PerlOMP_1D_Array_TO_1D_STRING_ARRAY_r>

  void PerlOMP_1D_Array_TO_1D_STRING_ARRAY_r(SV *AVref, int numElements, char *retArray[numElements]);

The parallelized version of C<PerlOMP_1D_Array_TO_1D_STRING_ARRAY> using OpenMP. This function performs the same operation, but the array conversion is parallelized with OpenMP.

=head2 Example

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
      cmp_deeply $aref_new, $expected, qq{Row summed array ref returned as expected from $thread_count OpenMP threads};
      cmp_deeply $aref_new, $expected, qq{PerlOMP_1D_Array_TO_1D_INT_ARRAY worked to convert original ARRAY reference to raw C 1D array of floats};
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
    int raw_array[num_elements];                                      // create native 1D array as target
    PerlOMP_1D_Array_TO_1D_INT_ARRAY(ARRAY, num_elements, raw_array); // call macro to put AoA into native "nodes" array
  
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

=head1 PROVIDED C FUNCTIONS FOR CONVERTING 2D PERL ARRAYS TO C ARRAYS

=head2 C<void PerlOMP_2D_AoA_TO_2D_FLOAT_ARRAY>

  void PerlOMP_2D_AoA_TO_2D_FLOAT_ARRAY(SV *AoA, int numRows, int rowSize, float retArray[numRows][rowSize]);

Converts a 2D Array of Arrays (AoA) in Perl into a 2D C array of floats. The Perl array should be an array of arrays, where each inner array contains floating point values.

=head2 C<void PerlOMP_2D_AoA_TO_2D_FLOAT_ARRAY_r>

  void PerlOMP_2D_AoA_TO_2D_FLOAT_ARRAY_r(SV *AoA, int numRows, int rowSize, float retArray[numRows][rowSize]);

The parallelized version of C<void PerlOMP_2D_AoA_TO_2D_FLOAT_ARRAY> using OpenMP. This function performs the same operation, but the array conversion is parallelized with OpenMP.

=head2 C<void PerlOMP_2D_AoA_TO_2D_INT_ARRAY>

  void PerlOMP_2D_AoA_TO_2D_INT_ARRAY(SV *AoA, int numRows, int rowSize, int retArray[numRows][rowSize]);

Converts a 2D Array of Arrays (AoA) in Perl into a 2D C array of integers. The Perl array should be an array of arrays, where each inner array contains integer values.

=head2 C<void PerlOMP_2D_AoA_TO_2D_INT_ARRAY_r>

  void PerlOMP_2D_AoA_TO_2D_INT_ARRAY_r(SV *AoA, int numRows, int rowSize, int retArray[numRows][rowSize]);

The parallelized version of C<void PerlOMP_2D_AoA_TO_2D_INT_ARRAY> using OpenMP. This function performs the same operation, but the array conversion is parallelized with OpenMP.

=head2 C<void PerlOMP_2D_AoA_TO_2D_STRING_ARRAY>

  void PerlOMP_2D_AoA_TO_2D_STRING_ARRAY(SV *AoA, int numRows, int rowSize, char *retArray[numRows][rowSize]);
  
Converts a 2D Array of Arrays (AoA) in Perl into a 2D C array of strings. The Perl array should be an array of arrays, where each inner array contains string values.

=head2 C<void PerlOMP_2D_AoA_TO_2D_STRING_ARRAY_r>

  void PerlOMP_2D_AoA_TO_2D_STRING_ARRAY_r(SV *AoA, int numRows, int rowSize, char *retArray[numRows][rowSize]);
  
The parallelized version of C<void PerlOMP_2D_AoA_TO_2D_STRING_ARRAY> using OpenMP. This function performs the same operation, but the array conversion is parallelized with OpenMP.

=head2 Example

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
    cmp_deeply $aref_new, $aref_orig, qq{2D Array passed by reference matches the array returned};
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

=head1 PROVIDED ARRAY MEMBER VERIFICATION FUNCTIONS

=head2 C<void PerlOMP_VERIFY_1D_Array>

  void PerlOMP_VERIFY_1D_Array(SV* array);

Verifies that the given Perl variable is a valid 1D array reference.

=head2 C<void PerlOMP_VERIFY_1D_INT_ARRAY>

  void PerlOMP_VERIFY_1D_INT_ARRAY(SV* array);

Verifies that the given 1D array contains only integer values.

=head2 C<void PerlOMP_VERIFY_1D_FLOAT_ARRAY>

  void PerlOMP_VERIFY_1D_FLOAT_ARRAY(SV* array);

Verifies that the given 1D array contains only floating-point values.

=head2 C<void PerlOMP_VERIFY_1D_CHAR_ARRAY>

  void PerlOMP_VERIFY_1D_CHAR_ARRAY(SV* array);

Verifies that the given 1D array contains only string values.

=head2 C<void PerlOMP_VERIFY_2D_AoA>

  void PerlOMP_VERIFY_2D_AoA(SV* array);

Verifies that the given Perl variable is a valid 2D array of arrays (AoA) reference.

=head2 C<void PerlOMP_VERIFY_2D_INT_ARRAY>

  void PerlOMP_VERIFY_2D_INT_ARRAY(SV* array);

Verifies that the given 2D array contains only integer values.

=head2 C<void PerlOMP_VERIFY_2D_FLOAT_ARRAY>

  void PerlOMP_VERIFY_2D_FLOAT_ARRAY(SV* array);

Verifies that the given 2D array contains only floating-point values.

=head2 C<void PerlOMP_VERIFY_2D_STRING_ARRAY>

  void PerlOMP_VERIFY_2D_STRING_ARRAY(SV* array);

Verifies that the given 2D array contains only string values.

=head2 Examples

  #!/usr/bin/env perl
  
  use strict;
  use warnings;
  use OpenMP::Simple;
  use Inline (
      C                 => 'DATA',
      with              => qw/OpenMP::Simple/,
  );
  use Test::More;
  use Test::Exception;
  
  my $valid_1d_int = [1, 2, 3, 4, 5];
  my $valid_1d_float = [1.1, 2.2, 3.3, 4.4, 5.5];
  my $valid_1d_string = ["ant", "bat", "cat", "dog"];
  
  my $valid_2d_int = [[1, 2], [3, 4], [5, 6]];
  my $valid_2d_float = [[1.1, 2.2], [3.3, 4.4], [5.5, 6.6]];
  my $valid_2d_string = [["ark", "bar"], ["car", "day"], ["egg", "fly"]];
  
  my $invalid_scalar = 42;
  my $invalid_1d_array = { key => "value" };
  
  # Verify 1D arrays
  dies_ok { _PerlOMP_VERIFY_1D_Array($invalid_scalar) } "Scalar should not be a valid 1D array";
  lives_ok { _PerlOMP_VERIFY_1D_Array($valid_1d_int) } "Valid 1D array passes verification";
  
  lives_ok { _PerlOMP_VERIFY_1D_INT_ARRAY($valid_1d_int) } "Valid 1D integer array";
  dies_ok { _PerlOMP_VERIFY_1D_INT_ARRAY($valid_1d_float) } "Float 1D array should fail int verification";
  
  lives_ok { _PerlOMP_VERIFY_1D_FLOAT_ARRAY($valid_1d_float) } "Valid 1D float array";
  dies_ok { _PerlOMP_VERIFY_1D_FLOAT_ARRAY($valid_1d_int) } "Int 1D array should fail float verification";
  
  lives_ok { _PerlOMP_VERIFY_1D_STRING_ARRAY($valid_1d_string) } "Valid 1D string array";
  dies_ok { _PerlOMP_VERIFY_1D_STRING_ARRAY($valid_1d_int) } "Int 1D array should fail string verification";
  
  # Verify 2D arrays
  dies_ok { _PerlOMP_VERIFY_2D_AoA($invalid_scalar) } "Scalar should not be a valid 2D array";
  lives_ok { _PerlOMP_VERIFY_2D_AoA($valid_2d_int) } "Valid 2D array passes verification";
  
  lives_ok { _PerlOMP_VERIFY_2D_INT_ARRAY($valid_2d_int) } "Valid 2D integer array";
  dies_ok { _PerlOMP_VERIFY_2D_INT_ARRAY($valid_2d_float) } "Float 2D array should fail int verification";
  
  lives_ok { _PerlOMP_VERIFY_2D_FLOAT_ARRAY($valid_2d_float) } "Valid 2D float array";
  dies_ok { _PerlOMP_VERIFY_2D_FLOAT_ARRAY($valid_2d_int) } "Int 2D array should fail float verification";
  
  lives_ok { _PerlOMP_VERIFY_2D_STRING_ARRAY($valid_2d_string) } "Valid 2D string array";
  dies_ok { _PerlOMP_VERIFY_2D_STRING_ARRAY($valid_2d_int) } "Int 2D array should fail string verification";
  
  done_testing();
  
  __DATA__
  __C__
  
  void _PerlOMP_VERIFY_1D_Array(SV* array) { PerlOMP_VERIFY_1D_Array(array); }
  void _PerlOMP_VERIFY_1D_INT_ARRAY(SV* array) { PerlOMP_VERIFY_1D_INT_ARRAY(array); }
  void _PerlOMP_VERIFY_1D_FLOAT_ARRAY(SV* array) { PerlOMP_VERIFY_1D_FLOAT_ARRAY(array); }
  void _PerlOMP_VERIFY_1D_STRING_ARRAY(SV* array) { PerlOMP_VERIFY_1D_STRING_ARRAY(array); }
  void _PerlOMP_VERIFY_2D_AoA(SV* array) { PerlOMP_VERIFY_2D_AoA(array); }
  void _PerlOMP_VERIFY_2D_INT_ARRAY(SV* array) { PerlOMP_VERIFY_2D_INT_ARRAY(array); }
  void _PerlOMP_VERIFY_2D_FLOAT_ARRAY(SV* array) { PerlOMP_VERIFY_2D_FLOAT_ARRAY(array); }
  void _PerlOMP_VERIFY_2D_STRING_ARRAY(SV* array) { PerlOMP_VERIFY_2D_STRING_ARRAY(array); }

=head1 SEE ALSO

This is a module that aims at making it easier to bootstrap Perl+OpenMP
programs. It is designed to work together with L<OpenMP::Environment>.

This module heavily favors the C<GOMP> implementation of the OpenMP
specification within gcc. In fact, it has not been tested with any other
implementations because L<Alien::OpenMP> doesn't support anything other
than GCC at the time of this writing due to lack of anyone asking for it.

L<https://gcc.gnu.org/onlinedocs/libgomp/index.html>

Please also see the C<rperl> project for a glimpse into the potential future
of Perl+OpenMP, particularly in regards to thread-safe data structures.

L<https://www.rperl.org>

=head1 AUTHOR

Brett Estrade L<< <oodler@cpan.org> >>

=head1 AI GENERATED CODE DISCLAIMER

B<Please be advised>, for full transparency (and to set a good precedence,)
please note that the conversion functions, verification functions, their
POD entries, and testing functions werge generated with great assistance
using the "I<Perl Programming Expert By DRAKOPOULOS ANASTASIOS>" chatGPT.

=head1 LICENSE & COPYRIGHT

Same as Perl.
