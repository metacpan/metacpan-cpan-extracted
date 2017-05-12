#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

sub num_tests {
  return scalar(Test::Builder->new->details);
}

is num_tests(), 0, 'no tests yet';
is num_tests(), 1, 'that check created a test';

SKIP: {
    skip "it's my party and i'll skip if i want to", 1;
    ok 1;
}

is num_tests(), 3, 'skip adds a detail';
