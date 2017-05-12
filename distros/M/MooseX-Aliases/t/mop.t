#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 8;
use Test::Moose;

{
    package MyTest;
    use Moose;
    use MooseX::Aliases;

    sub foo { }
    alias bar => 'foo';

    has baz => (
        is    => 'ro',
        alias => 'quux',
    );
}

with_immutable {
    my $method = MyTest->meta->get_method('bar');
    ok($method->meta->does_role('MooseX::Aliases::Meta::Trait::Method'),
       'does the method trait');
    is($method->aliased_from, 'foo', 'bar is aliased from foo');
    my $attr_method = MyTest->meta->get_method('quux');
    ok($attr_method->meta->does_role('MooseX::Aliases::Meta::Trait::Method'),
       'does the method trait');
    is($attr_method->aliased_from, 'baz', 'quux is aliased from baz');
} 'MyTest';
