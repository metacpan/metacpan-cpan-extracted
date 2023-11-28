# An OpenTelemetry Protocol (OTLP) Exporter for Perl

[![Coverage Status][badge]][coveralls]

This is part of an ongoing attempt at implementing the OpenTelemetry standard
in Perl. The distribution in this repository implements an OpenTelemetry
exporter that uses the OpenTelemetry Protocol to send the telemetry data to a
collector. For ways to generate that telemetry data, you should look into the
[OpenTelemetry][api] API distribution (if you are a library author) or the
[OpenTelemetry::SDK][sdk] distribution (if you are an application author).

## What is OpenTelemetry?

[OpenTelemetry][home] is an open source observability framework, providing a
general-purpose API, SDK, and related tools required for the instrumentation
of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector
services to capture distributed traces and metrics from your application. You
can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this distribution fit in?

The telemetry data provided by the API and SDK distributions needs to be sent
and collected somewhere for processing. This distribution provides an OTLP
exporter class that can be used to send telemetry data to a collector that
supports that protocol.

This distribution will be used by the [OpenTelemetry::SDK][sdk] distribution
to send telemetry data (if configured to do so). If you are not writing an
application that will send telemetry data to a collector, then you are
unlikely to need distribution directly.

## How do I get started?

This repository has some optional external dependencies. In particular, it
requires the [API] distribution to work. But more importantly, in order to
export telemetry data using the `http/protobuf` protocol, it requires
`cmake`, a C++ compiler, and the development headers for the `protobuf`
and `protoc` libraries. Note that even if these are not available, this
exporter will continue to work, but it will only be able to export data
using the `http/json` protocol.

Check the documentation of your system for how to install these system
dependencies. Here are some examples for some common Linux distributions:

```
# Debian / Ubuntu
apt install g++ cmake libprotobuf-dev libprotoc-dev

# Arch
pacman -S gcc protobuf
```

You can then install this distribution from CPAN:
```
cpanm OpenTelemetry::Exporter::OTLP
```
or directly from the repository if you want to install a development
version (although note that only the CPAN version is recommended for
production environments):
```
# On a local fork
cd path/to/this/repo
cpanm install .

# Over the net
cpanm https://github.com/jjatria/perl-opentelemetry-exporter-otlp.git
```

Then, if the SDK is configured to use this exporter, the telemetry data it
generates should be exported to the specified endpoint automatically.
OTLP is the default exporter for [OpenTelemetry::SDK][sdk], so unless you've
specifically configured it otherwise, you will start using it automatically.

Please refer to the documentation of that distribution for details on how to
load it and configure it.

## How can I get involved?

We are in the process of setting up an OpenTelemetry-Perl special interest
group (SIG). Until that is set up, you are free to [express your
interest][sig] or join us in IRC on the #io-async channel in irc.perl.org.

## License

The OpenTelemetry::Exporter::OTLP distribution is licensed under the same
terms as Perl itself. See [LICENSE] for more information.

[api]: https://github.com/jjatria/perl-opentelemetry
[sdk]: https://github.com/jjatria/perl-opentelemetry-sdk
[badge]: https://coveralls.io/repos/github/jjatria/perl-opentelemetry-exporter-otlp/badge.svg?branch=main
[coveralls]: https://coveralls.io/github/jjatria/perl-opentelemetry-exporter-otlp?branch=main
[home]: https://opentelemetry.io
[license]: https://github.com/jjatria/perl-opentelemetry-exporter-otlp/blob/main/LICENSE
[sig]: https://github.com/open-telemetry/community/issues/828
