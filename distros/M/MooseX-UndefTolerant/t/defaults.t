use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;
use Test::Moose;

use MooseX::UndefTolerant::Attribute ();

{
    package Foo;
    use Moose;

    has 'attr1' => (
        traits => [ qw(MooseX::UndefTolerant::Attribute)],
        is => 'ro',
        isa => 'Num',
        predicate => 'has_attr1',
        default => 1,
    );
    has 'attr2' => (
        is => 'ro',
        isa => 'Num',
        predicate => 'has_attr2',
        default => 2,
    );
    has 'attr3' => (
        is => 'ro',
        isa => 'Maybe[Num]',
        predicate => 'has_attr3',
        default => 3,
    );
}

{
    package Bar;
    use Moose;
    use MooseX::UndefTolerant;

    has 'attr1' => (
        is => 'ro',
        isa => 'Num',
        predicate => 'has_attr1',
        default => 1,
    );
    has 'attr2' => (
        is => 'ro',
        isa => 'Num',
        predicate => 'has_attr2',
        default => 2,
    );
    has 'attr3' => (
        is => 'ro',
        isa => 'Maybe[Num]',
        predicate => 'has_attr3',
        default => 3,
    );
}


package main;

sub do_tests
{
    note 'Default behaviour: ',
        (Foo->meta->is_immutable ? 'im' : '') . 'mutable classes', "\n";

    note 'Testing class with a single UndefTolerant attribute';
    do_tests_with_class('Foo');

    note '';
    note 'Testing class with the entire class being UndefTolerant';
    do_tests_with_class('Bar');
}

sub do_tests_with_class
{
    my $class = shift;

    {
        my $obj = $class->new;
        ok($obj->has_attr1, 'attr1 has a value');
        ok($obj->has_attr2, 'attr2 has a value');
        ok($obj->has_attr3, 'attr3 has a value');

        is($obj->attr1, 1, 'attr1\'s value is its default');
        is($obj->attr2, 2, 'attr2\'s value is its default');
        is($obj->attr3, 3, 'attr3\'s value is its default');
    }

    TODO: {
        my $e = exception {
            my $obj = $class->new(attr1 => undef, attr3 => undef);
            {
                local $TODO = 'not sure why this fails still... needs attr trait rewrite' if $obj->meta->is_immutable;
                # FIXME: the object is successfully constructed, and the value
                # for attr1 is properly removed, but the default is not then
                # used instead...
                # note "### constructed object: ", $obj->dump(2);
                ok($obj->has_attr1, 'UT attr1 has a value when assigned undef in constructor');
                is($obj->attr1, 1, 'attr1\'s value is its default');
            }
            ok($obj->has_attr3, 'attr3 retains its undef value when assigned undef in constructor');

            is($obj->attr2, 2, 'attr2\'s value is its default');
            is($obj->attr3, undef, 'attr3\'s value is not its default (explicitly set)');
        };
        local $TODO = 'some immutable cases are not handled yet; see CAVEATS'
            if $class->meta->is_immutable and $class eq 'Foo';

        is($e, undef, 'these tests do not die');
    }

    {
        my $obj = $class->new(attr1 => 1234, attr2 => 5678, attr3 => 9012);
        is($obj->attr1, 1234, 'assigning a defined value during construction works as normal');
        ok($obj->has_attr1, '...and the predicate returns true as normal');

        is($obj->attr2, 5678, 'assigning a defined value during construction works as normal');
        ok($obj->has_attr2, '...and the predicate returns true as normal');

        is($obj->attr3, 9012, 'assigning a defined value during construction works as normal');
        ok($obj->has_attr3, '...and the predicate returns true as normal');
    }
}

with_immutable {
    do_tests;
} qw(Foo Bar);

TODO: {
    local $TODO = 'some cases are still not handled yet; see CAVEATS';
    is(Test::More->builder->current_test, 98, 'if we got here, we can declare victory!');
}

done_testing;

