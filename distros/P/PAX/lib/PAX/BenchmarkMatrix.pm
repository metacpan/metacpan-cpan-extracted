package PAX::BenchmarkMatrix;

our $VERSION = '0.031';

use strict;
use warnings;
use JSON::PP qw(decode_json);
use PAX::Benchmark;
use PAX::Capture;
use PAX::Manifest;

sub new {
    my ($class, %args) = @_;
    return bless {
        manifest_path => $args{manifest_path},
        iterations => $args{iterations} // 1,
        pax_bin => $args{pax_bin},
    }, $class;
}

sub run {
    my ($self) = @_;
    my $manifest = $self->_load_manifest;
    my @classes;
    for my $class (@{ $manifest->{classes} // [] }) {
        my @fixtures;
        for my $fixture (@{ $class->{fixtures} // [] }) {
            push @fixtures, $self->_run_fixture($fixture);
        }
        push @classes, {
            id => $class->{id},
            description => $class->{description},
            metrics => $class->{metrics} // [],
            fixtures => \@fixtures,
        };
    }
    return {
        manifest_path => $self->{manifest_path},
        iterations => $self->{iterations},
        classes => \@classes,
        passed => JSON::PP::true(),
    };
}

sub _run_fixture {
    my ($self, $fixture) = @_;
    my $capture = PAX::Capture->new(mode => 'live')->capture($fixture);
    my $manifest = PAX::Manifest->new(capture => $capture)->to_hash;
    my $benchmark = PAX::Benchmark->new(
        pax_bin => $self->{pax_bin},
        iterations => $self->{iterations},
    )->run_runtime_benchmark($fixture);
    return {
        path => $fixture,
        capture_status => $capture->{status},
        compatibility_level => $manifest->{compatibility}{level},
        fallback_reason => $manifest->{compatibility}{reason},
        benchmark => $benchmark,
    };
}

sub _load_manifest {
    my ($self) = @_;
    open my $fh, '<', $self->{manifest_path} or die "cannot read benchmark matrix $self->{manifest_path}: $!";
    local $/;
    return decode_json(<$fh>);
}

1;

=pod

=head1 NAME

PAX::BenchmarkMatrix - benchmark matrix runner for repeatable performance comparisons

=head1 SYNOPSIS

  use PAX::BenchmarkMatrix;

  my $obj = PAX::BenchmarkMatrix->new(...);
  my $result = $obj->run(...);

=head1 DESCRIPTION

Loads matrix definitions for benchmark runs and normalizes the execution plan used by the benchmarking commands.

=head1 METHODS

=head2 new, run

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the benchmark matrix runner for repeatable performance comparisons logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs benchmark matrix runner for repeatable performance comparisons. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects benchmark matrix runner for repeatable performance comparisons, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover benchmark matrix runner for repeatable performance comparisons.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::BenchmarkMatrix -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
