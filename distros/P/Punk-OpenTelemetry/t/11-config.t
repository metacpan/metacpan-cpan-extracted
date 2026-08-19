#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::OpenTelemetry;
use Punk::OpenTelemetry::Config;

# The OTEL_* environment surface, the precedence merge, and the boot line.

# Every test sets the environment it means and nothing else, because the
# suite's own environment may well have OTEL_* variables in it - a developer
# with a collector running locally must not fail this file.
my @OTEL = grep { /^OTEL_/ } keys %ENV;

sub with_env {
    my ($env, $cb) = @_;
    my @keys = do { my %s; grep { !$s{$_}++ } (@OTEL, keys %$env) };
    local @ENV{@keys};
    delete @ENV{@keys};
    @ENV{ keys %$env } = values %$env;
    return $cb->(Punk::OpenTelemetry::Config::from_env());
}

# ---- defaults ----------------------------------------------------------------
# The defaults are the spec's, and they are asserted because "what happens
# when nothing is set" is the configuration almost every deployment runs.
{
    my $c = with_env({}, sub { $_[0] });
    ok(!$c->{disabled}, 'enabled by default');
    is($c->{protocol}, 'http/protobuf', 'the default protocol');
    is($c->{compression}, 'none', 'no compression by default');
    is($c->{timeout}, 10000, 'the 10s default timeout, in ms');
    is($c->{sampler}, 'parentbased_always_on', 'the default sampler');
    is_deeply($c->{propagators}, [qw(tracecontext baggage)],
        'BOTH default propagators - a deployment that drops baggage loses it '
      . 'silently');

    is($c->{bsp}{schedule_delay}, 5000, 'BSP schedule delay');
    is($c->{bsp}{max_queue_size}, 2048, 'BSP queue size');
    is($c->{bsp}{max_export_batch_size}, 512, 'BSP batch size');
    is($c->{blrp}{schedule_delay}, 1000,
        'the LOG processor flushes at 1s, not the span processor 5s - '
      . 'different on purpose');

    is($c->{metric_export_interval}, 60000, 'metric export interval');
    is($c->{temporality_preference}, 'cumulative', 'temporality preference');
    is($c->{exemplar_filter}, 'trace_based', 'exemplar filter');
    is($c->{attribute_count_limit}, 128, 'attribute count limit');
    is($c->{span_event_count_limit}, 128, 'span event count limit');
    ok(!exists $c->{attribute_value_length_limit},
        'the length limit is ABSENT rather than a huge number: unlimited is '
      . 'not a number');
    ok(!exists $c->{service_name}, 'and no service name is invented');
}

# ---- OTEL_SDK_DISABLED -------------------------------------------------------
# The switch an operator reaches for at 3am. It is the spec's boolean, not
# Perl truth.
{
    for my $v (qw(true TRUE True)) {
        my $c = with_env({ OTEL_SDK_DISABLED => $v }, sub { $_[0] });
        ok(Punk::OpenTelemetry::Config::disabled($c), "$v disables the SDK");
    }
    for my $v (qw(false FALSE 0 no off yes 1)) {
        my $c = with_env({ OTEL_SDK_DISABLED => $v }, sub { $_[0] });
        ok(!Punk::OpenTelemetry::Config::disabled($c),
            "'$v' does NOT disable it");
    }
    # '1' and 'yes' above are the point: under Perl truth they would disable
    # the SDK, and an operator who wrote OTEL_SDK_DISABLED=false would find
    # telemetry switched off by the value they used to switch it on.
}

# ---- an empty value is absent, not empty -------------------------------------
{
    my $c = with_env({ OTEL_SERVICE_NAME => '' }, sub { $_[0] });
    ok(!exists $c->{service_name},
        'OTEL_SERVICE_NAME= means unset, not a service named ""');
}

# ---- a number that is not a number -------------------------------------------
{
    my $c = with_env({ OTEL_BSP_MAX_QUEUE_SIZE => 'lots',
                       OTEL_BSP_SCHEDULE_DELAY => '2500' }, sub { $_[0] });
    is($c->{bsp}{max_queue_size}, 2048,
        'an unparseable number keeps the DEFAULT rather than becoming zero - '
      . 'a queue of nothing is indistinguishable from a broken exporter');
    is($c->{bsp}{schedule_delay}, 2500, 'and a real one is taken');

    my $n = with_env({ OTEL_BSP_MAX_QUEUE_SIZE => '12abc' }, sub { $_[0] });
    is($n->{bsp}{max_queue_size}, 2048, 'and a trailing-garbage number too');
}

# ---- lists -------------------------------------------------------------------
{
    my $c = with_env({ OTEL_PROPAGATORS => ' tracecontext , b3 ,,jaeger ' },
                     sub { $_[0] });
    is_deeply($c->{propagators}, [qw(tracecontext b3 jaeger)],
        'a list is split on comma, trimmed, and empty items dropped');
}

# ---- resource attributes -----------------------------------------------------
{
    my $c = with_env({ OTEL_RESOURCE_ATTRIBUTES =>
                       'deployment.environment=prod, service.version=1.2.3' },
                     sub { $_[0] });
    is($c->{resource_attributes}{'deployment.environment'}, 'prod',
        'resource attributes are key=value pairs');
    is($c->{resource_attributes}{'service.version'}, '1.2.3', 'and the second');
}

