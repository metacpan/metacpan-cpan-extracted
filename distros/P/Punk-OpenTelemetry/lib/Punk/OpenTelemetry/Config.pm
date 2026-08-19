package Punk::OpenTelemetry::Config;

use 5.010;
use strict;
use warnings;
use Punk::OpenTelemetry ();

our $VERSION = '0.01';

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
authenticates against nothing) - and then never printed. L</diagnostic> emits
the header B<count>, never a value, not even truncated: a token with its first
eight characters shown is a token in the log.

=head1 WHAT IS PARSED

Identity: C<OTEL_SERVICE_NAME>, C<OTEL_RESOURCE_ATTRIBUTES>.

Propagation: C<OTEL_PROPAGATORS>, defaulting to C<tracecontext,baggage> - both
of them, because a deployment that drops baggage loses it silently.

Sampling: C<OTEL_TRACES_SAMPLER>, C<OTEL_TRACES_SAMPLER_ARG>.

Transport: C<OTEL_EXPORTER_OTLP_ENDPOINT>, C<_PROTOCOL>, C<_HEADERS>,
C<_TIMEOUT>, C<_COMPRESSION>, and the per-signal C<_TRACES_>, C<_METRICS_> and
C<_LOGS_> forms of each. The general endpoint has the signal path appended; a
per-signal endpoint is used exactly as given. That asymmetry is the spec's,
and it is the most common thing to get wrong.

Batching: C<OTEL_BSP_*> for spans and C<OTEL_BLRP_*> for log records. Their
schedule delays differ on purpose - 5s and 1s, the spec's numbers - because a
log somebody is watching for is worth sending sooner than a span they will
look at afterwards.

Metrics: C<OTEL_METRIC_EXPORT_INTERVAL>, C<_TIMEOUT>,
C<OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE>,
C<OTEL_METRICS_EXEMPLAR_FILTER>.

Limits: C<OTEL_ATTRIBUTE_COUNT_LIMIT>, C<_VALUE_LENGTH_LIMIT>, and the
C<OTEL_SPAN_*>, C<OTEL_EVENT_*> and C<OTEL_LINK_*> forms.

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
