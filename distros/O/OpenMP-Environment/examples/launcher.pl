#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib qq{$Bin/../lib};

use OpenMP::Environment ();

my $env = OpenMP::Environment->new;

for my $i ( qw/1 2 4 8 16 32 64 128/ ) { 
  $env->omp_num_threads($i);
  $env->print_omp_summary_set;

  #<< add `system` call to OpenMP compiled executable >>
  # e.g.,
  # my $exit_code = system(qw{/path/to/my_prog_r --opt1 x --opt2 y});
  #
  # if ($exit_code == 0) {
  #   # ... do some post processing
  # }
  # else {
  #   # ... handle failed execution
  # }
}

exit;
