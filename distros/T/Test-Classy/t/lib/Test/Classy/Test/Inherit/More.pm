package Test::Classy::Test::Inherit::More;

use strict;
use warnings;
use base qw( Test::Classy::Test::Inherit::UseBase );
use Test::More; # require this as "use base" doesn't import things

sub data { 'more' };

sub more_test : Test {
  my $class = shift;
  pass $class->message("yet another test");
}

1;
