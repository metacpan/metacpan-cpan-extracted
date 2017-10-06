use strict;
use warnings;

# These tests only concern themselves with the 'builder => sub { ... }'
# functionality, as 'builder => 1' is tested elsewhere.

use Test::More;
use Test::Moose::More 0.044;

use constant ATTRIBUTE_TRAIT      => 'MooseX::AttributeShortcuts::Trait::Attribute';
use constant ROLE_ATTRIBUTE_TRAIT => 'MooseX::AttributeShortcuts::Trait::Role::Attribute';

my $i = 0;

{
    package TestRole;

    use Moose::Role;
    use namespace::autoclean;
    use MooseX::AttributeShortcuts;

    has  bar => (is => 'ro', builder => sub { $i++ });
    has _bar => (is => 'ro', builder => sub { $i++ });
}
{
    package TestClass;

    use Moose;
    use namespace::autoclean;
    use MooseX::AttributeShortcuts;

    # HA!
    with 'TestRole';

    has  foo => (is => 'ro', builder => sub { $i++ });
    has _foo => (is => 'ro', builder => sub { $i++ });
}

validate_class TestClass => (
    -subtest   => 'validate TestClass structure',
    does       => [ 'TestRole' ],
    attributes => [
        qw{ foo _foo },
        bar => {
            -does   => [ ATTRIBUTE_TRAIT ],
            builder => '_build_bar',
        },
        _bar => {
            -does   => [ ATTRIBUTE_TRAIT ],
            builder => '_build__bar',
        },
        foo => {
            -does   => [ ATTRIBUTE_TRAIT ],
            builder => '_build_foo',
        },
        _foo => {
            -does   => [ ATTRIBUTE_TRAIT ],
            builder => '_build__foo',
        },
    ],
    methods => [ qw{
        foo _build_foo _foo _build__foo
        bar _build_bar _bar _build__bar
    } ],
);


subtest 'check counters!' => sub {
    is $i, 0, 'counter correct (sanity check)';
    my $tc = TestClass->new;
    isa_ok $tc, 'TestClass';
    is $i, 4, 'counter correct';
};

# using builders in roles and being able to exclude/alias them as
# necessary when consuming them is a major win.  Because of that -- and
# because that's what we'd expect to be able to do with a builder when
# created in the usual fashion (aka not anon sub via us) we want to create
# the builder as a method in the role when we define the attribute to a
# role.

validate_role TestRole => (
    -subtest => 'TestRole',
    attributes => [
        bar  => { -does => [ ATTRIBUTE_TRAIT ] },
        _bar => { -does => [ ATTRIBUTE_TRAIT ] },
    ],
    methods => [ qw{ _build_bar _build__bar } ],
);

done_testing;
