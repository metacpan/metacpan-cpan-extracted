package Test::Classy::Test::OSTest::Win;

use strict;
use warnings;
use Test::Classy::Base;

sub initialize {
  my $class = shift;

  unless ( $^O eq 'MSWin32' ) {
    $class->skip_the_rest('This test is only for Win')
  }
}

sub win_only : Test {
  my $class = shift;
  pass $class->message;
}

1;
