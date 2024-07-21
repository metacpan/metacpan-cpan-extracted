package OpenMP::Simple;

use strict;
use warnings;
use Alien::OpenMP;

our $VERSION = q{0.1.2};

# This module is a wrapper around a ".h" file that is injected into Alien::OpenMP
# via Inline:C's AUTO_INCLUDE feature. This header file constains C MACROs for reading
# OpenMP relavent environmental variables via %ENV (set by OpenMP::Environment perhaps)
# and using the standard OpenMP runtime functions to set them.

sub Inline {
  my ($self, $lang) = @_;
  my $config = Alien::OpenMP->Inline($lang);
  $config->{AUTO_INCLUDE} .=q{

/**
All setters EXCEPT the LOCK routines,
  as defined at https://gcc.gnu.org/onlinedocs/libgomp/Runtime-Library-Routines.html

   Status                              GCC*     Description
+-------------------------------------------------------------------------------------------+
 - DONE   omp_set_num_threads          8.3.0  – Set upper team size limit
 - DONE   omp_set_schedule             8.3.0  – Set the runtime scheduling method
 - DONE   omp_set_dynamic              8.3.0  – Enable/disable dynamic teams
 - DONE   omp_set_nested               8.3.0  – Enable/disable nested parallel regions
 - DONE   omp_set_max_active_levels    8.3.0  – Limits the number of active parallel regions
 - DONE   omp_set_default_device       8.3.0  – Set the default device for target regions
 - DONE   omp_set_num_teams           12.3.0  – Set upper teams limit for teams construct
 - DONE   omp_set_teams_thread_limit  12.3.0  – Set upper thread limit for teams construct
+-------------------------------------------------------------------------------------------+
**/

/* %ENV Update Macros                                      */

#define PerlOMP_UPDATE_WITH_ENV__DEFAULT_DEVICE             \
    char *num1 = getenv("OMP_DEFAULT_DEVICE");              \
    if (num1 != NULL) {                                     \
      omp_set_default_device(atoi(num1));                   \
    }

#define PerlOMP_UPDATE_WITH_ENV__TEAMS_THREAD_LIMIT         \
    char *num2 = getenv("OMP_TEAMS_THREAD_LIMIT");          \
    if (num2 != NULL) {                                     \
      omp_set_teams_thread_limit(atoi(num2));               \
    }

#define PerlOMP_UPDATE_WITH_ENV__NUM_TEAMS                  \
    char *num3 = getenv("OMP_NUM_TEAMS");                   \
    if (num3 != NULL) {                                     \
      omp_set_num_teams(atoi(num3));                        \
    }

#define PerlOMP_UPDATE_WITH_ENV__MAX_ACTIVE_LEVELS          \
    char *num4 = getenv("OMP_MAX_ACTIVE_LEVELS");           \
    if (num4 != NULL) {                                     \
      omp_set_max_active_levels(atoi(num4));                \
    }

#define PerlOMP_UPDATE_WITH_ENV__NUM_THREADS                \
    char *num5 = getenv("OMP_NUM_THREADS");                 \
    if (num5 != NULL) {                                     \
      omp_set_num_threads(atoi(num5));                      \
    }

#define PerlOMP_UPDATE_WITH_ENV__DYNAMIC                    \
    char *VALUE1 = getenv("OMP_DYNAMIC");                   \
    if (VALUE1 == NULL) {                                   \
      omp_set_dynamic(VALUE1);                              \
    }                                                       \
    else if (strcmp(VALUE1,"TRUE") || strcmp(VALUE1,"true") || strcmp(VALUE1,"1")) { \
      omp_set_dynamic(1);                                   \
    }                                                       \
    else {                                                  \
      omp_set_dynamic(NULL);                                \
    }

#define PerlOMP_UPDATE_WITH_ENV__NESTED                     \
    char *VALUE = getenv("OMP_NESTED");                     \
    if (VALUE == NULL) {                                    \
      omp_set_nested(VALUE);                                \
    }                                                       \
    else if (strcmp(VALUE,"TRUE") || strcmp(VALUE,"true") || strcmp(VALUE,"1")) { \
      omp_set_nested(1);                                    \
    }                                                       \
    else {                                                  \
      omp_set_nested(NULL);                                 \
    };

#define PerlOMP_UPDATE_WITH_ENV__SCHEDULE                   \
    char *str = getenv("OMP_SCHEDULE");                     \
    if (str != NULL) {                                      \
      omp_sched_t SCHEDULE = omp_sched_static;              \
      int CHUNK = 1; char *pt;                              \
      pt = strtok (str,",");                                \
      if (strcmp(pt,"static")) {                            \
        SCHEDULE = omp_sched_static;                        \
      }                                                     \
      else if (strcmp(pt,"dynamic")) {                      \
        SCHEDULE = omp_sched_dynamic;                       \
      }                                                     \
      else if (strcmp(pt,"guided")) {                       \
        SCHEDULE = omp_sched_guided;                        \
      }                                                     \
      else if (strcmp(pt,"auto")) {                         \
        SCHEDULE = omp_sched_auto;                          \
      }                                                     \
      pt = strtok (NULL, ",");                              \
      if (pt != NULL) {                                     \
        CHUNK = atoi(pt);                                   \
      }                                                     \
      omp_set_schedule(SCHEDULE, CHUNK);                    \
    }

/* bundled Macros */
#define PerlOMP_GETENV_BASIC                                \
    PerlOMP_UPDATE_WITH_ENV__NUM_THREADS                    \ 
    PerlOMP_UPDATE_WITH_ENV__SCHEDULE

#define PerlOMP_GETENV_ALL                                  \
    PerlOMP_UPDATE_WITH_ENV__DEFAULT_DEVICE                 \
    PerlOMP_UPDATE_WITH_ENV__TEAMS_THREAD_LIMIT             \
    PerlOMP_UPDATE_WITH_ENV__NUM_TEAMS                      \
    PerlOMP_UPDATE_WITH_ENV__MAX_ACTIVE_LEVELS              \
    PerlOMP_UPDATE_WITH_ENV__NUM_THREADS                    \
    PerlOMP_UPDATE_WITH_ENV__DYNAMIC                        \
    PerlOMP_UPDATE_WITH_ENV__NESTED                         \
    PerlOMP_UPDATE_WITH_ENV__SCHEDULE

// ... add all of them from OpenMP::Environment, add unit tests

/* Output Init Macros (needed?) */
#define PerlOMP_RET_ARRAY_REF_ret AV* ret = newAV();sv_2mortal((SV*)ret);

/* Datastructure Introspection Functions*/

/**
 * Returns the number of elements in a 1D array from Perl
 */

int PerlOMP_1D_Array_NUM_ELEMENTS (SV *AVref) {
  return av_count((AV*)SvRV(AVref));
}

/* Datatype Converters (doxygen style comments) */

/**
 * Converts a 1D Perl Array Reference (AV*) into a 1D C array of floats; allocates retArray[numElements] by reference
 * @param[in] *Aref, int numElements, float retArray[numElements] 
 * @param[out] void 
 */ 

void PerlOMP_1D_Array_TO_1D_FLOAT_ARRAY(SV *AVref, int numElements, float retArray[numElements]) {
  AV *array    = (AV*)SvRV(AVref);
  SV **element;
  for (int i=0; i<numElements;i++) {
    element = av_fetch(array, i, 0);
    if (!element || !*element || !SvOK(*element))
      croak("Expected value at array[%d]", i);
    retArray[i] = SvNV(*element);
  }
}

/* 1D Array reference to 1D int C array ...
 * Convert a regular M-element Perl array consisting of inting point values, e.g.,
 *
 *   my $Aref = [ 10, 314, 527, 911, 538 ];
 *
 * into a C array of the same dimensions so that it can be used as exepcted with an OpenMP
 * "#pragma omp for" work sharing construct
*/

void PerlOMP_1D_Array_TO_1D_INT_ARRAY(SV *AVref, int numElements, int retArray[numElements]) {
  AV *array    = (AV*)SvRV(AVref);
  SV **element;
  for (int i=0; i<numElements;i++) {
    element = av_fetch(array, i, 0);
    if (!element || !*element || !SvOK(*element))
      croak("Expected value at array[%d]", i);
    retArray[i] = SvIV(*element);
  }
}

/* 2D AoA to 2D float C array ...
 * Convert a regular MxN Perl array of arrays (AoA) consisting of floating point values, e.g.,
 *
 *   my $AoA = [ [qw/1.01 2.02 3.03/], [qw/3.145 2.123 0.892/], [qw/19.17 60.651 20.17/] ];
 *
 * into a C array of the same dimensions so that it can be used as expected with an OpenMP
 * "#pragma omp for" work sharing construct
*/
 
// contribued by CPAN's NERDVANA - thank you!
void PerlOMP_2D_AoA_TO_2D_FLOAT_ARRAY(SV *AoA, int numRows, int rowSize, float retArray[numRows][rowSize]) {
  SV **AVref;
  if (!SvROK(AoA) || SvTYPE(SvRV(AoA)) != SVt_PVAV)
    croak("Expected Arrayref");
  for (int i=0; i<numRows; i++) {
    AVref = av_fetch((AV*)SvRV(AoA), i, 0);
    if (!AVref || !*AVref || !SvROK(*AVref) || SvTYPE(SvRV(*AVref)) != SVt_PVAV)
      croak("Expected arrayref at array[%d]", i);
    for (int j=0; j<rowSize;j++) {
      SV **element = av_fetch((AV*)SvRV(*AVref), j, 0);
      if (!element || !*element || !SvOK(*element))
        croak("Expected value at array[%d][%d]", i, j);
      retArray[i][j] = SvNV(*element);
    }
  }
}

/* 2D AoA to 2D int C array ...
 * Convert a regular MxN Perl array of arrays (AoA) consisting of inting point values, e.g.,
 *
 *   my $AoA = [ [qw/101 202 303/], [qw/3145 2123 892/], [qw/1917 60.651 2017/] ];
 *
 * into a C array of the same dimensions so that it can be used as expected with an OpenMP
 * "#pragma omp for" work sharing construct
*/
 
void PerlOMP_2D_AoA_TO_2D_INT_ARRAY(SV *AoA, int numRows, int rowSize, int retArray[numRows][rowSize]) {
  SV **AVref;
  if (!SvROK(AoA) || SvTYPE(SvRV(AoA)) != SVt_PVAV)
    croak("Expected Arrayref");
  for (int i=0; i<numRows; i++) {
    AVref = av_fetch((AV*)SvRV(AoA), i, 0);
    if (!AVref || !*AVref || !SvROK(*AVref) || SvTYPE(SvRV(*AVref)) != SVt_PVAV)
      croak("Expected arrayref at array[%d]", i);
    for (int j=0; j<rowSize;j++) {
      SV **element = av_fetch((AV*)SvRV(*AVref), j, 0);
      if (!element || !*element || !SvOK(*element))
        croak("Expected value at array[%d][%d]", i, j);
      retArray[i][j] = SvNV(*element);
    }
  }
}

/* TODO:
  * add unit tests for conversion functions
  * add some basic matrix operations (transpose for 2D, reverse for 1D)
  * experiment with simple hash ref to C struct
 * ...
*/

};
  return $config;
}

