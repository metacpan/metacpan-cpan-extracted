package OpenTelemetry::SDK;
# ABSTRACT: An implementation of the OpenTelemetry SDK for Perl

our $VERSION = '0.028';

use strict;
use warnings;
use experimental 'signatures';
use feature 'state';

use Feature::Compat::Try;
use Module::Runtime;
use OpenTelemetry::Common 'config';
use OpenTelemetry::Propagator::Composite;
use OpenTelemetry::SDK::Trace::TracerProvider;
use OpenTelemetry::X;
use OpenTelemetry;
use Ref::Util 'is_coderef';
use Scalar::Util 'blessed';

use isa 'OpenTelemetry::X';

sub configure_propagators ($, @args) {
    my $logger = OpenTelemetry::Common::internal_logger;

    state %map = (
        b3           => 'B3',
        b3multi      => 'B3::Multi',
        baggage      => 'Baggage',
        jaeger       => 'Jaeger',
        none         => 'None',
        ottrace      => 'OTTrace',
        tracecontext => 'TraceContext',
        xray         => 'XRay',
    );

    push @args, split ',',
        ( config('PROPAGATORS') // 'tracecontext,baggage' ) =~ s/\s//gr
        unless @args;

    my ( %seen, @propagators );
    for my $candidate ( grep !!$_, @args ) {
        if ( blessed $candidate ) {
            if ( $candidate->DOES('OpenTelemetry::Propagator') ) {
                push @propagators, $candidate;
            }
            else {
                $logger->warnf("Attempted to configure a '%s' propagator, but it does not do the OpenTelemetry::Propagator role", ref $candidate );
            }
            next;
        }

        my $suffix = $map{$candidate};
        unless ($suffix) {
            $logger->warn("Unknown propagator '$candidate' cannot be configured");
            next;
        }

        next if $seen{$suffix}++;

        my $class = 'OpenTelemetry::Propagator::' . $suffix;

        try {
            Module::Runtime::require_module $class;
            push @propagators, $class->new;
        }
        catch ($e) {
            die OpenTelemetry::X->create(
                Invalid => "Error configuring '$candidate' propagator: $e",
            );
        }
    }

    # If we have no good ones, keep the default
    return OpenTelemetry->propagator unless @propagators;

    # If we have only one good one, set that one as the global one
    return OpenTelemetry->propagator = shift @propagators if @propagators == 1;

    # If we have multiple good ones, wrap them in a composite
    OpenTelemetry->propagator
        = OpenTelemetry::Propagator::Composite->new(@propagators),
}

sub configure_tracer_provider ($, $provider = undef, @) {
    my $logger = OpenTelemetry::Common::internal_logger;

    state %map = (
        jaeger  => '::Jaeger',
        otlp    => '::OTLP::Traces',
        zipkin  => '::Zipkin',
        console => 'OpenTelemetry::SDK::Exporter::Console',
    );

    my @names = split ',',
        ( config('TRACES_EXPORTER') // 'otlp' ) =~ s/\s//gr;

    if ($provider) {
        if ( ! blessed $provider ) {
            $logger->warnf('Attempted to configure a tracer provider that was not a blessed reference: %s', $provider );
            undef $provider;
        }
        elsif (
            !$provider->can('tracer')
         || !$provider->can('add_span_processor')
         || !$provider->can('shutdown')
         || !$provider->can('force_flush')
        ) {
            $logger->warnf("Attempted to configure a '%s' tracer provider, but it does not implement the OpenTelemetry::SDK::Trace::TracerProvider interface", ref $provider );
            undef $provider;
        }
    }

    $provider //= OpenTelemetry::SDK::Trace::TracerProvider->new;

    my %seen;
    for my $name ( @names ) {
        next if $name eq 'none';

        unless ( $map{$name} ) {
            $logger->warnf("Unknown exporter '%s' cannot be configured", $name);
            next;
        }

        next if $seen{ $map{$name} }++;

        my $exporter = $map{$name} =~ /^::/
            ? ( 'OpenTelemetry::Exporter' . $map{$name} )
            : $map{$name};

        my $processor = 'OpenTelemetry::SDK::Trace::Span::Processor::'
            . ( $name eq 'console' ? 'Simple' : 'Batch' );

        try {
            Module::Runtime::require_module $exporter;
            Module::Runtime::require_module $processor;

            $provider->add_span_processor(
                $processor->new( exporter => $exporter->new )
            );
        }
        catch ($e) {
            die OpenTelemetry::X->create(
                Invalid => "Error configuring '$name' span processor: $e",
            );
        }
    }

    OpenTelemetry->tracer_provider = $provider;
}

sub import ( $class ) {
    return if config('SDK_DISABLED');

    try {
        # TODO: logger
        # TODO: error_handler

        configure_propagators(1);
        configure_tracer_provider(1);
    }
    catch ($e) {
        die $e if isa_OpenTelemetry_X $e;
        die OpenTelemetry::X->create(
            Invalid => "Unexpected error initialising OpenTelemetry::SDK: $e",
        );
    }
}

1;
