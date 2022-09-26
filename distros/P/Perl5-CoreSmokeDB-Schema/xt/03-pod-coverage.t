#! perl -I. -w
use t::Test::abeltje;

use Test::Pod::Coverage;

Test::Warnings->import(':no_end_test');

my @ignore_words = sort {
    length($b) <=> length($a) ||
    $a cmp $b
} map {chomp($_); $_} <DATA>;

all_pod_coverage_ok({ trustme => \@ignore_words });

__DATA__
arch_os_version_key
arch_os_version_label
arch_os_version_pair
average_in_hhmm
c_compiler_key
c_compiler_label
c_compiler_pair
c_compilers
duration_in_hhmm
full_arguments
group_tests_by_status
list_title
matrix
matrix_legend
test_env
test_failures
test_todo_passed
time_in_hhmm
title