1;

__END__

=head1 NAME

OpenMP::Simple - Wrapper around C<Alien::OpenMP> that provides helpful C MACROs and
runtime functions

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
file constains C MACROs for reading OpenMP relavent environmental variables
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

=head1 PROVIDED MACROS

=head2 Updating Runtime with Environmental Variables

All MACROS have at least 1 test in the suite. Please look at these in the
Github repository to get an idea of how to use C<OpenMP::Simple>'s macros
with C<OpenMP::Environment>.

=over 4

=item C<PerlOMP_GETENV_BASIC>

Equivalent of using,

  PerlOMP_UPDATE_WITH_ENV__NUM_THREADS
  PerlOMP_UPDATE_WITH_ENV__NUM_SCHEDULE

The purpose of this bundled approach is to make it easier to get started
quickly. This list may be updated between versions. This is the recommended
one to use when starting with this module. See the L<SYNOPSIS> example.

=item C<PerlOMP_GETENV_ALL>

Equivalent of using,

    PerlOMP_UPDATE_WITH_ENV__DEFAULT_DEVICE
    PerlOMP_UPDATE_WITH_ENV__TEAMS_THREAD_LIMIT
    PerlOMP_UPDATE_WITH_ENV__NUM_TEAMS
    PerlOMP_UPDATE_WITH_ENV__MAX_ACTIVE_LEVELS
    PerlOMP_UPDATE_WITH_ENV__NUM_THREADS
    PerlOMP_UPDATE_WITH_ENV__DYNAMIC
    PerlOMP_UPDATE_WITH_ENV__NESTED
    PerlOMP_UPDATE_WITH_ENV__SCHEDULE

