#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;

use Mite::Attribute;

tests "Simple test" => sub {
    mite_load <<'CODE';
package Foo;
use Mite::Shim;
has num =>
  lazy => 1,
  isa => 'Int',
  reader => 1,
  writer => 1,
  accessor => 1,
  clearer => 1,
  predicate => 1,
  builder => sub { 99 };
1;
CODE

    my $obj = Foo->new;
    ok !$obj->has_num;

    is $obj->get_num, 99;
    ok $obj->has_num;
    $obj->clear_num;
    ok !$obj->has_num;

    is $obj->num, 99;
    ok $obj->has_num;
    $obj->clear_num;
    ok !$obj->has_num;

    $obj->num(24);
    ok $obj->has_num;
    is $obj->get_num, 24;
    is $obj->num, 24;
    $obj->clear_num;
    ok !$obj->has_num;
};

tests "Lazy default which fails type check" => sub {
    mite_load <<'CODE';
package Bar;
use Mite::Shim;
has num =>
  lazy => 1,
  isa => 'Int',
  reader => 1,
  writer => 1,
  accessor => 1,
  clearer => 1,
  predicate => 1,
  builder => sub { 9.5 };
1;
CODE

    my $obj = Bar->new;
    local $@;
    eval { $obj->num; 1 };
    my $e = $@;
    like $e, qr/Type check failed in default/;
};

done_testing;
