package Test::Classy::Test::Basic::Plain;

use strict;
use warnings;
use Test::Classy::Base;

sub plain_1 : Test {
  my $class = shift;
  pass $class->message("first test");
}

sub plain_2 : Tests(2) {
  my $class = shift;
  pass $class->message("second test");
  pass $class->message("third test");
}

sub plain_3 : Tests(3) {
  my $class = shift;
  pass $class->message("fourth test");
  pass $class->message("fifth test");
  pass $class->message("sixth test");
}

1;
