package PAX::GuardManager;

our $VERSION = '0.031';

use strict;
use warnings;
use PAX::DeoptEngine;

sub new {
    my ($class, %args) = @_;
    return bless {
        epochs => $args{epochs} // {},
        telemetry => [],
    }, $class;
}

sub validate_region {
    my ($self, $ssa_unit) = @_;
    for my $guard (@{ $ssa_unit->{guards} // [] }) {
        my $key = $guard->{invalidation_key};
        if (!exists $self->{epochs}{$key}) {
            push @{ $self->{telemetry} }, {
                region_id => $ssa_unit->{region_id},
                guard_id => $guard->{id},
                status => 'failed',
                reason => 'missing_epoch',
                invalidation_key => $key,
            };
            return 0;
        }
        push @{ $self->{telemetry} }, {
            region_id => $ssa_unit->{region_id},
            guard_id => $guard->{id},
            status => 'passed',
            invalidation_key => $key,
        };
    }
    return 1;
}

sub validate_or_deopt {
    my ($self, $ssa_unit, %args) = @_;
    my $ok = $self->validate_region($ssa_unit);
    if ($ok) {
        return {
            status => 'native_allowed',
            region_id => $ssa_unit->{region_id},
            telemetry => $self->telemetry,
        };
    }

    my $last = $self->{telemetry}[-1] // {};
    my $reconstructed = PAX::DeoptEngine->new->reconstruct(
        ssa_unit => $ssa_unit,
        reason => $last->{reason} // 'guard_failed',
        guard => $last,
        interpreter_result => $args{interpreter_result},
        args => $args{args} // [],
        context => $args{context} // 'scalar',
    );
    return {
        status => 'deopt',
        region_id => $ssa_unit->{region_id},
        fallback => {
            reason => $last->{reason} // 'guard_failed',
            guard_id => $last->{guard_id},
            invalidation_key => $last->{invalidation_key},
            continuation => $ssa_unit->{deopt}{safepoint},
            interpreter_result => $args{interpreter_result},
            reconstructed_frame => $reconstructed,
        },
        telemetry => $self->telemetry,
    };
}

sub invalidate_epoch {
    my ($self, $key) = @_;
    delete $self->{epochs}{$key};
}

sub telemetry {
    my ($self) = @_;
    return $self->{telemetry};
}

1;

=pod

=head1 NAME

PAX::GuardManager - guard registration and invalidation helper

=head1 SYNOPSIS

  use PAX::GuardManager;

  my $obj = PAX::GuardManager->new(...);
  my $result = $obj->validate_region(...);

=head1 DESCRIPTION

Keeps the runtime-side bookkeeping for speculative guards so compiled regions can be invalidated when assumptions stop holding.

=head1 METHODS

=head2 new, validate_region, validate_or_deopt, invalidate_epoch, telemetry

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the guard registration and invalidation helper logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs guard registration and invalidation helper. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects guard registration and invalidation helper, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover guard registration and invalidation helper.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::GuardManager -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
