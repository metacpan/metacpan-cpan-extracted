#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

BEGIN {
    use_ok('Moose::Policy');
}

BEGIN {
    package My::Plain::Attribute;
    use Moose;
    extends 'Moose::Meta::Attribute';
}
BEGIN {
    package My::Bar::Attribute;
    use Moose;
    extends 'Moose::Meta::Attribute';
}
BEGIN {
    package My::Plain::Class;
    use Moose;
    extends 'Moose::Meta::Class';
}
BEGIN {
    package My::Bar::Class;
    use Moose;
    extends 'Moose::Meta::Class';
}
BEGIN {
    package My::Moose::Policy;
    # because writing subs is hard
    my %pkg_map = (
        qw(metaclass Class),
        qw(attribute_metaclass  Attribute),
        # TODO these:
        # qw(method_metaclass Method),
        # qw(instance_metaclass Instance),
    );
    foreach my $subname (keys(%pkg_map)) {
        my $pkg = $pkg_map{$subname};
        my $sub = sub {
            my $self = shift;
            my ($caller) = @_;
            return('My::Bar::' . $pkg)
                if($caller =~ m/^Bar(?:::|$)/);
            return 'My::Plain::' . $pkg;
        };
        no strict 'refs';
        *{$subname} = $sub;
    }
}
{
    package Foo;
    use Moose::Policy 'My::Moose::Policy';
}
{
    package Bar;
    use Moose::Policy 'My::Moose::Policy';
}
{
    package Bars;
    use Moose::Policy 'My::Moose::Policy';
}
{
    package Bar::None;
    use Moose::Policy 'My::Moose::Policy';
}

isa_ok(Foo->meta, 'Moose::Meta::Class');
is(Foo->meta->attribute_metaclass, 'My::Plain::Attribute',
    '... got our custom attr metaclass');

isa_ok(Bar->meta, 'Moose::Meta::Class');
isa_ok(Bar->meta, 'My::Bar::Class');
is(Bar->meta->attribute_metaclass, 'My::Bar::Attribute',
    '... got our custom attr metaclass');

isa_ok(Bars->meta, 'Moose::Meta::Class');
isa_ok(Bars->meta, 'My::Plain::Class');
is(Bars->meta->attribute_metaclass, 'My::Plain::Attribute',
    '... got our custom attr metaclass');

isa_ok(Bar::None->meta, 'Moose::Meta::Class');
isa_ok(Bar::None->meta, 'My::Bar::Class');
is(Bar::None->meta->attribute_metaclass, 'My::Bar::Attribute',
    '... got our custom attr metaclass');
