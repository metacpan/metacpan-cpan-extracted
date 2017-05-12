use strict;
use warnings;
use Test::More tests => 2;

use ok 'MooseX::Runnable::Fuse';

{ package Class;
  use Moose;
  with 'MooseX::Runnable::Fuse';
}

can_ok 'Class', 'run';
