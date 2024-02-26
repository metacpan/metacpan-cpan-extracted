package OpenMP::Simple;

use strict;
use warnings;
use Alien::OpenMP;

our $VERSION = q{0.0.5};

sub Inline {
  my ($self, $lang) = @_;
  my $config = Alien::OpenMP->Inline($lang);
  $config->{AUTO_INCLUDE} .=q{

/**
All setters EXCEPT the LOCK retoutines,
  as defined at https://gcc.gnu.org/onlinedocs/libgomp/Runtime-Library-Routines.html

   Status                              GCC*     Description
+-------------------------------------------------------------------------------------------+
 - DONE   omp_set_num_threads          8.3.0  – Set upper team size limit
 - DONE   omp_set_schedule             8.3.0  – Set the runtime scheduling method
 - DONE   omp_set_dynamic              8.3.0  – Enable/disable dynamic teams
 - DONE   omp_set_nested               8.3.0  – Enable/disable nested parallel regions
 - DONE   omp_set_max_active_levels    8.3.0  – Limits the number of active parallel regions
 - DONE   omp_set_default_device       8.3.0 – Set the default device for target regions
 - DONE   omp_set_num_teams           12.3.0  – Set upper teams limit for teams construct
 - DONE   omp_set_teams_thread_limit  12.3.0 – Set upper thread limit for teams construct
+-------------------------------------------------------------------------------------------+
**/

/* %ENV Update Macros */

#define PerlOMP_UPDATE_WITH_ENV__DEFAULT_DEVICE                      \
    char *num = getenv("OMP_DEFAULT_DEVICE");               \
    omp_set_default_device(atoi(num));                      ///< read and update with $ENV{OMP_NUM_TEAMS}

#define PerlOMP_UPDATE_WITH_ENV__TEAMS_THREAD_LIMIT                  \
    char *num = getenv("OMP_TEAMS_THREAD_LIMIT");           \
    omp_set_teams_thread_limit(atoi(num));                  ///< read and update with $ENV{OMP_NUM_TEAMS}

#define PerlOMP_UPDATE_WITH_ENV__NUM_TEAMS                           \
    char *num = getenv("OMP_NUM_TEAMS");                    \
    omp_set_num_teams(atoi(num));                           ///< read and update with $ENV{OMP_NUM_TEAMS}

#define PerlOMP_UPDATE_WITH_ENV__MAX_ACTIVE_LEVELS                   \
    char *num = getenv("OMP_MAX_ACTIVE_LEVELS");            \
    omp_set_max_active_levels(atoi(num));                   ///< read and update with $ENV{OMP_MAX_ACTIVE_LEVELS}

#define PerlOMP_UPDATE_WITH_ENV__NUM_THREADS                         \
    char *num = getenv("OMP_NUM_THREADS");                  \
    omp_set_num_threads(atoi(num));                         ///< read and update with $ENV{OMP_NUM_THREADS}

#define PerlOMP_UPDATE_WITH_ENV__DYNAMIC                             \
    char *VALUE = getenv("OMP_DYNAMIC");                    \
    if (VALUE == NULL) {                                    \
      omp_set_dynamic(VALUE);                               \
    }                                                       \
    else if (strcmp(VALUE,"TRUE") || strcmp(VALUE,"true") || strcmp(VALUE,"1")) { \
      omp_set_dynamic(1);                                   \
    }                                                       \
    else {                                                  \
      omp_set_dynamic(NULL);                                \
    };                                                      ///> read and update with $ENV{OMP_DYNAMIC} 

#define PerlOMP_UPDATE_WITH_ENV__NESTED                              \
    char *VALUE = getenv("OMP_NESTED");                     \
    if (VALUE == NULL) {                                    \
      omp_set_nested(VALUE);                                \
    }                                                       \
    else if (strcmp(VALUE,"TRUE") || strcmp(VALUE,"true") || strcmp(VALUE,"1")) { \
      omp_set_nested(1);                                    \
    }                                                       \
    else {                                                  \
      omp_set_nested(NULL);                                 \
    };                                                      ///> read and update with $ENV{OMP_NESTED} 

#define PerlOMP_UPDATE_WITH_ENV__SCHEDULE                            \
    char *str = getenv("OMP_SCHEDULE");                     \
    omp_sched_t SCHEDULE = omp_sched_static;                \
    int CHUNK = 1; char *pt;                                \
    pt = strtok (str,",");                                  \
    if (strcmp(pt,"static")) {                              \
      SCHEDULE = omp_sched_static;                          \
    }                                                       \
    else if (strcmp(pt,"dynamic")) {                        \
      SCHEDULE = omp_sched_dynamic;                         \
    }                                                       \
    else if (strcmp(pt,"guided")) {                         \
      SCHEDULE = omp_sched_guided;                          \
    }                                                       \
    else if (strcmp(pt,"auto")) {                           \
      SCHEDULE = omp_sched_auto;                            \
    }                                                       \
    pt = strtok (NULL, ",");                                \
    if (pt != NULL) {                                       \
      CHUNK = atoi(pt);                                     \
    }                                                       \
    omp_set_schedule(SCHEDULE, CHUNK);                      ///< read and update with $ENV{OMP_SCHEDULE}

// ... add all of them from OpenMP::Environment, add unit tests

/* Output Init Macros (needed?) */
#define PerlOMP_RET_ARRAY_REF_ret AV* ret = newAV();sv_2mortal((SV*)ret);

/* Datatype Converters (doxygen style comments) */

/**
 * Converts a 1D Perl Array Reference (AV*) into a 1D C array of floats; allocates retArray[numElements] by reference
 * @param[in] *Aref, int numElements, float retArray[numElements] 
 * @param[out] void 
 */ 

void PerlOMP_1D_Array_TO_1D_FLOAT_ARRAY(SV *Aref, int numElements, float retArray[numElements]) {
  for (int i=0; i<numElements; i++) {
    SV **element = av_fetch((AV*)SvRV(Aref), i, 0);
    retArray[i] = SvNV(*element);
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

/* 1D Array reference to 1D int C array ...
 * Convert a regular M-element Perl array consisting of inting point values, e.g.,
 *
 *   my $Aref = [ 10, 314, 527, 911, 538 ];
 *
 * into a C array of the same dimensions so that it can be used as exepcted with an OpenMP
 * "#pragma omp for" work sharing construct
*/

void PerlOMP_1D_Array_TO_1D_INT_ARRAY(SV *Aref, int numElements, int retArray[numElements]) {
  for (int i=0; i<numElements; i++) {
    SV **element = av_fetch((AV*)SvRV(Aref), i, 0);
    retArray[i] = SvIV(*element);
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
  for (int i=0; i<numRows; i++) {
    AVref = av_fetch((AV*)SvRV(AoA), i, 0);
    for (int j=0; j<rowSize;j++) {
      SV **element = av_fetch((AV*)SvRV(*AVref), j, 0);
      retArray[i][j] = SvIV(*element);
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

OpenMP::Simple - Provides some DWIM helpers for using OpenMP via C<Inline::C>.

=head1 SYNOPSIS

    use OpenMP::Simple;
    use OpenMP::Environment;
    
    use Inline (
        C                 => 'DATA',
        with              => qw/OpenMP::Simple/,
    );

Note: while not C<experimental> per se, this module is still in a very fluid
state. It is actively being used as the basis for real world codes. As
more experience and intuition is gained by using it, this interface
will only improve. Feedback is very valuable, so please reach out to L<<
OODLER <oodler@cpan.org> >> or visit the I<Perl+OpenMP> Github repository,
L<https://github.com/Perl-OpenMP>.

=head1 DESCRIPTION AND DISCUSSION

Contained here is essentially a set of macros and C<Inline::C> defined C<C>
functions that make it easier for Perl programs to interface basic Perl
structures more directly with C<Inline::C> functions for use with OpenMP It
also containes macros that emulate the access of OpenMP programs to C<%ENV>
at program start up, and through this module, during runtime. Note: normal
OpenMP programs do not re-sample C<%ENV> during runtime, but C<OpenMP::Simple>
provides macros to do just that; so this module provides an additional
level of control that so that C<OpenMP::Environment> may be used effectively
during the running of a Perl program that contains C<Inline::C> functions
with OpenMP inside of them.

As a reminder, the OpenMP standard has several aspects that work in concert
to make shared memory programming (with SMP threads) more accessible. These
aspects may be summarized as the following:

=over 4

=item a runtime and library of functions that may be used to programatically
affect execution and work distribution; here is where this module,
L<OpenMP::Simple> makes a contribution to extending the promise of OpenMP
to Perl programmers.

=item a set of environmental variables (i.e., C<%ENV>) that can be used to
control the OpenMP runtime; this aspect is where the L<OpenMP::Environment>
module comes into play.

=item work sharing constructs used to implicitly share memory and executions
among a series of threads; these are implemented directly into the C<C> code,
and is also where most of the hard work for anyone (including Perl programmers)
exists. I.e., making OpenMP more I<perlish>. It also may including in the
future, using OpenMP I<inside> of the C<perl> interpreter itself; but this
is the domain of core Perl maintainers and experts in language semantics.
No attempt has been made so far to address this large and very fruitful area
of exploration.

=back

This module attempts to ease the transition for those more familiar with
programming C with OpenMP than they are with Perl or using C<Inline::C>
within their Perl programs. It build upon the configuration information that
is provided for by C<Alien::OpenMP>, and appends to the C<AUTO_INCLUDE>
literal lines of C code that defines useful macros and data conversion
functions (Perl to C, C to Perl).

In addition to helping to deal with getting data structures that are very
common in the computational domains into and out of these C<Inline::C>'d
routines that leverage I<OpenMP>, this module provides macros that are
designed to provide behavior that is assumed to work when executing a binary
that has been compiled with OpenMP support, such as the awareness of the
current state of the C<OMP_NUM_THREADS> environmental variable.

=head1 PROVIDED MACROS

=head2 Updating Runtime with Environmental Variables

When C<Inline::C> compiles and loads these shared libraries once, when the
script is first loaded. At this time, the OpenMP runtime inspects C<%ENV>;
but the environment is not automatically updated as whenever the runtime
interfaces to the compiled library is used. The following macros offer
a very concise and convenient way to update in the runtime based on the
values of the respective environmental variables. They are designed with the
use of C<OpenMP::Environment> in mind, which provides an OpenMP specific
OOP interface to getting and setting these variables. Nearly all of them
correspond to a way to C<set> them in the OpenMP runtime (provided by the
compiler's implementation, e.g., C<omp.h>).

All MACROS have at least 1 test. Please those in the Github repository to get
an idea of how to use C<OpenMP::Simple>'s macros with C<OpenMP::Environment>.

=over 4

=item C<PerlOMP_UPDATE_WITH_ENV__NUM_THREADS>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_NUM_THREADS}>, which is managed via C<<
OpenMP::Environment->omp_num_threads[int numThreads]); >>.

=item C<PerlOMP_UPDATE_WITH_ENV__DEFAULT_DEVICE>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_DEFAULT_DEVICE}>, which is managed via C<<
OpenMP::Environment->omp_default_device([int deviceNo]); >>.

=item C<PerlOMP_UPDATE_WITH_ENV__MAX_ACTIVE_LEVELS>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_MAX_ACTIVE_LEVELS}>, which is managed via C<<
OpenMP::Environment->omp_max_active_levels([int maxLevel]); >>.

=item C<PerlOMP_UPDATE_WITH_ENV__DYNAMIC>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_DYNAMIC}>, which is managed via C<<
OpenMP::Environment->omp_dynamic(['true'|'false']); >>.

=item C<PerlOMP_UPDATE_WITH_ENV__NESTED>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_NESTED}>, which is managed via C<<
OpenMP::Environment->omp_nested(['true'|'false']); >>.

=item C<PerlOMP_UPDATE_WITH_ENV__SCHEDULE>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_SCHEDULE}>, which is managed via C<<
OpenMP::Environment->omp_schedule(...); >>.

Note: The schedule syntax is of the form I<schedule[;chunkSize]>.

=item C<PerlOMP_UPDATE_WITH_ENV__TEAMS_THREAD_LIMIT>

Updates the OpenMP runtime with the value of the environmental
variable, C<$ENV{OMP_TEAMS_THREAD_LIMIT}>, which is managed via C<<
OpenMP::Environment->omp_([int limit]); >>.

Note: Not supported until GCC 12.3.0

=item C<PerlOMP_UPDATE_WITH_ENV__NUM_TEAMS>

Updates the OpenMP runtime with the value of the environmental variable,
C<$ENV{OMP_NUM_TEAMS}>, which is managed via C<< OpenMP::Environment->omp_([int
num]); >>.

Note: Not supported until GCC 12.3.0

=item C<PerlOMP_RET_ARRAY_REF_ret>

(may not be needed) - creates a new C<AV*> and sets it I<mortal> (doesn't
survive outside of the current scope). Used when wanting to return an array
reference that's been populated via C<av_push>.

=back

=head1 PROVIDED PERL TO C CONVERSION FUNCTIONS

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
implementations.

L<https://gcc.gnu.org/onlinedocs/libgomp/index.html>

Please also see the C<rperl> project for a glimpse into the potential future
of Perl+OpenMP, particularly in regards to thread-safe data structures.

L<https://www.rperl.org>

=head1 AUTHOR

Oodler 577 L<< <oodler@cpan.org> >>

=head1 LICENSE & COPYRIGHT

Same as Perl.