# ---- headers: percent decoding, and never being printed ----------------------
{
    my $c = with_env({ OTEL_EXPORTER_OTLP_HEADERS =>
                       'api-key=s3cr%2Bet%2Ftoken,x-tenant=acme' },
                     sub { $_[0] });
    is($c->{headers}{'api-key'}, 's3cr+et/token',
        'header values are percent-decoded - the spec carries them in the '
      . 'baggage encoding, and a token that survives the split but not the '
      . 'decode authenticates against nothing');
    is($c->{headers}{'x-tenant'}, 'acme', 'and one needing no decoding');

    my $line = Punk::OpenTelemetry::Config::diagnostic($c);
    unlike($line, qr/s3cr/, 'THE DIAGNOSTIC DOES NOT PRINT THE TOKEN');
    unlike($line, qr/api-key/, 'nor the header name');
    like($line, qr/headers=2/,
        'it prints the COUNT, which answers "did my credentials arrive" '
      . 'without answering anything else');

    # per-signal headers are counted too, and equally not printed
    my $p = with_env({ OTEL_EXPORTER_OTLP_TRACES_HEADERS => 'a=1,b=2',
                       OTEL_EXPORTER_OTLP_HEADERS        => 'c=3' },
                     sub { $_[0] });
    is($p->{signal_headers}{traces}{a}, '1', 'per-signal headers are parsed');
    like(Punk::OpenTelemetry::Config::diagnostic($p), qr/headers=3/,
        'and counted alongside the general ones');
}

# ---- the endpoint asymmetry --------------------------------------------------
{
    my $c = with_env({ OTEL_EXPORTER_OTLP_ENDPOINT => 'http://collector:4318',
                       OTEL_EXPORTER_OTLP_TRACES_ENDPOINT =>
                           'https://ingest.example/v1/traces' },
                     sub { $_[0] });
    is($c->{endpoint}, 'http://collector:4318', 'the general endpoint');
    is($c->{endpoints}{traces}, 'https://ingest.example/v1/traces',
        'and the per-signal one, kept separate - the general form has the '
      . 'signal path APPENDED and the per-signal form is used exactly');
    ok(!exists $c->{endpoints}{metrics}, 'an unset per-signal key is absent');
}

# ---- the diagnostic ----------------------------------------------------------
{
    my $c = with_env({ OTEL_SERVICE_NAME => 'checkout',
                       OTEL_EXPORTER_OTLP_ENDPOINT => 'http://c:4318',
                       OTEL_TRACES_SAMPLER => 'traceidratio',
                       OTEL_TRACES_SAMPLER_ARG => '0.05' }, sub { $_[0] });
    my $line = Punk::OpenTelemetry::Config::diagnostic($c);
    like($line, qr/enabled/,                  'says it is on');
    like($line, qr/service=checkout/,         'the service name');
    like($line, qr{endpoint=http://c:4318},   'the endpoint');
    like($line, qr/protocol=http\/protobuf/,  'the protocol');
    like($line, qr/sampler=traceidratio:0\.05/,
        'the sampler AND its argument - "is it sampling" and "at what rate" '
      . 'are different questions');
    like($line, qr/propagators=tracecontext,baggage/, 'the propagators');
    unlike($line, qr/\n/, 'one line, so it does not bury the rest of the boot');

    my $off = with_env({ OTEL_SDK_DISABLED => 'true' }, sub { $_[0] });
    like(Punk::OpenTelemetry::Config::diagnostic($off),
        qr/disabled \(OTEL_SDK_DISABLED\)/,
        'and when it is off it says WHY, naming the variable that did it');
}

# ---- precedence --------------------------------------------------------------
# keyword > punk.yml > environment > default.
{
    my $env = with_env({ OTEL_SERVICE_NAME => 'from-env',
                         OTEL_EXPORTER_OTLP_ENDPOINT => 'http://env:4318',
                         OTEL_TRACES_SAMPLER => 'always_off' }, sub { $_[0] });
    my $file = { service_name => 'from-yml', sampler => 'always_on' };
    my $kw   = { service_name => 'from-keyword' };

    my $c = Punk::OpenTelemetry::Config::resolve($kw, $file, $env);
    is($c->{service_name}, 'from-keyword', 'the keyword beats punk.yml');
    is($c->{sampler}, 'always_on',        'punk.yml beats the environment');
    is($c->{endpoint}, 'http://env:4318',
        'and the environment supplies what neither declared');
    is($c->{protocol}, 'http/protobuf', 'defaults survive all of it');

    # an undef layer is skipped rather than being an error, so a caller does
    # not have to test each source before passing it
    my $u = Punk::OpenTelemetry::Config::resolve($kw, undef, $env);
    is($u->{service_name}, 'from-keyword', 'an undef layer is skipped');
}

# ---- merging is one level deep, and arrays replace ---------------------------
{
    my $env = with_env({ OTEL_BSP_MAX_QUEUE_SIZE => '4096',
                         OTEL_BSP_SCHEDULE_DELAY => '7000',
                         OTEL_PROPAGATORS => 'tracecontext,baggage,b3' },
                       sub { $_[0] });
    my $c = Punk::OpenTelemetry::Config::resolve(
        { bsp => { max_queue_size => 99 }, propagators => ['jaeger'] },
        undef, $env);

    is($c->{bsp}{max_queue_size}, 99, 'a sub-hash key is overridden');
    is($c->{bsp}{schedule_delay}, 7000,
        'and its SIBLINGS survive - setting one per-signal value does not '
      . 'mean forgetting what the environment said about the others');
    is_deeply($c->{propagators}, ['jaeger'],
        'but an ARRAY replaces wholesale: a propagator list is one decision, '
      . 'and merging two gives an order nobody chose');
}

done_testing;
