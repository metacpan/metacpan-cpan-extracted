#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Scalar::Util 'blessed';

BEGIN {
    plan skip_all => "DateTime and MooseX::AttributeHelpers are required"
        unless eval { require DateTime; require MooseX::AttributeHelpers; 1 };
}

plan tests => 8;

do {
    package Foo;
    use Moose;
    use MySmartAttrs;

    xhas seen => (
        is  => 'ro',
        isa => 'HashRef',
        provides => {
            set => 'mark',
            get => 'has_seen',
        },
    );

    xhas age => (
        is  => 'ro',
        isa => 'Int',
    );

    xhas time => (
        private => 1,
        isa     => 'DateTime',
    );
};

can_ok(Foo => qw(seen mark has_seen));
can_ok(Foo => qw(time _set_time)); # created by virtual option "private => 1"

my $seen = Foo->meta->get_attribute('seen');
my $age  = Foo->meta->get_attribute('age');
my $time = Foo->meta->get_attribute('time');

is(blessed($seen), 'MooseX::AttributeHelpers::Collection::Hash','seen attribute has Hash helpers');
is(blessed($age),  'Moose::Meta::Attribute', 'age is plain, since it asked for no helpers');
is(blessed($time), 'Moose::Meta::Attribute', 'time is plain, since it asked for no helpers');

my $foo = Foo->new;

is_deeply($foo->seen, {}, 'hashref default intuited');
is($foo->age, undef, "no default, since it has no provides and is not a class");
isa_ok($foo->time, 'DateTime', 'class default intuited');

