#!/usr/bin/env perl

use strict;
use warnings;

use OpenMP::Environment ();

my $oenv = OpenMP::Environment->new;

# go there
chdir q{./NPB3.4.1/NPB3.4-OMP};

# build 'DC' (purely C)
my $exit_error = system(qw/make dc/);

if ( $exit_error != 0 ) {
    print qq{Error making benchmark\n};
    exit $exit_error;
}

NEXT_NUM_THREADS:
for my $num_threads (qw/1 2 3 4/) {
    $oenv->omp_num_threads($num_threads);
    $exit_error = system(qw{./bin/dc.W.x});

    if ( $exit_error != 0 ) {
        print qq{Error making du\n};
        exit $exit_error;
    }

    # clean up
    unlink glob q{ADC*};
}
