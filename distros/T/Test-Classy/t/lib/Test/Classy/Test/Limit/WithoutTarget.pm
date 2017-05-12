package Test::Classy::Test::Limit::WithoutTarget;

use strict;
use warnings;
use Test::Classy::Base;

sub not_targeted_at_all : Test {
  my $class = shift;

  fail $class->message('this test should be skipped');
}

1;
