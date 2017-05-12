use strict;
use warnings;

use Test::More;

# Simple checks to ensure our traits are applied where we expect them to be.

use Test::Moose::More 0.044;

{ package TestClass; use Moose;       use MooseX::AttributeShortcuts; has foo => (is => 'ro') }
{ package TestRole;  use Moose::Role; use MooseX::AttributeShortcuts; has foo => (is => 'ro') }

validate_class TestClass => (
    -subtest => 'validate_class TestClass',

    class_metaroles => {
        attribute => ['MooseX::AttributeShortcuts::Trait::Attribute'],
    },

    attributes => [
        foo => { -does =>  ['MooseX::AttributeShortcuts::Trait::Attribute'] },
    ],
);

validate_role TestRole => (
    -subtest => 'validate_Role TestRole',

    role_metaroles => {
        applied_attribute => ['MooseX::AttributeShortcuts::Trait::Attribute'],
    },

    attributes => [
        foo => { -does =>  ['MooseX::AttributeShortcuts::Trait::Attribute'] },
    ],
);

done_testing;
__END__
