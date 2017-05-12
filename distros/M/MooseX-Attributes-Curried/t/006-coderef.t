#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;
use lib 't/lib';

do {
    package Foo;
    use Moose;
    use MyCodeAttrs (
        'has_guess',
        has_guess => {
            -as      => 'needs_guess',
            required => 1,
        },
    );

    has_guess x => (
        is => 'rw',
    );

    needs_guess name => (
        is => 'ro',
    );
};

my $x    = Foo->meta->get_attribute('x');
my $name = Foo->meta->get_attribute('name');

is($x->type_constraint, 'Int');
ok($x->has_accessor, 'has accessor');
ok(!$x->is_required, 'is not required');

is($name->type_constraint, 'Str');
ok($name->has_reader, 'has reader');
ok(!$name->has_writer, 'lacks writer');
ok($name->is_required, 'is required');