=item C<PerlOMP_UPDATE_WITH_ENV__NUM_THREADS>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_NUM_THREADS}>, which is managed via
C<< OpenMP::Environment->omp_num_threads[int numThreads]); >>.

=item C<PerlOMP_UPDATE_WITH_ENV__DEFAULT_DEVICE>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_DEFAULT_DEVICE}>, which is managed
via C<< OpenMP::Environment->omp_default_device([int deviceNo]); >>.

=item C<PerlOMP_UPDATE_WITH_ENV__MAX_ACTIVE_LEVELS>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_MAX_ACTIVE_LEVELS}>, which is managed
via C<< OpenMP::Environment->omp_max_active_levels([int maxLevel]); >>.

=item C<PerlOMP_UPDATE_WITH_ENV__DYNAMIC>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_DYNAMIC}>, which is managed
via C<< OpenMP::Environment->omp_dynamic(['true'|'false']); >>.

=item C<PerlOMP_UPDATE_WITH_ENV__NESTED>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_NESTED}>, which is managed
via C<< OpenMP::Environment->omp_nested(['true'|'false']); >>.

=item C<PerlOMP_UPDATE_WITH_ENV__SCHEDULE>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_SCHEDULE}>, which is managed
via C<< OpenMP::Environment->omp_schedule(...); >>.

