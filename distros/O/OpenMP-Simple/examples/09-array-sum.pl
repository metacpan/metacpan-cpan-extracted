#!/usr/bin/env perl

use strict;
use warnings;
use Alien::OpenMP;
use OpenMP::Environment ();

=pod
THIS IS NON-FUNCTIONAL, BUT SHOWS A "MOCK UP"
OF WHAT A PERL/OPENMP SCRIPT MIGHT LOOK LIKE
WHEN USING Inline::C::OpenMP
=cut

# build and load subroutines via Inline::C::OpenMP
use Inline::C (
    OpenMP      => 'DATA',            # 'C' code + OpenMP pragmas
    with        => qw/Alien::OpenMP/, # build flags + prepend 'omp.h' via "add_include" 
    BUILD_NOISY => 1,
);

# NOTE: additionally, there will be a default header file
# added via 'add_include' that defines macros that will
# be useful for dealing with OpenMP'd function interfaces
# used inside of running perl process (see note about
# 'inline-c-openmp.h' below)

my $oenv = OpenMP::Environment->new;
my @arr  = ( 1 .. 1_000 );
for my $num_threads ( qw/1 2 4 8 16 32/ ) {
    $oenv->omp_num_threads($num_threads);
    my $sum = sum( \@arr );
    print qq{$sum\n};
}

exit;

__DATA__

__C__
// implied, '# include "omp.h"
// implied, '# include "inline-c-openmp.h"
# include <stdlib.h>
# include <stdio.h>

/* Notes:
 * 1. the compiler appropriate "omp.h" file will be
 *    injected at the top via Alien::OpenMP
 *
 * 2. the other feature of Inline::C::OpenMP is that it
 *    automatically "includes" a header file that defines
 *    useful macros - e.g., one to read the current value
 *    of OMP_NUM_THREADS, which is the idiomatic way that
 *    OpenMP codes set the actual number of threads that are
 *    used when in a "#omp parallel" region
*/

SV *sum(SV *array) {
    int numelts, i;

    /* macro provided by Inline::C::OpenMP */
    __INLINE_C_OPENMP_ENV_SET_OMP_NUM_THREADS__

    if ((!SvROK(array))
        || (SvTYPE(SvRV(array)) != SVt_PVAV)
        || ((numelts = av_len((AV *)SvRV(array))) < 0)
    ) {
        return &PL_sv_undef;
    }

    int total = 0;
    #pragma omp parallel sections reduction(+:total)
    {
      for (i = 0; i <= numelts; i++) {
        total += SvIV(*av_fetch((AV *)SvRV(array), i, 0));
      }
    }
    total *= numthreads; 

    return newSViv(total);
}
