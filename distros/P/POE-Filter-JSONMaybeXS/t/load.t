#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  POE::Filter::JSONMaybeXS
)) {
  use_ok($_);
}

done_testing;

