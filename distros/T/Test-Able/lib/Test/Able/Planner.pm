package Test::Able::Planner;

use Moose::Role;
use Moose::Util::TypeConstraints;
use strict;
require Test::Builder;
use warnings;

=head1 NAME

Test::Able::Planner - Planning role

=head1 DESCRIPTION

This role represents the core of the planning support in Test::Able.

The vast majority of the time all that's necessary, in terms of planning, is
to set the plans at the method level.  For a more thorough explanation of how
planning in Test::Able works read on.

In order to facilitate planning there's a hierarchy of plans.  That hierarchy
is as follows:  test-related methods, test objects, test runner object, and
Test::Builder.  The sum of all the constituent method plans make up the
object plan.  The sum of all the constituent object plans make up the runner
object plan.  And the runner object plan gets added to Test::Builder's plan.

Its possible to set a method's plan at any time.  To make this possible the
object and runner object plans are cleared when a method plan is set.  Then,
the runner object's plan gets recalculated, at the latest, when it needs to
add to Test::Builder's plan.

At the moment Test::Builder does not support deferred planning.  Until such
time as Test::Builder supports it Test::Able emulates it as best it can for
its own purposes.

If Test::Builder's plan is set to a numeric value then Test::Able
will not touch it.  If Test::Builder's plan is no_plan then Test::Able will
persuade Test::Builder to do deferred planning with what it thinks is the
plan.

Note that as a convenience, if Test::Builder's plan is not declared by the
time Test::Able's run_tests() is called the plan will be set to no_plan.

=head1 ATTRIBUTES

=over

=item builder

The Test::Builder instance.

=cut

has 'builder' => (
    is => 'ro', isa => 'Test::Builder', lazy_build => 1,
);

subtype 'Test::Able::Plan' => as 'Str' => where { /^no_plan|\d+$/; };

=item plan

Test plan similar to Test::Builder's.

=cut

has 'plan' => (
    is => 'rw', isa => 'Test::Able::Plan', lazy_build => 1,
    trigger => sub {
        my ( $self, ) = @_;

        if ( $self->isa( 'Moose::Meta::Method' ) ) {
            my $in_a_role = $self->associated_metaclass->isa(
                'Moose::Meta::Role'
            );
            $self->associated_metaclass->clear_plan unless $in_a_role;
        }

        return;
    },
);

=item runner_plan

The plan that the test runner object manages.  This is the top level plan that
all other plans are aggregated into.

=cut

has 'runner_plan' => (
    is => 'rw', isa => 'Test::Able::Plan', lazy_build => 1,
);

=item last_runner_plan

Used by the test runner object in calculating Test::Builder's plan.

=back

=cut

has 'last_runner_plan' => (
    is => 'rw', isa => 'Test::Able::Plan',
    predicate => 'has_last_runner_plan',
    clearer => 'clear_last_runner_plan',
);

sub _build_builder {
    my ( $self, ) = @_;

    return Test::Builder->new;
}

=head1 AUTHOR

Justin DeVuyst, C<justin@devuyst.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Justin DeVuyst.

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
