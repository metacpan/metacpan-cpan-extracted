#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

our $foo_constructed = 0;

package Foo;

sub new {
    my $class = shift;
    bless {}, $class;
}

package Foo::Moose;
use Moose;
use MooseX::NonMoose;
extends 'Foo';

after new => sub {
    $main::foo_constructed = 1;
};

package Foo::Moose2;
use Moose;
use MooseX::NonMoose;
extends 'Foo';

sub new {
    my $class = shift;
    $main::foo_constructed = 1;
    return $class->meta->new_object(@_);
}

package main;
my $method = Foo::Moose->meta->get_method('new');
isa_ok($method, 'Class::MOP::Method::Wrapped');
my $foo = Foo::Moose->new;
ok($foo_constructed, 'method modifier called for the constructor');
$foo_constructed = 0;
{
    # we don't care about the warning that moose isn't going to inline our
    # constructor - this is the behavior we're testing
    local $SIG{__WARN__} = sub {};
    Foo::Moose->meta->make_immutable;
}
is($method, Foo::Moose->meta->get_method('new'),
   'make_immutable doesn\'t overwrite constructor with method modifiers');
$foo = Foo::Moose->new;
ok($foo_constructed, 'method modifier called for the constructor (immutable)');

$foo_constructed = 0;
$method = Foo::Moose2->meta->get_method('new');
$foo = Foo::Moose2->new;
ok($foo_constructed, 'custom constructor called');
$foo_constructed = 0;
# still need to specify inline_constructor => 0 when overriding new manually
Foo::Moose2->meta->make_immutable(inline_constructor => 0);
is($method, Foo::Moose2->meta->get_method('new'),
   'make_immutable doesn\'t overwrite custom constructor');
$foo = Foo::Moose2->new;
ok($foo_constructed, 'custom constructor called (immutable)');

done_testing;
