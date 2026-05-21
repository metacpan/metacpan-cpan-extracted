package PAX::Runtime::Value;

our $VERSION = '0.031';

use strict;
use warnings;

sub fast_int {
    my ($class, $value) = @_;
    return bless {
        kind => 'FastValue',
        type => 'int',
        value => 0 + $value,
        escaped => 0,
    }, $class;
}

sub perl_value {
    my ($class, $value) = @_;
    return bless {
        kind => 'PerlValue',
        type => ref($value) || 'scalar',
        value => $value,
        escaped => 1,
    }, $class;
}

sub materialise {
    my ($self) = @_;
    return $self if $self->{kind} eq 'PerlValue';
    return __PACKAGE__->perl_value($self->{value});
}

sub as_hash {
    my ($self) = @_;
    return {
        kind => $self->{kind},
        type => $self->{type},
        value => $self->{value},
        escaped => $self->{escaped} ? 1 : 0,
    };
}

1;

=pod

=head1 NAME

PAX::Runtime::Value - runtime value normalization helper

=head1 SYNOPSIS

  use PAX::Runtime::Value;

  my $result = PAX::Runtime::Value->fast_int(...);

=head1 DESCRIPTION

Provides value-shape helpers used when compiled code and runtime fallback paths need to exchange normalized Perl values.

=head1 METHODS

=head2 fast_int, perl_value, materialise, as_hash

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the runtime value normalization helper logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs runtime value normalization helper. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects runtime value normalization helper, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover runtime value normalization helper.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::Runtime::Value -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
