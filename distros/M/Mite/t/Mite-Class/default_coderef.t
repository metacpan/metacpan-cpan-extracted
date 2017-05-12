#!/usr/bin/perl

use lib 't/lib';
use Test::Mite with_recommends => 1;

after_case "Setup class" => sub {
    mite_load(<<'CODE');
package Foo;
use Mite::Shim;

# For lexical environment test
use strict;
use warnings;
use feature ':5.10';

has number =>
  is            => 'rw',
  default       => sub { 23 };

has list =>
  is            => 'rw',
  default       => sub { [] };

my $thing = { foo => 99 };
has closure =>
  is            => 'rw',
  default       => sub { $thing };

has counter =>
  is            => 'rw',
  default       => sub {
      state $counter = 0;
      $counter++;
      return $counter;
  };

1;
CODE

};

tests simple_defaults => sub {
    my $obj = new_ok "Foo";
    is $obj->number, 23;
};

tests override_default => sub {
    my $obj = new_ok "Foo", [ number => 42 ];
    is $obj->number, 42;
};

tests reference_defaults => sub {
    my $obj1 = new_ok "Foo";
    my $obj2 = new_ok "Foo";

    is_deeply $obj1->list, [];
    is_deeply $obj2->list, [];

    $obj1->list->[0] = 23;
    ok !$obj2->list->[0], "references are copies";
};

tests closures => sub {
    my $obj = new_ok "Foo";

    is_deeply $obj->closure, { foo => 99 };
};

tests "Preserving lexical environment" => sub {
    my $obj1 = new_ok "Foo";

    my $count = $obj1->counter;

    my $obj2 = new_ok "Foo";
    is $obj2->counter, $count + 1;
};

done_testing;
