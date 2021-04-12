#!/usr/bin/env perl

use strict;
use warnings;

use OpenMP::Environment ();
use constant USE_DEFAULT => 0;

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

This example uses OpenMP::Environment, but shows that it works
with two caveats:

=over 4

=item It must be called in a C<BEGIN> block that contains the
invocation of C<Inline::C>

=item It as only this single opportunity to effect the variables
that it sets

=back

=cut

BEGIN {
    my $oenv = OpenMP::Environment->new;
    $oenv->omp_num_threads(16);     # serve as "default" (actual standard default is 4)
    $oenv->omp_thread_limit(32);    # demonstrate setting of the max number of threads

    # build and load subroutines
    use Inline (
        C           => 'DATA',
        name        => q{Test},
        ccflagsex   => q{-fopenmp},
        lddlflags   => join( q{ }, $Config::Config{lddlflags}, q{-fopenmp} ),
        BUILD_NOISY => 1,
    );
}

# use default
test(USE_DEFAULT);

for my $num_threads (qw/1 2 4 8 16 32 64 128 256/) {
    test($num_threads);
}

exit;

__DATA__

__C__
#include <omp.h>
#include <stdio.h>
void test(int num_threads) {

  // invoke default set at library load time if a number less than 1 is provided
  if (num_threads > 0)
    omp_set_num_threads(num_threads);

  #pragma omp parallel
  {
    if (0 == omp_get_thread_num())
      printf("wanted '%d', got '%d' (max number is %d)\n", num_threads, omp_get_num_threads(), omp_get_thread_limit()); 
  }
}
