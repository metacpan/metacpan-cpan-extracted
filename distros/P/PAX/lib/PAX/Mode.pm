package PAX::Mode;

our $VERSION = '0.031';

use strict;
use warnings;

sub policy {
    my ($class, $mode) = @_;
    $mode //= 'dev';
    my %policies = (
        dev => {
            explainability => 'max',
            cache_persistence => 'low',
            undeclared_inputs => 'warn',
            telemetry => 'verbose',
        },
        ci => {
            explainability => 'structured',
            cache_persistence => 'content-addressed',
            undeclared_inputs => 'fail',
            telemetry => 'strict',
        },
        prod => {
            explainability => 'summary',
            cache_persistence => 'persistent',
            undeclared_inputs => 'record',
            telemetry => 'low_overhead',
        },
    );
    return $policies{$mode} // $policies{dev};
}

1;

=pod

=head1 NAME

PAX::Mode - mode normalizer for capture and build flows

=head1 SYNOPSIS

  use PAX::Mode;

  my $result = PAX::Mode->policy(...);

=head1 DESCRIPTION

Normalizes public mode names and defaults so the CLI and internals agree on live, hermetic, and related execution modes.

=head1 METHODS

=head2 policy

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the mode normalizer for capture and build flows logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs mode normalizer for capture and build flows. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects mode normalizer for capture and build flows, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover mode normalizer for capture and build flows.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::Mode -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
