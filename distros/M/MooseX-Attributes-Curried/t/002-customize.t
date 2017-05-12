#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;
use lib 't/lib';

do {
    package Foo;
    use Moose;
    use MyAttrs (
        has_str => {
            default => 'hi',
        },
    );

    has_str 'name';
};

is(Foo->meta->get_attribute('name')->type_constraint, 'Str');
is(Foo->meta->get_attribute('name')->default, 'hi');

