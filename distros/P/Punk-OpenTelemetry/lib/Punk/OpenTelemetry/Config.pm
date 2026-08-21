package Punk::OpenTelemetry::Config;

use 5.010;
use strict;
use warnings;
use Punk::OpenTelemetry ();

our $VERSION = '0.04';

# All of it is C (include/otel_config.h + xs/config.xs).

1;

__END__

=head1 NAME

Punk::OpenTelemetry::Config - the OTEL_* environment surface and precedence

=head1 SYNOPSIS

    my $env = Punk::OpenTelemetry::Config::from_env();

    my $cfg = Punk::OpenTelemetry::Config::resolve(
        \%keyword, $punk_yml_block, $env);      # first wins

    return if Punk::OpenTelemetry::Config::disabled($cfg);

    $log->info(Punk::OpenTelemetry::Config::diagnostic($cfg));

=head1 DESCRIPTION

Nobody configures a telemetry SDK by calling its constructor. They set
environment variables, because that is what their deployment tool sets, and
because the C<OTEL_*> names are the one part of OpenTelemetry that is the same
in every language. An SDK that reads only its own options is one every
operator has to learn separately, which is exactly what the spec's environment
surface exists to prevent.

So: roughly thirty variables, parsed here, once, into a plain hash - and then
merged under whatever the application declared.

=head1 PRECEDENCE

    keyword  >  punk.yml  >  environment  >  default

The spec defines three configuration interfaces (programmatic, environment
variable, declarative file) and says programmatic configuration is the
foundation the others should be built on. It states B<no> precedence between
programmatic and environment configuration. The one precedence rule it gives
concerns the declarative config file: when C<OTEL_EXPERIMENTAL_CONFIG_FILE> is
set, that file takes precedence over the SDK configuration environment
variables.

So this order matches the spec where it speaks and follows its stated
principle where it does not. It is also Punk's own convention.

F<punk.yml>'s C<otel:> block is B<not> the spec's declarative configuration
format, and the two should not be conflated.

=head1 READ ONCE

The environment is read at boot, not per request. Re-reading C<%ENV> in the
request path would be both slower and wrong: a worker that picked up a
mid-flight change would disagree with its siblings, and telemetry that
disagrees about its own configuration is worse than telemetry that is
uniformly stale.

=head1 TWO THINGS THAT MUST NOT GO WRONG

=head2 OTEL_SDK_DISABLED

It has to make the whole thing inert. It is the switch an operator reaches for
at three in the morning, so it is checked before anything is built and before
a single hook is registered.

The value is the B<spec's> boolean, not Perl truth: only C<true>,
case-insensitively. C<OTEL_SDK_DISABLED=false> does not disable the SDK, and
it would under any looser rule.

=head2 OTEL_EXPORTER_OTLP_HEADERS

It carries credentials. Every value is percent-decoded (the spec carries these
in the W3C Baggage encoding, so a token containing a comma or an equals sign
arrives encoded, and one that survives the split but not the decode
authenticates against nothing) - and then never printed.
L<diagnostic|/"diagnostic($config)">
emits the header B<count>, never a value, not even truncated: a token with
its first eight characters shown is a token in the log.

=head1 WHAT IS PARSED

Every name in full, so that looking one up finds it.

=head2 Identity

    OTEL_SERVICE_NAME                     unknown_service, and a warning
    OTEL_RESOURCE_ATTRIBUTES              -

An unnamed service is warned about at boot rather than left to be discovered
on a dashboard, where it is indistinguishable from every other unnamed
service.

=head2 Propagation and sampling

    OTEL_PROPAGATORS                      tracecontext,baggage
    OTEL_TRACES_SAMPLER                   parentbased_always_on
    OTEL_TRACES_SAMPLER_ARG               -

Both propagators by default, because a deployment that drops baggage loses it
silently.

=head2 Transport

    OTEL_EXPORTER_OTLP_ENDPOINT           -   NOTHING IS EXPORTED WITHOUT ONE
    OTEL_EXPORTER_OTLP_PROTOCOL           http/protobuf
    OTEL_EXPORTER_OTLP_COMPRESSION        none
    OTEL_EXPORTER_OTLP_TIMEOUT            10000     ms
    OTEL_EXPORTER_OTLP_HEADERS            -

