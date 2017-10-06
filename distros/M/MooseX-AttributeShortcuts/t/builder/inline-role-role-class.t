use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use constant ATTRIBUTE_TRAIT      => 'MooseX::AttributeShortcuts::Trait::Attribute';
use constant ROLE_ATTRIBUTE_TRAIT => 'MooseX::AttributeShortcuts::Trait::Role::Attribute';

{ package A; use Moose::Role; use MooseX::AttributeShortcuts; has a => (is => 'ro', builder => sub { 16 }) }
{ package B; use Moose::Role; with 'A'                                  }
{ package C; use Moose;       with 'B'                                  }

validate_role 'A' => (
    -subtest => 'A',
    methods => [ qw{ _build_a } ],
    role_metaroles => {
        attribute         => [ ROLE_ATTRIBUTE_TRAIT ],
        applied_attribute => [ ATTRIBUTE_TRAIT      ],
    },
    attributes => [
        a => {
            -does => [ ROLE_ATTRIBUTE_TRAIT ],
        },
    ],
);

validate_role 'B' => (
    -subtest => 'B',
    does     => ['A'],
    methods  => [ qw{ _build_a } ],
);

validate_class 'C' => (
    -subtest   => 'C',
    does       => ['A', 'B'],
    attributes => ['bar'],
    methods    => [ qw{ _build_bar } ],
    methods  => ['_build_a'],
    attributes => [
        a => {
            -does => [ATTRIBUTE_TRAIT],
            builder => '_build_a',
        },
    ],
);

is C::_build_a() => 16, '...::_build_bar() is correct (16)';
my $tc = C->new;
is $tc->a() => 16, 'builder method as expected (16)';

method_from_pkg_ok C => '_build_a', 'A';

done_testing;

