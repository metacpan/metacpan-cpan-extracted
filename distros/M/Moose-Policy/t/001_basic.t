#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    require Moose;

    plan skip_all => 'Moose::Policy does not work with recent versions of Moose'
        if Moose->VERSION >= 1.05;

    plan tests => 11;

    use_ok('Moose::Policy');
}

{
    package My::Moose::Meta::Attribute;
    use Moose;

    extends 'Moose::Meta::Attribute';

    # this method (mostly stolen from M::M::Attribute) just rebuilds the
    # options so anything with 'is' gets PBP accessors
    before '_process_options' => sub {
        my ($class, $name, $options) = @_;
        if (exists $options->{is}) {
            if ($options->{is} eq 'ro') {
                $options->{reader} = 'get_' . $name;
            }
            elsif ($options->{is} eq 'rw') {
                $options->{reader} = 'get_' . $name;
                $options->{writer} = 'set_' . $name;
            }
            delete $options->{is};
        }

        $class->SUPER::_process_options($name, $options);
    }
}

{
    package My::Moose::Policy;
    # policy just specifies metaclass delegates
    use constant attribute_metaclass => 'My::Moose::Meta::Attribute';
}

{
    package Foo;

    use Moose::Policy 'My::Moose::Policy';
    use Moose;

    has 'bar' => (is => 'rw', default => 'Foo::bar');
    has 'baz' => (is => 'ro', default => 'Foo::baz');
}

isa_ok(Foo->meta, 'Moose::Meta::Class');
is(Foo->meta->attribute_metaclass, 'My::Moose::Meta::Attribute', '... got our custom attr metaclass');

isa_ok(Foo->meta->get_attribute('bar'), 'My::Moose::Meta::Attribute');

my $foo = Foo->new;
isa_ok($foo, 'Foo');

can_ok($foo, 'get_bar');
can_ok($foo, 'set_bar');

can_ok($foo, 'get_baz');
ok(! $foo->can('set_baz'), 'without setter');

is($foo->get_bar, 'Foo::bar', '... got the right default value');
is($foo->get_baz, 'Foo::baz', '... got the right default value');

# vim:ts=4:sw=4:et:sta
