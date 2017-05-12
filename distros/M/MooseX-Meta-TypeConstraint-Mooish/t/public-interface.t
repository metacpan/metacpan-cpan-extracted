use strict;
use warnings;

use Test::More;
use Test::Moose::More 0.028;

use aliased 'Moose::Meta::TypeConstraint'                    => 'TypeConstraint';
use aliased 'MooseX::Meta::TypeConstraint::Mooish'           => 'MooishTC';
use aliased 'MooseX::TraitFor::Meta::TypeConstraint::Mooish' => 'TraitFor';

validate_class MooishTC() => (
    isa       => [ TypeConstraint ],
    does      => [ TraitFor       ],
    immutable => 1,
    methods => [ qw{
        mooish
        original_constraint
        has_original_constraint

    }],
    attributes => [
        mooish => {
            is      => 'ro',
            default => 1,
        },
        original_constraint => {
            is        => 'ro',
            predicate => 'has_original_constraint',
        },
    ],
);

validate_role TraitFor() => (
    attributes => [
        mooish => {
            is      => 'ro',
            default => 1,
        },
        original_constraint => {
            is        => 'ro',
            predicate => 'has_original_constraint',
        },
    ],
);

done_testing;
