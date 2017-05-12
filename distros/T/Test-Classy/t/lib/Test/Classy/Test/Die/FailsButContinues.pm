package Test::Classy::Test::Die::FailsButContinues;

use strict;
use warnings;
use Test::Classy::Base;

sub initialize {
  my $class = shift;

  unless ( $ENV{TEST_CLASSY_DIE_TEST} ) {
    $class->skip_this_class("this test is for the author only")
  }
}

sub die_in_a_test : Test {
  my $class = shift;

  die "actually died";
  ok 1;
}

sub die_in_tests : Tests(2) {
  my $class = shift;

  die "actually died";
  ok 1;
  ok 2;
}

sub die_in_the_middle_of_tests : Tests(2) {
  my $class = shift;

  ok 1;
  die "actually died";
  ok 2;
}

1;
