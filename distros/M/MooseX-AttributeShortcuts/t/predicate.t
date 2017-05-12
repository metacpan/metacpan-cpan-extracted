
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

    has public           => (is => 'rw', predicate =>  1);
    has _private         => (is => 'rw', predicate =>  1);
    has public_inverse   => (is => 'rw', predicate => -1);
    has _private_inverse => (is => 'rw', predicate => -1);
}

validate_class TestClass => (

    methods => [qw{
        public           has_public
        _private         _has_private
        public_inverse   _has_public_inverse
        _private_inverse has_private_inverse
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
            predicate => 'has_public',
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
            predicate => '_has_private',
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
            predicate => '_has_public_inverse',
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
            predicate => 'has_private_inverse',
        },
    ],

);


done_testing;
