package Test::Classy::Test::OSTest::NotWin;

use strict;
use warnings;
use Test::Classy::Base;

sub initialize {
  my $class = shift;

  if ( $^O eq 'MSWin32' ) {
    $class->skip_the_rest('This test is not for Win')
  }
}

sub not_for_win : Test {
  my $class = shift;
  pass $class->message;
}

1;
