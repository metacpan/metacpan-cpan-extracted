#!/usr/bin/env perl

use strict;
use warnings;
use OpenMP::Environment ();

=pod
The following is an example of emulating the familiar behavior
of compiled OpenMP programs that respect a number of environmental
variables at run time. The key difference between running a compiled
OpenMP program at the commandline and a compiled subroutine in Perl
that utilizes OpenMP, is that subsequent calls to the subroutine in
the Perl script do not have an opportunity to relead the binary or
shared library.

The "user experience" of one running an OpenMP program from the shell
is that it the number of threads used in the program may be set implicitly
using the OMP_NUM_THREADS environmental variable. Therefore, one may
run the binary in a shell loop and update C<OMP_NUM_THREADS> environmentally.

OpenMP benchmarks are often written in this fashion. It is possible
to affect the number of threads in the binary, but only through the
use of run time methods. In the case of C<OMP_NUM_THREADS>, this function
is C<omp_set_num_threads>. The issue here is that using run time setters
breaks the veil that is so attractive about OpenMP; the pragmas offer
a way to implicitly define OpenMP threads *if* the compiler can recognize
them; if it can't, the pragmas are designed to appear as normal comments.

Using run time functions is an explicit act, and therefore can't be
hidden in the same manner. This requires the compiler to link against
OpenMP run time libraries, even if there is no intention to run in
parallel. There are 2 options here - hide the run time call from the
compiler using C<ifdef> or the like; or link the OpenMP library and
just ensure C<OMP_NUM_THREADS> is set to C<1> (as in a single thread).

Using C<OpenMP::Environment> introduces the consideration that the compiled
subroutine is loaded only once when the Perl script is executed. It
is true that in this situation, the environment is read in as expected -
but, it is only considered I<once> and at library I<load> time.

To get away from this restriction and emulate more closely the C<user
experience> of the commandline with respect to OpenMP environmental
variable controls, we present the following example to show how to
C<re-read> certain environmental variables.

Interestingly, there are only 6 run time I<setters> that correspond
to OpenMP environmental variables to work with:

=over 4
=item C<omp_set_num_threads>

By far the most commonly used environmental variable; this run time
I<setter> corresponds to C<OMP_NUM_THREADS>. The example below illustrates
a basic case of re-reading this variable, but the general principle
can be applied to any of the following variables.

=item C<omp_set_default_device>

Corresponds to C<OMP_DEFAULT_DEVICE>

=item C<omp_set_dynamic>

Corresponds to C<OMP_DYNAMIC>.

=item C<omp_set_max_active_levels>

Corresponds to C<OMP_MAX_ACTIVE_LEVELS>

=item C<omp_set_nested>

Corresponds to C<OMP_NESTED>

=item C<omp_set_schedule>

Corresponds to C<OMP_SCHEDULE>.

=back 

B<Note:> The other environmental variables presented in this module
do not have run time I<setters>. Dealing with tese dynamically
presents some additional hurdles and considerations; this will be
addressed outside of this example.

=cut

# build and load subroutines
use Inline (
    C           => 'DATA',
    name        => q{Test},
    ccflagsex   => q{-fopenmp},
    lddlflags   => join( q{ }, $Config::Config{lddlflags}, q{-fopenmp} ),
    BUILD_NOISY => 1,
);

my $oenv = OpenMP::Environment->new;
for my $num_threads (qw/1 2 4 8 16 24/) {
    $oenv->omp_num_threads($num_threads);
    test();
}

exit;

__DATA__

__C__
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>

void test() {
  _ENV_set_num_threads();
  #pragma omp parallel
  {
    if (0 == omp_get_thread_num())
      printf("%-2d threads\n", omp_get_num_threads()); 
  }
}

void _ENV_set_num_threads() {
  char *num;
  num = getenv("OMP_NUM_THREADS");
  omp_set_num_threads(atoi(num));
}
