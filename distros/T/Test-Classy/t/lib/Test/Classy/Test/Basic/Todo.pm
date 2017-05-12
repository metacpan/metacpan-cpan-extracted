package Test::Classy::Test::Basic::Todo;

use strict;
use warnings;
use Test::Classy::Base;

sub todo_1 : Test TODO {
  my $class = shift;

  fail $class->message("but this is a todo test: 1-1");
}

sub todo_2 : Test(2) TODO {
  my $class = shift;

  fail $class->message("but this is a todo test: 2-1");
  fail $class->message("but this is a todo test: 2-2");
}

sub todo_3 : Tests(3) TODO(skipped by attribute) {
  my $class = shift;

  fail $class->message("but this is a todo test: 3-1");
  fail $class->message("but this is a todo test: 3-2");
  fail $class->message("but this is a todo test: 3-3");
}

sub todo_4 : Tests(3) TODO Skip {
  my $class = shift;

  fail $class->message("but this is a todo test: 4-1");
  fail $class->message("but this is a todo test: 4-2");
  fail $class->message("but this is a todo test: 4-3");
  fail $class->message("but this is a todo test: 4-4");
}

sub todo_5_partly : Tests(3) {
  my $class = shift;

  pass $class->message("this should pass");

  TODO: {
    local $TODO = $class->message('this is not implemented');
    fail $class->message("this is a todo test");
  }

  pass $class->message("this should pass, too");
}

1;
