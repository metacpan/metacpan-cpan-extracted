package PAX::Backend::Tier1CraneliftEquivalent;
our $VERSION = '0.031';

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless {
        name => $args{name} // 'cranelift-equivalent-low-latency-backend',
    }, $class;
}

sub metadata {
    my ($self) = @_;
    return {
        tier => 1,
        name => $self->{name},
        role => 'quick_native_backend',
        contract => 'low_latency_guarded_ssa_native_emission',
    };
}

1;

=pod

=head1 NAME

PAX::Backend::Tier1CraneliftEquivalent - tier-1 backend planning stub for fast native code generation

=head1 SYNOPSIS

  use PAX::Backend::Tier1CraneliftEquivalent;

  my $obj = PAX::Backend::Tier1CraneliftEquivalent->new(...);
  my $result = $obj->metadata(...);

=head1 DESCRIPTION

Represents the fast-path tier-1 backend contract that can accept lowered regions and return an execution plan for quick native compilation.

=head1 METHODS

=head2 new, metadata

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the tier-1 backend planning stub for fast native code generation logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs tier-1 backend planning stub for fast native code generation. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects tier-1 backend planning stub for fast native code generation, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover tier-1 backend planning stub for fast native code generation.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::Backend::Tier1CraneliftEquivalent -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
