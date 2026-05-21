package PAX::DeoptEngine;

our $VERSION = '0.031';

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless {}, $class;
}

sub reconstruct {
    my ($self, %args) = @_;
    my $ssa_unit = $args{ssa_unit} // {};
    my $reason = $args{reason} // 'guard_failed';
    my $guard = $args{guard} // {};
    my $interpreter_result = $args{interpreter_result};
    my $args_value = $args{args} // [];
    my $context = $args{context} // 'scalar';
    my $deopt = $ssa_unit->{deopt} // {};

    return {
        status => 'reconstructed',
        region_id => $ssa_unit->{region_id},
        region_name => $ssa_unit->{region_name},
        reason => $reason,
        guard_id => $guard->{guard_id},
        invalidation_key => $guard->{invalidation_key},
        continuation => $deopt->{safepoint},
        frame => {
            argv => [@$args_value],
            wantarray => _wantarray_for_context($context),
            lexicals => $args{lexicals} // {},
            closure_environment => $args{closure_environment} // {},
            exception_handlers => $args{exception_handlers} // [],
            exception_state => $args{exception_state},
            caller => $args{caller},
            debugger_stack => $args{debugger_stack} // [],
        },
        materialised => $deopt->{materialise} // [],
        interpreter_result => $interpreter_result,
    };
}

sub _wantarray_for_context {
    my ($context) = @_;
    return undef if !defined $context || $context eq 'void';
    return 1 if $context eq 'list';
    return 0;
}

1;

=pod

=head1 NAME

PAX::DeoptEngine - deoptimization policy helper

=head1 SYNOPSIS

  use PAX::DeoptEngine;

  my $obj = PAX::DeoptEngine->new(...);
  my $result = $obj->reconstruct(...);

=head1 DESCRIPTION

Tracks when speculative native execution must drop back to the safer runtime path after a guard failure or unsupported state transition.

=head1 METHODS

=head2 new, reconstruct

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the deoptimization policy helper logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs deoptimization policy helper. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects deoptimization policy helper, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover deoptimization policy helper.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::DeoptEngine -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
