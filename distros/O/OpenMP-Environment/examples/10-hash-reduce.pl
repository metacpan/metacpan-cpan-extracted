#!/usr/bin/env perl

use strict;
use warnings;
use Alien::OpenMP;
use OpenMP::Environment ();
use Getopt::Long qw/GetOptionsFromArray/;
use Util::H2O qw/h2o/;

# build and load subroutines
use Inline (
    C            => 'DATA',
    with         => qw/Alien::OpenMP/,
    auto_include => q{#include "omp.h"}, #<~ will move this to Alien::OpenMP
);

# init options
my $o = { threads => q{1,2,4,8,16}, };

my $ret = GetOptionsFromArray( \@ARGV, $o, qw/threads=s/ );
h2o $o;

my $oenv = OpenMP::Environment->new;

my %hash = ();
foreach my $i (0 .. 1_000) {
  $hash{$i} = $i;
}

for my $num_threads ( split / *, */, $o->threads ) {
    $oenv->omp_num_threads($num_threads);
    my $sum = sum( \%hash );
    print qq{$sum\n};
}

exit;

__DATA__

__C__
# include <stdlib.h>
# include <stdio.h>

/* added for integration for use with OpenMP::Environment */
int _ENV_set_num_threads() {
  char *num;
  num = getenv("OMP_NUM_THREADS");
  omp_set_num_threads(atoi(num));
  return atoi(num);
}

/* minor modificatin of example in Inline::C::Cookbook */

SV *sum(SV *hash_ref ) {
  HV* hash;
  HE* hash_entry;
  int num_keys, i;
  SV* sv_key;
  SV* sv_val;
 
  if (! SvROK(hash_ref))
    croak("hash_ref is not a reference");

  /* update and get OMP_NUM_THREADS */
  int numthreads = _ENV_set_num_threads();
 
  hash = (HV*)SvRV(hash_ref);
  num_keys = hv_iterinit(hash);
    int total = 0;
    #pragma omp parallel sections reduction(+:total)
    {
      for (i = 0; i < num_keys; i++) {
        hash_entry = hv_iternext(hash);
        sv_key = hv_iterkeysv(hash_entry);
        sv_val = hv_iterval(hash, hash_entry);
        total += SvIV(sv_val);
      }
    }

    total *= numthreads; 

    return newSViv(total);
}
