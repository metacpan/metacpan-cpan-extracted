#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'Mojolicious::Command::generate::controller';
  require_ok 'Mojolicious::Command::generate::controller';
}

done_testing;
