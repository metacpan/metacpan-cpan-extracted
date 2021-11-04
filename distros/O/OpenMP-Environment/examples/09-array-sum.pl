#!/usr/bin/env perl

use strict;
use warnings;
use Alien::OpenMP;
use OpenMP::Environment ();
use Getopt::Long qw/GetOptionsFromArray/;
use Util::H2O qw/h2o/;

=pod
First example of a C function that uses the OpenMP C<reduction>
capability to add up a 1D array of numbers, using threads operating
over shared memory.

=over 4

=item function interface accepts an array reference

=item OpenMP addition is accomplished using C<reduction> by addition, C<+>

=item value is return back as a scalar IV Perl data structure

=back
=cut

# build and load subroutines
use Inline (
    C           => 'DATA',
    with        => qw/Alien::OpenMP/,
    BUILD_NOISY => 1,
);

# init options
my $o = { threads => q{1,2,4,8,16}, };

my $ret = GetOptionsFromArray( \@ARGV, $o, qw/threads=s/ );
h2o $o;

my $oenv = OpenMP::Environment->new;
my @arr  = ( 1 .. 1_000 );
for my $num_threads ( split / *, */, $o->threads ) {
    $oenv->omp_num_threads($num_threads);
    my $sum = sum( \@arr );
    print qq{$sum\n};
}

exit;

__DATA__

__C__
# include <stdlib.h>
# include <stdio.h>
# include <omp.h>

/* added for integration for use with OpenMP::Environment */
int _ENV_set_num_threads() {
  char *num;
  num = getenv("OMP_NUM_THREADS");
  omp_set_num_threads(atoi(num));
  return atoi(num);
}

SV *sum(SV *array) {
    int numelts, i;
    /* update OMP_NUM_THREADS from %ENV */
    int numthreads = _ENV_set_num_threads();
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
