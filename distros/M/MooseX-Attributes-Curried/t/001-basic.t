#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 6;
use lib 't/lib';

do {
    package Foo;
    use Moose;
    use MyAttrs;

    has_str name => (
        is => 'ro',
    );

    has_int age => (
        is => 'rw',
    );
};

my $name = Foo->meta->get_attribute('name');
my $age  = Foo->meta->get_attribute('age');

is($name->type_constraint, 'Str', "name's type constraint");
ok($name->has_reader, "name has a reader");
ok(!$name->has_writer, "name has no writer");

is($age->type_constraint, 'Int', "age's type constraint");
is($age->default, 0, "age's default");
ok($age->has_accessor, "age has a read/write accessor");

