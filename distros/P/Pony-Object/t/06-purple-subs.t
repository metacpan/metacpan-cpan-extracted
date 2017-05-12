#!/usr/bin/env perl

use lib './lib';
use lib './t';
use Test::More tests => 4;

SKIP: {
  skip "Perl version < 5.020", 4 if $] < 5.020;
  use_ok 'Pony::Object';

  package Purple::Class {
    use Pony::Object;
    
    sub sum($self, $a, $b = 0) {
      return $a + $b;
    }
    
    sub sum_it($self, @args) {
      return $self->sum(@args);
    }
  }

  package main {
    my $summer = new Purple::Class;
    ok($summer->sum(1, 2) == 3, "Test easy sum method");
    ok($summer->sum(1) == 1, "Test default sum method");
    ok($summer->sum_it(1) == 1, "Test array sum method");
  }
}

