package Test::Classy::Test::Inherit::Base;

use strict;
use warnings;
use Carp;
use Test::Classy::Base 'ignore';

sub data { croak "should override this" };

sub test : Test {
  my ($class, @args) = @_;

  pass $class->message("tested ".$class->data); # should be ignored here
}

1;
