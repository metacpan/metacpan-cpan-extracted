package Coding::Error;

use strict;
use warnings;

use Applify;

sub some_method {
  return 'something';
}

app {
  my $self = shift;
  warn "[Coding::Error] test should not display this\n";
  warn "[Coding::Error] ", $self->some_method, "\n";
  return 0;
};

1;
