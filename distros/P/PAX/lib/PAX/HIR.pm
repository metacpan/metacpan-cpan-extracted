package PAX::HIR;

our $VERSION = '0.031';

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless {
        manifest => $args{manifest},
        regions => $args{regions} // [],
    }, $class;
}

sub lower_all {
    my ($self) = @_;
    my @units;

    for my $region (@{ $self->{regions} }) {
        push @units, $self->lower_region($region);
    }

    return \@units;
}

sub lower_region {
    my ($self, $region) = @_;
    my $blocked = ($region->{lowering_status} // '') eq 'blocked';
    my $native_shape = $blocked ? undef : $region->{source}{native_shape};
    my $body_op = $blocked ? {
        op => 'fallback_call',
        target => $region->{name},
        effects => ['interpreter'],
    } : _body_op_for_region($region, $native_shape);

    return {
        region_id => $region->{id},
        region_name => $region->{name},
        status => $blocked ? 'fallback' : 'lowered',
        native_shape => $native_shape,
        graph => {
            blocks => [
                {
                    id => 'entry',
                    ops => [
                        {
                            op => 'enter_region',
                            context => 'unknown',
                            effects => [],
                        },
                        $body_op,
                        {
                            op => 'return',
                            effects => [],
                        },
                    ],
                    successors => [],
                },
            ],
        },
        source => $region->{source},
        deopt_anchors => [
            {
                block => 'entry',
                reason => $blocked ? $region->{reason} : 'guard_failure',
                live_values => [qw(@_ wantarray)],
            },
        ],
        required_epochs => $region->{required_epochs} // [],
        diagnostics => $blocked ? [{
            level => 'warning',
            code => 'hir_fallback_region',
            message => $region->{reason},
        }] : [],
    };
}

sub _body_op_for_region {
    my ($region, $native_shape) = @_;
    if ($native_shape) {
        return {
            op => 'native_candidate',
            target => $region->{name},
            shape => $native_shape,
            effects => ['guarded_call'],
        };
    }
    return {
        op => 'call_reference_equivalent',
        target => $region->{name},
        effects => ['guarded_call'],
    };
}

1;

=pod

=head1 NAME

PAX::HIR - high-level intermediate representation builder

=head1 SYNOPSIS

  use PAX::HIR;

  my $obj = PAX::HIR->new(...);
  my $result = $obj->lower_all(...);

=head1 DESCRIPTION

Builds the high-level IR records that bridge raw capture output and later guarded or native lowering stages.

=head1 METHODS

=head2 new, lower_all, lower_region

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the high-level intermediate representation builder logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs high-level intermediate representation builder. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects high-level intermediate representation builder, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover high-level intermediate representation builder.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::HIR -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
