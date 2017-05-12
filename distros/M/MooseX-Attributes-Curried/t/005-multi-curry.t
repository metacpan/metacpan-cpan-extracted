#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 6;
use lib 't/lib';

do {
    package Foo;
    use Moose;
    use MyAttrs (
        has_str => {
            -as     => 'default_str',
            default => '',
        },
        has_str => {
            -as      => 'needs_str',
            required => 1,
        },
    );

    needs_str 'name';
    default_str 'confound';
};

my $name = Foo->meta->get_attribute('name');
my $confound = Foo->meta->get_attribute('confound');

is($name->type_constraint, 'Str', 'needs_str isa has_str');
is($confound->type_constraint, 'Str', 'default_str isa has_str');

ok($name->is_required, 'needs_str: required');
is($confound->default, '', 'default_str: default');

ok(!$confound->is_required, 'default_str: not required');
ok(!$name->has_default, 'needs_str: no default');

