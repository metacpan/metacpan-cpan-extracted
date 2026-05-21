package PAX::Compatibility;

our $VERSION = '0.031';

use strict;
use warnings;
use JSON::PP ();

sub new {
    my ($class, %args) = @_;
    return bless {
        capture => $args{capture} // {},
        baseline_match => $args{baseline_match} ? 1 : 0,
    }, $class;
}

sub report {
    my ($self) = @_;
    my $capture = $self->{capture};
    my $features = $capture->{source_features} // {};
    my @barriers;

    for my $name (sort keys %$features) {
        next if !$features->{$name};
        my $policy = _feature_policy($name);
        push @barriers, {
            feature => $name,
            policy => $policy->{policy},
            reason => $policy->{reason},
        } if $policy->{barrier};
    }

    if (($capture->{status} // '') ne 'ok') {
        return _level('D', 'reference capture failed', 0, \@barriers);
    }

    if (!$self->{baseline_match}) {
        return _level('C', 'runtime is capturable but does not match Perl 5.42.x baseline', 0, \@barriers);
    }

    if (@barriers) {
        return _level('B', 'capturable baseline with dynamic feature barriers', 1, \@barriers);
    }

    return _level('A', 'capturable baseline with no detected dynamic barriers in source scan', 1, \@barriers);
}

sub _level {
    my ($level, $reason, $acceleration_supported, $barriers) = @_;
    return {
        level => $level,
        reason => $reason,
        acceleration_supported => $acceleration_supported ? JSON::PP::true() : JSON::PP::false(),
        barriers => $barriers,
    };
}

sub _feature_policy {
    my ($name) = @_;
    my %policies = (
        string_eval => ['fallback', 'string eval is a runtime compilation boundary'],
        autoload => ['guarded_barrier', 'AUTOLOAD requires guarded method resolution'],
        tie => ['barrier', 'tied variables are semantic barriers by default'],
        overload => ['guarded_barrier', 'overload tables require epoch guards'],
        typeglob => ['guarded_barrier', 'typeglob access requires package shape guards'],
        xs_loader => ['barrier', 'XS is barrier mode unless declared safe'],
        local_dynamic => ['guarded_barrier', 'local dynamic scoping requires deopt state'],
    );
    my $entry = $policies{$name} // ['unknown', 'unknown dynamic feature'];
    return {
        policy => $entry->[0],
        reason => $entry->[1],
        barrier => 1,
    };
}

1;

=pod

=head1 NAME

PAX::Compatibility - compatibility comparator for native-versus-Perl behavior

=head1 SYNOPSIS

  use PAX::Compatibility;

  my $obj = PAX::Compatibility->new(...);
  my $result = $obj->report(...);

=head1 DESCRIPTION

Runs side-by-side comparisons between stock Perl execution and PAX-managed execution so command-level regressions can be explained instead of guessed at.

=head1 METHODS

=head2 new, report

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the compatibility comparator for native-versus-Perl behavior logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs compatibility comparator for native-versus-Perl behavior. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects compatibility comparator for native-versus-Perl behavior, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover compatibility comparator for native-versus-Perl behavior.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::Compatibility -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
