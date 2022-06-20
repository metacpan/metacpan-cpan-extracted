#!/usr/bin/env perl

use lib 't/lib';
use MooseX::Extended::Tests;

package Local::MyClass {
    use MooseX::Extended;
    field foo => ( init_arg => '_foo', builder => 1 );

    sub _build_foo {
        return "quux";
    }
}

is(
    Local::MyClass->new->foo,
    'quux',
    'field with default',
);

is(
    Local::MyClass->new( _foo => 'quuux' )->foo,
    'quuux',
    'field initialized in constructor (init_arg => _foo)',
);

done_testing;
