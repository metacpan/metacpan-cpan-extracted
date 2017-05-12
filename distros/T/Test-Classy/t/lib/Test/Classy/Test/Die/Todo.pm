package Test::Classy::Test::Die::Todo;

use strict;
use warnings;
use Test::Classy::Base;

sub die_in_a_test : Test TODO(this test will die) {
  my $class = shift;

  die "actually died";
  ok 1;
}

sub die_in_tests : Tests(2) TODO(this test will die) {
  my $class = shift;

  die "actually died";
  ok 1;
  ok 2;
}

sub die_in_the_middle_of_tests : Tests(2) TODO(this test will die) {
  my $class = shift;

  ok 1;
  die "actually died";
  ok 2;
}

1;
