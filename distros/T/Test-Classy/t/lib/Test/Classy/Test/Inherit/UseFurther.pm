package Test::Classy::Test::Inherit::UseFurther;

use strict;
use warnings;
use Test::Classy::Test::Inherit::Use 'base';

sub data { 'use_further' };

sub further_test : Test {
  my $class = shift;

  pass $class->message("further test");
}

1;
