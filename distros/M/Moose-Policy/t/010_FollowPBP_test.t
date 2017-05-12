#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    require Moose;

    plan skip_all => 'Moose::Policy does not work with recent versions of Moose'
        if Moose->VERSION >= 1.05;

    plan tests => 28;

    use_ok('Moose::Policy');
}

{
    package Foo;

    use Moose::Policy 'Moose::Policy::FollowPBP';
    use Moose;

    has 'bar' => (is => 'rw', default => 'Foo::bar');
    has 'baz' => (is => 'ro', default => 'Foo::baz');
}

isa_ok(Foo->meta, 'Moose::Meta::Class');
is(Foo->meta->attribute_metaclass, 'Moose::Policy::FollowPBP::Attribute', '... got our custom attr metaclass');

isa_ok(Foo->meta->get_attribute('bar'), 'Moose::Policy::FollowPBP::Attribute');

my $foo = Foo->new;
isa_ok($foo, 'Foo');

can_ok($foo, 'get_bar');
can_ok($foo, 'set_bar');

can_ok($foo, 'get_baz');
ok(! $foo->can('set_baz'), 'without setter');

is($foo->get_bar, 'Foo::bar', '... got the right default value');
is($foo->get_baz, 'Foo::baz', '... got the right default value');

{
    package Bar;
    use Moose::Policy 'Moose::Policy::FollowPBP';    
    use Moose;
    
    extends 'Foo';

    has 'boing' => (is => 'rw', default => 'Bar::boing');
}

isa_ok(Bar->meta, 'Moose::Meta::Class');
is(Bar->meta->attribute_metaclass, 'Moose::Policy::FollowPBP::Attribute', '... got our custom attr metaclass');

isa_ok(Bar->meta->get_attribute('boing'), 'Moose::Policy::FollowPBP::Attribute');

my $bar = Bar->new;
isa_ok($bar, 'Bar');
isa_ok($bar, 'Foo');

can_ok($bar, 'get_boing');
can_ok($bar, 'set_boing');

is($bar->get_boing, 'Bar::boing', '... got the right default value');
$bar->set_boing('Woot!');
is($bar->get_boing, 'Woot!', '... got the right changed value');

{
    package Baz;
    use Moose;
    
    extends 'Bar';

    has 'bling' => (is => 'ro', default => 'Baz::bling');
}

isa_ok(Baz->meta, 'Moose::Meta::Class');
is(Baz->meta->attribute_metaclass, 'Moose::Meta::Attribute', '... got our custom attr metaclass');

isa_ok(Baz->meta->get_attribute('bling'), 'Moose::Meta::Attribute');

my $baz = Baz->new;
isa_ok($baz, 'Baz');
isa_ok($baz, 'Bar');
isa_ok($baz, 'Foo');

can_ok($baz, 'bling');

is($baz->bling, 'Baz::bling', '... got the right default value');