and the per-signal forms, each overriding the general one for that signal
alone:

    OTEL_EXPORTER_OTLP_TRACES_ENDPOINT       _METRICS_        _LOGS_
    OTEL_EXPORTER_OTLP_TRACES_PROTOCOL       _METRICS_        _LOGS_
    OTEL_EXPORTER_OTLP_TRACES_COMPRESSION    _METRICS_        _LOGS_
    OTEL_EXPORTER_OTLP_TRACES_HEADERS        _METRICS_        _LOGS_

There is B<no default endpoint>, and this SDK does not fall back to
C<http://localhost:4318> the way some others do. With none set the SDK still
builds and still records, and the spans are dropped for want of anywhere to
go. It is the first thing to check when everything looks configured and
nothing arrives.

The general endpoint has the signal path B<appended>; a per-signal endpoint is
used B<exactly> as given. That asymmetry is the spec's, and it is the most
common thing to get wrong - see L<Punk::OpenTelemetry::Exporter/Endpoints>.

=head2 Batching

    OTEL_BSP_SCHEDULE_DELAY               5000      ms
    OTEL_BSP_EXPORT_TIMEOUT              30000      ms
    OTEL_BSP_MAX_QUEUE_SIZE               2048
    OTEL_BSP_MAX_EXPORT_BATCH_SIZE         512

    OTEL_BLRP_SCHEDULE_DELAY              1000      ms
    OTEL_BLRP_EXPORT_TIMEOUT             30000      ms
    OTEL_BLRP_MAX_QUEUE_SIZE              2048
    OTEL_BLRP_MAX_EXPORT_BATCH_SIZE        512

C<BSP> is spans, C<BLRP> is log records. The schedule delays differ on purpose
- 5s and 1s, the spec's numbers - because a log somebody is watching for is
worth sending sooner than a span they will look at afterwards.

=head2 Metrics

    OTEL_METRIC_EXPORT_INTERVAL          60000      ms
    OTEL_METRIC_EXPORT_TIMEOUT           30000      ms
    OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE   cumulative
    OTEL_METRICS_EXEMPLAR_FILTER         trace_based

=head2 Limits

    OTEL_ATTRIBUTE_COUNT_LIMIT             128
    OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT        -      unlimited
    OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT        128
    OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT   -      unlimited
    OTEL_SPAN_EVENT_COUNT_LIMIT            128
    OTEL_SPAN_LINK_COUNT_LIMIT             128
    OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT       128
    OTEL_LINK_ATTRIBUTE_COUNT_LIMIT        128

A length limit of 0 means unlimited, which is why the two length limits are
absent by default rather than set to something enormous.

=head2 The switch

    OTEL_SDK_DISABLED                     unset

See L</OTEL_SDK_DISABLED> above for why only the string C<true> counts.

C<OTEL_EXPERIMENTAL_CONFIG_FILE> is B<not> read. Supporting the spec's
declarative configuration format is separate work; see L</PRECEDENCE> for
where it would sit if it were added.

=head2 Two rules for every value above

A value that is meant to be a number and is not is B<ignored> rather than
taken as zero. C<OTEL_BSP_MAX_QUEUE_SIZE=lots> must not silently become a
queue of nothing, which is indistinguishable from a broken exporter.

An B<empty> value is absent, not empty. C<OTEL_SERVICE_NAME=> in a compose
file means the operator did not set it, and honouring it as a service named
C<""> produces telemetry nothing can find again.

=head1 FUNCTIONS

=head2 from_env

The whole environment surface, as a hashref.

=head2 resolve(@layers)

Merges layers, B<first wins>, so they are written in the order they take
precedence. Undef layers are skipped, so a caller need not test each source.

Merging is one level deep for a hash value, because the sub-hashes here are
namespaces rather than values: an app that sets one per-signal endpoint means
that one, not "and forget what the environment said about the other two". An
array replaces wholesale, because a propagator list is a single decision and
merging two gives an order nobody chose.

=head2 disabled($config)

Whether the SDK is off. Separate from L</from_env> because it is asked before
anything is built, and the answer must not depend on any of it having been
built.

=head2 diagnostic($config)

The boot line: enabled or disabled, service, protocol, endpoint, sampler and
its argument, propagators, and the header count. Almost every OpenTelemetry
support question is answered by those facts, and almost no SDK prints them.

=head1 SEE ALSO

L<Punk::Plugin::OpenTelemetry>, which is what reads this.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
