#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'Mojolicious::Command::replget';
  require_ok 'Mojolicious::Command::replget';
}

done_testing;
