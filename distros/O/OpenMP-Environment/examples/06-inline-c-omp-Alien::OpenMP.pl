#!/usr/bin/env perl

use strict;
use warnings;
use Alien::OpenMP;
use OpenMP::Environment ();

=pod
Note: OpenMP::Environment has no effect on Perl interfaces
that utilize compiled code as shared objects, that also
contain OpenMP constructs.

The reason for this is that OpenMP implemented by compilers,
gcc (gomp), anyway, only read in the environment once. In our
use of Inline::C, this corresponds to the actual loading of
the .so that is linked to the XS-based Perl interface it
presents.  As a result, a developer must use the OpenMP API
that is exposed. In the example below, we're using the
C<omp_set_num_threads> rather than setting C<OMP_NUM_THREADS>
via %ENV or using OpenMP::Environment's C<omp_num_threads>
method.

This example doesn't use OpenMP::Environment, but it's
to demonstrate an example of passing the number of threads
in as a parameter to the compiled functions.
=cut

# build and load subroutines
use Inline (
    C           => 'DATA',
    ccflagsex   => Alien::OpenMP::cflags(),
    lddlflags   => join( q{ }, $Config::Config{lddlflags}, Alien::OpenMP::lddlflags() ),
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
