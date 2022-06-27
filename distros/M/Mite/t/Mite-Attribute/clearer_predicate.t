#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;

use Mite::Attribute;

after_case "Create a class to test with" => sub {
    package Foo;

    sub new {
        my $class = shift;
        bless { @_ }, $class
    }

    eval Mite::Attribute->new(
        name      => 'foo',
        accessor  => 1,
        clearer   => 1,
        predicate => 1,
    )->compile;
};

tests "Basic predicate and clearer" => sub {
    my $obj = new_ok 'Foo';
    ok !$obj->has_foo;

    $obj->foo(23);
    ok $obj->has_foo;

    $obj->foo(undef);
    ok $obj->has_foo;

    $obj->foo(0);
    ok $obj->has_foo;

    $obj->foo('');
    ok $obj->has_foo;

    $obj->clear_foo;
    ok !$obj->has_foo;

    $obj->foo(undef);
    ok $obj->has_foo;
};

done_testing;
