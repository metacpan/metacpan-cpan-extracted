package Test::Classy::Test::NoPlan::NoPlan;

use strict;
use warnings;
use Test::Classy::Base;

sub test : Test(no_plan) {
  my $class = shift;

  pass $class->message('no plan');
}

sub test2 : Test('no_plan') {
  my $class = shift;

  pass $class->message('no plan with single quotes');
}

sub test3 : Test("no_plan") {
  my $class = shift;

  pass $class->message('no plan with double quotes');
}

# followings should not be parsed as tests

sub test4 : Test("no_plan') {
  my $class = shift;

  fail $class->message('quotes mismatch');
}

sub test5 : Test(no_plan') {
  my $class = shift;

  fail $class->message('quotes mismatch');
}

sub test6 : Test(no_plan") {
  my $class = shift;

  fail $class->message('quotes mismatch');
}

sub test7 : Test(noplan) {
  my $class = shift;

  fail $class->message('bad plan name');
}

1;