Note: The schedule syntax is of the form I<schedule[;chunkSize]>.

=item C<PerlOMP_UPDATE_WITH_ENV__TEAMS_THREAD_LIMIT>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_TEAMS_THREAD_LIMIT}>, which is managed via C<< OpenMP::Environment->omp_([int limit]); >>.

Note: C<OMP_TEAMS_THREAD_LIMIT> is not supported until GCC 12.3.0

=item C<PerlOMP_UPDATE_WITH_ENV__NUM_TEAMS>

Updates the OpenMP runtime with the value of the environmental variable,
C<$ENV{OMP_NUM_TEAMS}>, which is managed via C<< OpenMP::Environment->omp_([int num]); >>.

Note: C<OMP_NUM_TEAMS> is not supported until GCC 12.3.0

=item C<PerlOMP_RET_ARRAY_REF_ret>

(may not be needed) - creates a new C<AV*> and sets it I<mortal> (doesn't
survive outside of the current scope). Used when wanting to return an array
reference that's been populated via C<av_push>.

=back

=head1 PROVIDED PERL TO C CONVERSION FUNCTIONS

B<Note>: Work is currently focused on finding the true limits of the Perl C
API. It is likely that in a lot of cases, elements in Perl Arrays (AV) and Perl
Hashes (HV) maybe accessed safely without first transferring the entire data
structures into its pure C<C> equivalent.

=over 4

=item C<PerlOMP_2D_AoA_TO_2D_FLOAT_ARRAY(AoA, num_nodes, dims, nodes)>

Used to extract the contents of a 2D rectangular Perl array reference that
has been used to represent a 2D matrix.

    float nodes[num_nodes][dims];
    PerlOMP_2D_AoA_TO_2D_FLOAT_ARRAY(AoA, num_nodes, dims, nodes);

=back

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

=head1 LICENSE & COPYRIGHT

Same as Perl.
