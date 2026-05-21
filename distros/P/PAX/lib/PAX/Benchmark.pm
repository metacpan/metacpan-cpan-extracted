package PAX::Benchmark;

our $VERSION = '0.031';

use strict;
use warnings;
use JSON::PP ();
use Time::HiRes qw(time);
use PAX::Capture;
use PAX::Manifest;
use PAX::RegionSelector;
use PAX::HIR;
use PAX::GuardedSSA;
use PAX::Tier1;
use PAX::NativeRunner;

sub new {
    my ($class, %args) = @_;
    return bless {
        iterations => $args{iterations} // 3,
        pax_bin => $args{pax_bin},
    }, $class;
}

sub run_capture_benchmark {
    my ($self, $entrypoint) = @_;
    my @samples;
    my $rss_before = _current_rss_kb();
    for (1 .. $self->{iterations}) {
        my $start = time();
        my $capture = eval { PAX::Capture->new(mode => 'live')->capture($entrypoint) };
        my $exit = ($@ || !$capture || ($capture->{status} // '') ne 'ok') ? 1 : 0;
        my $elapsed = time() - $start;
        push @samples, {
            iteration => $_,
            exit => $exit,
            elapsed_seconds => $elapsed,
            rss_kb => _current_rss_kb(),
        };
    }
    my $rss_after = _current_rss_kb();

    my $total = 0;
    $total += $_->{elapsed_seconds} for @samples;
    return {
        entrypoint => $entrypoint,
        benchmark_class => 'capture_overhead',
        iterations => $self->{iterations},
        samples => \@samples,
        mean_seconds => @samples ? $total / @samples : 0,
        warm_up_seconds => @samples ? $samples[0]{elapsed_seconds} : 0,
        fallback_share => 1,
        memory_impact => _memory_impact($rss_before, $rss_after),
    };
}

sub run_runtime_benchmark {
    my ($self, $entrypoint) = @_;
    my $rss_before = _current_rss_kb();
    my $reference = $self->_time_command([$^X, $entrypoint]);
    my $capture = $self->run_capture_benchmark($entrypoint);
    my $native = $self->_time_native($entrypoint);
    my $rss_after = _current_rss_kb();

    return {
        entrypoint => $entrypoint,
        benchmark_class => 'runtime',
        iterations => $self->{iterations},
        reference_mean_seconds => $reference->{mean_seconds},
        capture_mean_seconds => $capture->{mean_seconds},
        native_mean_seconds => $native->{mean_seconds},
        native_available => $native->{available},
        native_result => $native->{result},
        warm_up_seconds => $capture->{warm_up_seconds},
        fallback_share => $native->{available} ? 0 : 1,
        memory_impact => _memory_impact($rss_before, $rss_after),
    };
}

sub _time_command {
    my ($self, $cmd) = @_;
    my @samples;
    for (1 .. $self->{iterations}) {
        my $start = time();
        system(@$cmd);
        push @samples, {
            iteration => $_,
            exit => $? >> 8,
            elapsed_seconds => time() - $start,
            rss_kb => _current_rss_kb(),
        };
    }
    return _summarise(\@samples);
}

sub _time_native {
    my ($self, $entrypoint) = @_;
    my $capture = PAX::Capture->new(mode => 'live')->capture($entrypoint);
    my $manifest = PAX::Manifest->new(capture => $capture)->to_hash;
    my $regions = PAX::RegionSelector->new(manifest => $manifest)->select;
    my $hir = PAX::HIR->new(manifest => $manifest, regions => $regions->{selected})->lower_all;
    my $ssa = PAX::GuardedSSA->new(hir_units => $hir)->build_all;
    my @artifacts = map { PAX::Tier1->new->compile($_) } @$ssa;
    my ($native) = grep { ($_->{entry_kind} // '') eq 'native_i64_leaf' && $_->{executable_path} } @artifacts;
    if (!$native) {
        return {
            available => JSON::PP::false(),
            mean_seconds => undef,
            result => undef,
        };
    }

    my @samples;
    my $result;
    for (1 .. $self->{iterations}) {
        my $start = time();
        $result = PAX::NativeRunner->new->run_i64_binary(
            path => $native->{executable_path},
            left => 10,
            right => 32,
        );
        push @samples, {
            iteration => $_,
            exit => $result->{exit},
            elapsed_seconds => time() - $start,
            rss_kb => _current_rss_kb(),
        };
    }
    my $summary = _summarise(\@samples);
    $summary->{available} = JSON::PP::true();
    $summary->{result} = $result;
    return $summary;
}

sub _summarise {
    my ($samples) = @_;
    my $total = 0;
    $total += $_->{elapsed_seconds} for @$samples;
    return {
        samples => $samples,
        mean_seconds => @$samples ? $total / @$samples : 0,
        warm_up_seconds => @$samples ? $samples->[0]{elapsed_seconds} : 0,
    };
}

sub _current_rss_kb {
    open my $fh, '<', '/proc/self/status' or return undef;
    while (my $line = <$fh>) {
        return 0 + $1 if $line =~ /^VmRSS:\s+(\d+)\s+kB/;
    }
    return undef;
}

sub _memory_impact {
    my ($before, $after) = @_;
    return {
        measured => defined($before) && defined($after) ? JSON::PP::true() : JSON::PP::false(),
        unit => 'KiB',
        before_rss_kb => $before,
        after_rss_kb => $after,
        delta_rss_kb => defined($before) && defined($after) ? $after - $before : undef,
        source => '/proc/self/status VmRSS',
    };
}

1;

__END__

=head1 NAME

PAX::Benchmark - internal benchmark helpers for PAX validation

=head1 SYNOPSIS

  my $bench = PAX::Benchmark->new(iterations => 5);
  my $result = $bench->run_runtime_benchmark(entrypoint => 'bin/app.pl');

=head1 DESCRIPTION

This module measures capture, reference runtime, and native-runtime behavior for
validation gates. Under SOW-03 it calls compiler/runtime modules directly
instead of shelling out to removed public diagnostic CLI commands.

=head1 METHODS

=head2 new

Creates a benchmark runner. C<iterations> controls the number of samples.

=head2 run_capture_benchmark

Runs C<PAX::Capture> directly and records timing plus process memory fields.

=head2 run_runtime_benchmark

Compares stock Perl timing, capture timing, and native execution timing where a
native region can be emitted.

=head1 PURPOSE

This module exists to keep performance comparisons scripted and reproducible so
PAX can measure where a build is faster, slower, or functionally different from
stock Perl.

=cut
