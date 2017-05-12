use strict;
use warnings;
use Test::More 0.88;

do {
    package Labeled;
    use MooseX::Role::Parameterized;

    ::is(MooseX::Role::Parameterized->current_metaclass, undef, 'no metaclass yet');

    parameter default => (
        is  => 'rw',
        isa => 'Str',
    );

    ::is(MooseX::Role::Parameterized->current_metaclass, undef, 'no metaclass yet');

    role {
        my $p    = shift;
        my %args = @_;

        ::is(MooseX::Role::Parameterized->current_metaclass, $args{operating_on}, 'now we have a metaclass');

        has label => (
            is      => 'rw',
            isa     => 'Str',
            default => $p->default,
        );

        ::is(MooseX::Role::Parameterized->current_metaclass, $args{operating_on}, 'now we have a metaclass');
    };

    ::is(MooseX::Role::Parameterized->current_metaclass, undef, 'no metaclass yet');
};

do {
    package Foo;
    use Moose;

    ::is(MooseX::Role::Parameterized->current_metaclass, undef, 'no metaclass yet');
    with Labeled => { default => 'foo' };
    ::is(MooseX::Role::Parameterized->current_metaclass, undef, 'metaclass is gone now');
};

done_testing;
