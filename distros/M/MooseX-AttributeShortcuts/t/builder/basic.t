use strict;
use warnings;

use Test::More;
use Test::Moose::More 0.043;

use constant Shortcuts => 'MooseX::AttributeShortcuts::Trait::Attribute';

{
    package TestClass;

    use Moose;
    use namespace::autoclean 0.24;
    use MooseX::AttributeShortcuts;

    has public   => (is => 'rw', lazy => 1, builder =>  1);
    has _private => (is => 'rw', lazy => 1, builder =>  1);
}

validate_class TestClass => (

    methods => [qw{ public _private }],

    no_methods => [ qw{ _build_public _build__private build_public build__private } ],

    attributes => [

        public => {

            -isa      => ['Moose::Meta::Attribute'],
            -does     => [Shortcuts],
            reader    => undef,
            writer    => undef,
            clearer   => undef,
            builder   => '_build_public',
            default   => undef,
            predicate => undef,
            accessor  => 'public',
        },

        _private => {

            -isa      => ['Moose::Meta::Attribute'],
            -does     => [Shortcuts],
            reader    => undef,
            writer    => undef,
            clearer   => undef,
            builder   => '_build__private',
            default   => undef,
            predicate => undef,
            accessor  => '_private',
        },
    ],
);


done_testing;
