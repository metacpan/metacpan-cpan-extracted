# An OpenTelemetry SDK for Perl

[![Coverage Status][badge]][coveralls]

This is part of an ongoing attempt at implementing the OpenTelemetry standard
in Perl. The distribution in this repository implements the OpenTelemetry SDK,
which would allow an application can collect, analyze, and export telemetry
data. Currently only distributed traces are supported, but work on metrics and
logs should come next.

## What is OpenTelemetry?

[OpenTelemetry][home] is an open source observability framework, providing a
general-purpose API, SDK, and related tools required for the instrumentation
of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector
services to capture distributed traces and metrics from your application. You
can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this distribution fit in?

This distribution provides the reference implementation of the OpenTelemetry
Perl interfaces currently defined in the experimental [OpenTelemetry][api]
distribution. That is, it includes the *functionality* needed to collect,
analyze, and export telemetry data produced using the API.

Generally, Perl *applications* should install this distribution (or other
concrete implementation of the OpenTelemetry API). Using the SDK, an
application can configure how it wants telemetry data to be handled,
including which data should be persisted, how it should be formatted, and
where it should be recorded or exported. However, *libraries* that produce
telemetry data should generally depend only on [OpenTelemetry][api],
deferring the choice of concrete implementation to the application developer.

## How do I get started?

Install this distribution from CPAN:
```
cpanm OpenTelemetry::SDK
```
or directly from the repository if you want to install a development
version (although note that only the CPAN version is recommended for
production environments):
```
# On a local fork
cd path/to/this/repo
cpanm install .

# Over the net
cpanm https://github.com/jjatria/perl-opentelemetry-sdk.git
```

Then, configure the SDK according to your desired handling of telemetry data,
and use the OpenTelemetry interfaces to produces traces and other information.
Following is a basic example (although bear in mind this interface is still
being drafted, so some details might still change):

``` perl
# Importing the SDK will configure it with default export and context
# propagation formats.
use OpenTelemetry::SDK;

# Many configuration options may be set via the environment. To use them,
# set the appropriate variable before you import the SDK. For example:
#
# require OpenTelemetry::SDK;
#
# $ENV{OTEL_TRACES_EXPORTER} = 'console';
# $ENV{OTEL_PROPAGATORS}     = 'ottrace';
# OpenTelemetry::SDK->import;
#
# You can also use instrumentation libraries to automatically enable telemetry
# for specific code:
#
# use OpenTelemetry::Integration 'HTTP::Tiny';
#
# Or configure the SDK programmatically, if your use case requires it:
#
# OpenTelemetry->tracer_provider->add_span_processor(
#     OpenTelemetry::SDK::Trace::Span::Processor::Simple->new(
#         exporter => OpenTelemetry::SDK::Exporter::Console->new
#     ),
# );
#
# Note that the Simple span exporter is not recommended for use in production.

# To start a trace you need to get a Tracer from the TracerProvider
my $tracer = OpenTelemetry->tracer_provider->tracer(
    name    => 'my_app_or_module',
    version => '0.1.0',
);

# Create a span
$tracer->in_span( foo => sub ( $span, $ ) {
    # Set an attribute
    $span->set_attribute(  platform => 'osx' );
    # Add an event
    $span->add_event('event in bar');
    # Create bar as child of foo
    $tracer->in_span( bar => sub { $child_span, $ ) {
        # Inspect the span
        p $child_span;
    })
});
```

Additional examples will be added as development progresses. Make sure to
check again soon, or try your hand at submitting some of your own.

## How can I get involved?

We are in the process of setting up an OpenTelemetry-Perl special interest
group (SIG). Until that is set up, you are free to [express your
interest][sig] or join us in IRC on the #io-async channel in irc.perl.org.

## License

The OpenTelemetry::SDK distribution is licensed under the Artistic License 2.0.
See [LICENSE] for more information.

[api]: https://github.com/jjatria/perl-opentelemetry
[badge]: https://coveralls.io/repos/github/jjatria/perl-opentelemetry-sdk/badge.svg?branch=main
[coveralls]: https://coveralls.io/github/jjatria/perl-opentelemetry-sdk?branch=main
[home]: https://opentelemetry.io
[license]: https://github.com/jjatria/perl-opentelemetry-sdk/blob/main/LICENSE
[sig]: https://github.com/open-telemetry/community/issues/828
