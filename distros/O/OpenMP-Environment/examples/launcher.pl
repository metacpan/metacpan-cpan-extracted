#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib qq{$Bin/../lib};

use OpenMP::Environment ();

=pod
This example runs an standalone executable. Though one is not
provided, the basic example with C<gcc> is:

    gcc -fopenmp omp-example.c -o omp-example.x

You may then invoke this script like,

    examples/launcher.pl ./omp-example.x 

The C<OpenMP::Environment> module is highly effective when used
with externally compiled executables. Unlike is the case with
the examples provided that use C<Inline::C> to compile XS-based
Perl interfaces that can be used directly in Perl scripts; the
enviroment is an effective means of controlling the execution
parameters of the program. Therefore, the C<OpenMP::Environment>
is largely targed towards creating scripts and utilities that run
executables that utlize OpenMP.

An approach like this is useful for production HPC environments,
when running on large compute nodes. It's also useful as a basis
for running OpenMP-based benchmarks or test suites.
=cut

# initialize
my $oenv = OpenMP::Environment->new;

for my $i (qw/1 2 4 8 16 32 64 128/) {
    $oenv->omp_num_threads($i);

    #<< add `system` call to OpenMP compiled executable >>
    # e.g.,
    my $exit_code = system( $ARGV[0] );
    #
    if ( $exit_code == 0 ) {
        print qq{OK - now do stuff after a successful execution\n};
    }
    else {
        print qq{Oof - something went wrong.\n};
        exit $exit_code;
    }
}

exit;
