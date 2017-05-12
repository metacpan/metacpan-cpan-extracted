#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;
use lib 't/lib';

do {
    package Foo;
    use Moose;
    use MyAttrs (
        has_str => {
            -as => 'has_string',
        },
    );

    has_string 'name';
};

is(Foo->meta->get_attribute('name')->type_constraint, 'Str');

