#!/usr/bin/env perl

use strict;
use warnings;

use t::Correctness::DependencyGraphIsNotATree;

t::PBS::set_global_warp_mode('off');

my $num_runs = 2;

my $num_tests_per_run = t::Correctness::DependencyGraphIsNotATree->expected_tests();
my $extra_tests = ($num_runs - 1) * $num_tests_per_run;

t::Correctness::DependencyGraphIsNotATree->runtests($extra_tests);

for (my $i = 1; $i < $num_runs; ++$i) {
    t::Correctness::DependencyGraphIsNotATree->runtests();
}
