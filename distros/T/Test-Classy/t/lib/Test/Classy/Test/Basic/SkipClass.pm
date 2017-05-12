package Test::Classy::Test::Basic::SkipClass;

use strict;
use warnings;
use Test::Classy::Base;

sub initialize {
  my $class = shift;

  $class->skip_this_class('all tests in this class should be skipped');
}

sub failing_test : Test {
  my $class = shift;

  fail $class->message("but this is to be skipped");
}

1;
