#!/usr/bin/env perl

use lib './lib';
use lib './t';
use Test::More;

if ($] < 5.020) {
  plan(skip_all =>  "Perl version < 5.020");
}
else {
  plan(tests => 4);
  use_ok 'Pony::Object';
  require 'Purple/Object.pm';

  package main {
    my $summer = new Purple::Object;
    ok($summer->sum(1, 2) == 3, "Test easy sum method");
    ok($summer->sum(1) == 1, "Test default sum method");
    ok($summer->sum_it(1) == 1, "Test array sum method");
  }
}
