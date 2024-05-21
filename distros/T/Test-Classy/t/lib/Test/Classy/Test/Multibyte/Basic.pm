package Test::Classy::Test::Multibyte::Basic;

use strict;
use warnings;
use Test::Classy::Base;
use utf8;

sub 日本語 : Test {
  my $class = shift;

  pass($class->message('日本語のメッセージ'));
}

1;
