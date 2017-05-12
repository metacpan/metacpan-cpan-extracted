
use strict;
use warnings;

use Test::More;
use Test::Moose::More 0.043;

use constant Shortcuts => 'MooseX::AttributeShortcuts::Trait::Attribute';

my $trigger_called = 0;

{
    package TestClass;

    use Moose;
    use namespace::autoclean 0.24;
    use MooseX::AttributeShortcuts;

    # "trigger => -1" isn't supported (feel free to submit a PR)

    has public           => (is => 'rw', trigger =>  1);
    has _private         => (is => 'rw', trigger =>  1);

    has test => (is => 'rw', trigger => 1);
    sub _trigger_test { $trigger_called++ }
}

validate_class TestClass => (
    -subtest => 'validating class TestClass',

    methods => [qw{ public _private }],
    no_methods => [ qw{ _trigger_public _trigger__private } ],

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

            trigger_method => '_trigger_public',
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

            trigger_method => '_trigger__private',
        },

    ],
);

subtest 'make sure the trigger is called' => sub {

    my $name = 'test';
    my $a = TestClass->meta->get_attribute($name);
    ok $a->has_trigger, "$name has a trigger";

    ok !$trigger_called, 'no trigger calls yet';
    my $tc = TestClass->new($name => 'Ian');
    is $trigger_called, 1, 'trigger called once';
    $tc->$name('Cormac');
    is $trigger_called, 2, 'trigger called again';
};

done_testing;
