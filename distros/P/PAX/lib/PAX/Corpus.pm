package PAX::Corpus;

our $VERSION = '0.031';

use strict;
use warnings;
use JSON::PP qw(decode_json);
use PAX::Capture;
use PAX::Manifest;

sub new {
    my ($class, %args) = @_;
    return bless {
        manifest_path => $args{manifest_path},
    }, $class;
}

sub run {
    my ($self) = @_;
    my $manifest = $self->_load_manifest;
    my @results;
    my %levels;

    for my $case (@{ $manifest->{cases} // [] }) {
        my $capture = PAX::Capture->new(mode => $case->{mode} // 'live')->capture($case->{path});
        my $pax_manifest = PAX::Manifest->new(capture => $capture)->to_hash;
        my $level = $pax_manifest->{compatibility}{level};
        my $expected = $pax_manifest->{runtime}{baseline_match}
            ? $case->{expected_level}
            : ($case->{expected_level_when_baseline_mismatch} // $case->{expected_level});
        $levels{$level}++;
        push @results, {
            id => $case->{id},
            path => $case->{path},
            expected_level => $expected,
            actual_level => $level,
            passed => (!defined $expected || $expected eq $level) ? JSON::PP::true() : JSON::PP::false(),
            reason => $pax_manifest->{compatibility}{reason},
            barriers => $pax_manifest->{compatibility}{barriers} // [],
            diagnostics => $pax_manifest->{diagnostics} // [],
        };
    }

    my $failed = grep { !$_->{passed} } @results;
    return {
        manifest_path => $self->{manifest_path},
        total => scalar @results,
        failed => $failed,
        passed => $failed ? JSON::PP::false() : JSON::PP::true(),
        levels => \%levels,
        results => \@results,
    };
}

sub _load_manifest {
    my ($self) = @_;
    open my $fh, '<', $self->{manifest_path} or die "cannot read corpus manifest $self->{manifest_path}: $!";
    local $/;
    return decode_json(<$fh>);
}

1;

=pod

=head1 NAME

PAX::Corpus - corpus runner for grouped validation workloads

=head1 SYNOPSIS

  use PAX::Corpus;

  my $obj = PAX::Corpus->new(...);
  my $result = $obj->run(...);

=head1 DESCRIPTION

Normalizes corpus manifests and drives repeated validation across many sample programs or scenarios.

=head1 METHODS

=head2 new, run

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the corpus runner for grouped validation workloads logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs corpus runner for grouped validation workloads. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects corpus runner for grouped validation workloads, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover corpus runner for grouped validation workloads.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::Corpus -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
