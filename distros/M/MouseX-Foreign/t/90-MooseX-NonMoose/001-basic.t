#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

package Foo;

sub new {
    my $class = shift;
    bless { _class => $class }, $class;
}

package Foo::Mouse;
use Mouse;
use MouseX::Foreign qw(Foo);

package main;
my $foo = Foo->new;
my $foo_moose = Foo::Mouse->new;
isa_ok($foo, 'Foo');
is($foo->{_class}, 'Foo', 'Foo gets the correct class');
isa_ok($foo_moose, 'Foo::Mouse');
isa_ok($foo_moose, 'Foo');
isa_ok($foo_moose, 'Mouse::Object');
is($foo_moose->{_class}, 'Foo::Mouse', 'Foo::Mouse gets the correct class');
my $meta = Foo::Mouse->meta;
ok($meta->has_method('new'), 'Foo::Mouse has its own constructor');
my $cc_meta = $meta->constructor_class->meta;
isa_ok($cc_meta, 'Mouse::Meta::Class');

done_testing;
