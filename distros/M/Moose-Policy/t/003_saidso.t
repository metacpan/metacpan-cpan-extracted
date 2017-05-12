#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    require Moose;

    plan skip_all => 'Moose::Policy does not work with recent versions of Moose'
        if Moose->VERSION >= 1.05;

    plan tests => 22;

    use_ok('Moose::Policy');
}

{
    package My::Moose::Meta::Attribute;
    use Moose;

    extends 'Moose::Meta::Attribute';

    # this one gives you PBP accessors
    # and gives you accessors unless you said otherwise
    sub _process_options {
        my ($class, $name, $options) = @_;
        my $is = delete $options->{is} || 'rw';
        if($is eq 'ro') {
            $options->{reader} = 'get_' . $name;
        }
        elsif($is eq 'rw') {
            $options->{reader} = 'get_' . $name;
            $options->{writer} = 'set_' . $name;
        }
        elsif($is eq 'no') {
            # only way to not get accessors
        }
        else {
            # pass it through and let him deal with it
            $options->{is} = $is;
        }

        $class->SUPER::_process_options($name, $options);
    }
}

{
    package My::Moose::Policy;
    # policy just specifies metaclass delegates
    use constant attribute_metaclass => 'My::Moose::Meta::Attribute';
}

my $oops;
{
    package Foo;

    use Moose::Policy 'My::Moose::Policy';
    use Moose;

    has 'bar' => (default => 'Foo::bar');
    has 'baz' => (default => 'Foo::baz');
    has 'bop' => (is => 'bare', default => 'woot');
    eval { has 'oops' => (is => 'thbbbt'); };
    $oops = $@;
}

ok($oops, "thbbt got booted out");

isa_ok(Foo->meta, 'Moose::Meta::Class');
is(Foo->meta->attribute_metaclass, 'My::Moose::Meta::Attribute', '... got our custom attr metaclass');

isa_ok(Foo->meta->get_attribute('bar'), 'My::Moose::Meta::Attribute');

my $foo = Foo->new;
isa_ok($foo, 'Foo');

can_ok($foo, 'get_bar');
can_ok($foo, 'set_bar');

can_ok($foo, 'get_baz');
can_ok($foo, 'set_baz');

ok(! $foo->can('bop'), 'do not want any bop');
ok(! $foo->can('get_bop'), 'do not want any bop');
ok(! $foo->can('set_bop'), 'do not want any bop');

ok(! $foo->can('oops'), 'do not want any oops');
ok(! $foo->can('get_oops'), 'do not want any oops');
ok(! $foo->can('set_oops'), 'do not want any oops');

is($foo->get_bar, 'Foo::bar', '... got the right default bar value');
is($foo->get_baz, 'Foo::baz', '... got the right default baz value');
ok(exists($foo->{bop}), 'we have bop');
ok(! exists($foo->{oops}), 'do not want to have an oops');
is($foo->{bop}, 'woot',     '... got the right default bop value');

$foo->set_bar('the new bar');
is($foo->get_bar, 'the new bar', 'setter works');

# vim:ts=4:sw=4:et:sta

