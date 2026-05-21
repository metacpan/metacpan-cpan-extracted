package PAX::GuardedSSA;

our $VERSION = '0.031';

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless {
        hir_units => $args{hir_units} // [],
    }, $class;
}

sub build_all {
    my ($self) = @_;
    return [map { $self->build_unit($_) } @{ $self->{hir_units} }];
}

sub build_unit {
    my ($self, $unit) = @_;
    my $fallback = ($unit->{status} // '') eq 'fallback';
    my @guards = map {
        {
            id => 'guard_' . $_,
            predicate => $_ . '_epoch_unchanged',
            invalidation_key => $_,
            deopt_continuation => $unit->{region_id} . ':entry',
            compatibility_classification => $fallback ? 'fallback' : 'guarded',
        }
    } @{ $unit->{required_epochs} // [] };

    return {
        region_id => $unit->{region_id},
        region_name => $unit->{region_name},
        source => $unit->{source},
        status => $fallback ? 'fallback' : 'ssa',
        native_shape => $unit->{native_shape},
        values => [
            {
                id => 'v0',
                kind => 'frame_args',
                type_hypothesis => 'PerlValue[]',
            },
            {
                id => 'v1',
                kind => 'context',
                type_hypothesis => 'scalar|list|void',
            },
        ],
        guards => \@guards,
        blocks => [
            {
                id => 'entry',
                ops => [
                    map +{
                        op => 'guard',
                        guard_id => $_->{id},
                    }, @guards
                ],
                terminator => $fallback ? 'deopt_to_interpreter' : 'call_lowered_region',
            },
        ],
        deopt => {
            safepoint => $unit->{region_id} . ':entry',
            materialise => [qw(@_ wantarray lexicals exception_state)],
            anchors => $unit->{deopt_anchors} // [],
        },
    };
}

1;

=pod

=head1 NAME

PAX::GuardedSSA - guard-aware SSA lowerer

=head1 SYNOPSIS

  use PAX::GuardedSSA;

  my $obj = PAX::GuardedSSA->new(...);
  my $result = $obj->build_all(...);

=head1 DESCRIPTION

Transforms captured regions into a guarded SSA form that later native-planning stages can analyze.

=head1 METHODS

=head2 new, build_all, build_unit

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the guard-aware SSA lowerer logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs guard-aware SSA lowerer. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects guard-aware SSA lowerer, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover guard-aware SSA lowerer.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::GuardedSSA -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
