package PAX::RegionSelector;

our $VERSION = '0.031';

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless {
        manifest => $args{manifest},
    }, $class;
}

sub select {
    my ($self) = @_;
    my $manifest = $self->{manifest} // {};
    my $subs = $manifest->{optree_units}{subs} // [];
    my @regions;
    my @rejections;
    my $index = 0;

    for my $sub (@$subs) {
        my $name = $sub->{name} // next;
        next if $name =~ /^(main::BEGIN|main::UNITCHECK|main::CHECK|main::INIT)$/;
        next if !_is_application_sub($manifest, $sub);

        if (!$sub->{available}) {
            push @rejections, _reject($name, 'optree_unavailable', $sub->{reason});
            next;
        }

        my $kind = _classify_sub($name);
        my $support = _support_level($manifest, $kind);
        my $id = sprintf 'region-%04d', ++$index;
        push @regions, {
            id => $id,
            name => $name,
            kind => $kind,
            support_level => $support->{level},
            reason => $support->{reason},
            source => {
                entrypoint => $manifest->{source_entrypoint},
                root_class => $sub->{root_class},
                start_class => $sub->{start_class},
                optree_ops => $sub->{optree_ops} // [],
                native_shape => $sub->{native_shape},
            },
            required_epochs => [qw(package_symbols method_resolution loaded_modules)],
            lowering_status => $support->{level} eq 'fallback' ? 'blocked' : 'ready',
        };
    }

    return {
        selected => \@regions,
        rejected => \@rejections,
    };
}

sub _classify_sub {
    my ($name) = @_;
    return 'compile_phase_hook' if $name =~ /::(?:BEGIN|UNITCHECK|CHECK|INIT)$/;
    return 'candidate_leaf_function';
}

sub _is_application_sub {
    my ($manifest, $sub) = @_;
    my $name = $sub->{name} // '';
    my $file = $sub->{closure_descriptor}{file} // '';
    return 0 if $name =~ /^main::_/;
    return 0 if $name =~ /^main::(?:encode_json|decode_json|svref_2object)$/;
    return 1 if $name =~ /^main::/;
    return 1 if $name =~ /^PAX::Fixture::/;
    return 0 if !$file || $file eq '-';
    return 0 if $file !~ /\.(?:pm|pl)\z/;
    return 1 if $sub->{native_shape};
    return 0 if $file =~ m{\A(?:/usr|/System/|[A-Za-z]:/Strawberry/perl/)};
    return 1 if ($manifest->{source_entrypoint} // '') ne '' && $file eq $manifest->{source_entrypoint};
    return 1 if $file !~ m{\A/};
    return 0;
}

sub _support_level {
    my ($manifest, $kind) = @_;
    if (!$manifest->{runtime}{baseline_match}) {
        return {
            level => 'guarded',
            reason => 'runtime baseline mismatch requires guarded portable native packaging',
        };
    }
    return {
        level => 'guarded',
        reason => "$kind can enter HIR with runtime guards",
    };
}

sub _reject {
    my ($name, $code, $detail) = @_;
    return {
        name => $name,
        code => $code,
        detail => defined $detail ? $detail : '',
    };
}

1;

=pod

=head1 NAME

PAX::RegionSelector - candidate region selector

=head1 SYNOPSIS

  use PAX::RegionSelector;

  my $obj = PAX::RegionSelector->new(...);
  my $result = $obj->select(...);

=head1 DESCRIPTION

Chooses which captured regions are worth lowering or promoting based on shape, profile, and safety heuristics.

=head1 METHODS

=head2 new, select

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the candidate region selector logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs candidate region selector. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects candidate region selector, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover candidate region selector.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::RegionSelector -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
