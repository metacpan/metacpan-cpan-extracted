#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

pass;
# idea from Test::Harness, thanks!
diag(
  "Perl $], ",
  "$^X on $^O"
);
