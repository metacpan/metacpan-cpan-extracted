
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

    has public   => (is => 'rwp');
    has _private => (is => 'rwp');
}

validate_class TestClass => (

    methods => [qw{
        public           _set_public
        _private         _set__private
    }],

    attributes => [

        public => {

            -isa      => ['Moose::Meta::Attribute'],
            -does     => [Shortcuts],
            reader    => 'public',
            writer    => '_set_public',
            clearer   => undef,
            builder   => undef,
            default   => undef,
            predicate => undef,
        },

        _private => {

            -isa      => ['Moose::Meta::Attribute'],
            -does     => [Shortcuts],
            reader    => '_private',
            writer    => '_set__private',
            clearer   => undef,
            builder   => undef,
            default   => undef,
            predicate => undef,
        },
    ],
);


done_testing;
