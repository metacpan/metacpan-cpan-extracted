#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  Parse::BBCode::SCEditor
)) {
  use_ok($_);
}

done_testing;

