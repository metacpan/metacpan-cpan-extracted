
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

    # four permutations here: public/normal, private/normal, public/inverse,
    # private/inverse

    has public           => (is => 'rw', clearer =>  1);
    has _private         => (is => 'rw', clearer =>  1);
    has public_inverse   => (is => 'rw', clearer => -1);
    has _private_inverse => (is => 'rw', clearer => -1);
}

validate_class TestClass => (

    methods => [qw{
        public           clear_public
        _private         _clear_private
        public_inverse   _clear_public_inverse
        _private_inverse clear_private_inverse
    }],

    attributes => [

        public => {

            -isa      => ['Moose::Meta::Attribute'],
            -does     => [Shortcuts],
            reader    => undef,
            writer    => undef,
            clearer   => undef,
            builder   => undef,
            default   => undef,
            predicate => undef,
            accessor  => 'public',
            clearer   => 'clear_public',
        },

        _private => {

            -isa      => ['Moose::Meta::Attribute'],
            -does     => [Shortcuts],
            reader    => undef,
            writer    => undef,
            clearer   => undef,
            builder   => undef,
            default   => undef,
            predicate => undef,
            accessor  => '_private',
            clearer   => '_clear_private',
        },

        public_inverse => {

            -isa      => ['Moose::Meta::Attribute'],
            -does     => [Shortcuts],
            reader    => undef,
            writer    => undef,
            clearer   => undef,
            builder   => undef,
            default   => undef,
            predicate => undef,
            accessor  => 'public_inverse',
            clearer   => '_clear_public_inverse',
        },

        _private_inverse => {

            -isa      => ['Moose::Meta::Attribute'],
            -does     => [Shortcuts],
            reader    => undef,
            writer    => undef,
            clearer   => undef,
            builder   => undef,
            default   => undef,
            predicate => undef,
            accessor  => '_private_inverse',
            clearer   => 'clear_private_inverse',
        },
    ],

);


done_testing;
