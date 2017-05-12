#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

for (qw(
  MooX::POE
)) {
  use_ok($_);
}

done_testing;

