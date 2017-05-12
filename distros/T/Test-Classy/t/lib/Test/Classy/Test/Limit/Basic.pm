package Test::Classy::Test::Limit::Basic;

use strict;
use warnings;
use Test::Classy::Base;

sub limit_test : Test Target {
  my $class = shift;

  pass $class->message('this test will be executed');
}

sub not_targeted : Test {
  my $class = shift;

  fail $class->message('this test should be skipped');
}

1;
