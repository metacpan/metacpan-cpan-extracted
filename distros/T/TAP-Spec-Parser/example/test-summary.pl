#!/usr/bin/perl
#
use strict;
use warnings;

use TAP::Spec::Parser;
use Data::Dumper;

my $testset = TAP::Spec::Parser->parse_from_handle(\*ARGV);

my $planned = $testset->plan->number_of_tests;

my ($tests, $passed, $failed, $skipped, $passed_todo) = (0,0,0,0,0);

for my $test ($testset->tests) {
  ++ $tests;
  if ($test->passed) {
    ++ $passed;
  } else {
    ++ $failed;
  }

  if ($test->has_directive and $test->directive eq 'TODO' and $test->status eq 'ok') {
    ++ $passed_todo;
  }

  if ($test->has_directive and $test->directive eq 'SKIP') {
    ++ $skipped;
  }
}

print "Failed $failed/$tests tests (planned $planned), skipped $skipped.\n";
print "Unexpectedly passed $passed_todo TODO tests.\n" if $passed_todo;
print "Result: ", $testset->passed ? "PASS" : "FAIL", "\n";
