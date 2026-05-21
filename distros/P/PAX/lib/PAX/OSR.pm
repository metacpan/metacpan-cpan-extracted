package PAX::OSR;

our $VERSION = '0.031';

use strict;
use warnings;
use JSON::PP ();

sub new {
    my ($class, %args) = @_;
    return bless {
        threshold => $args{threshold} // 2,
    }, $class;
}

sub evaluate {
    my ($self, %args) = @_;
    my $unit = $args{ssa_unit} // {};
    my $profile = $args{profile} // {};
    my $shape = $unit->{native_shape} // $unit->{source}{native_shape} // {};
    my $dispatches = $profile->{dispatches} // 0;

    if (($shape->{kind} // '') ne 'i64_sum_loop') {
        return {
            status => 'not_applicable',
            reason => 'region is not an OSR-capable loop',
            osr_event => undef,
            safepoint => $unit->{deopt}{safepoint},
        };
    }

    if ($dispatches + 1 >= $self->{threshold}) {
        return {
            status => 'promote',
            reason => 'loop reached OSR threshold',
            osr_event => 'promote',
            loop_header => 'entry',
            backedge => 'entry',
            safepoint => $unit->{deopt}{safepoint},
        };
    }

    return {
        status => 'observe',
        reason => 'loop below OSR threshold',
        osr_event => undef,
        loop_header => 'entry',
        backedge => 'entry',
        safepoint => $unit->{deopt}{safepoint},
    };
}

sub retirement {
    my ($self, %args) = @_;
    return {
        status => 'retire',
        reason => $args{reason} // 'guard invalidated promoted OSR region',
        osr_event => 'retire',
        safepoint => $args{safepoint},
    };
}

1;

=pod

=head1 NAME

PAX::OSR - on-stack replacement promotion planner

=head1 SYNOPSIS

  use PAX::OSR;

  my $obj = PAX::OSR->new(...);
  my $result = $obj->evaluate(...);

=head1 DESCRIPTION

Evaluates loop and dispatch profiles to decide when PAX should offer an on-stack replacement path.

=head1 METHODS

=head2 new, evaluate, retirement

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the on-stack replacement promotion planner logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs on-stack replacement promotion planner. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects on-stack replacement promotion planner, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover on-stack replacement promotion planner.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::OSR -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
