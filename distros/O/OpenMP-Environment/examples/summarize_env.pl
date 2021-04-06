#!/usr/bin/omp perl

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib qq{$Bin/../lib};

use OpenMP::Environment ();

my $env = OpenMP::Environment->new;

# print report to STDOUT of what's set
$env->print_omp_summary_set;

print qq{\n};

# print report to STDOUT of what's NOT set
$env->print_omp_summary_unset;

print qq{\n};

# print full report
$env->print_omp_summary;

exit;
