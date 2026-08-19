#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::OpenTelemetry;

# The plugin: the keyword, the precedence it sits on top of, the disabled
# path, and a real request through a real Punk app producing a real span.
#
# Punk is a runtime prerequisite of the plugin but not of the SDK, and a
# checkout is routinely tested beside a Punk that has not been rebuilt yet -
# so this file skips rather than fails when the ABI is not there. That is also
# the shipped behaviour: a missing ABI means there is nothing of that kind to
# instrument.
BEGIN {
    eval { require Punk; 1 }
        or plan skip_all => "Punk is not installed: $@";
}
plan skip_all => "Punk $Punk::VERSION has no pk_abi (need 0.20)"
    unless Punk->can('_abi_ptr');

require Punk::Plugin::OpenTelemetry;

my @OTEL = grep { /^OTEL_/ } keys %ENV;

# Each app gets its own package, because the plugin's state and Punk's
# keywords are both per-application-class - two apps in one package would
# share a tracer and prove nothing.
my $n = 0;
our %PLUGIN_OPTS;

sub build_app {
    my (%opt) = @_;
    my $pkg = 'OTelApp' . ++$n;
    my $env = $opt{env} || {};
    $PLUGIN_OPTS{$pkg} = $opt{plugin} || {};

    # localise the ambient OTEL_* variables AND the ones this app sets: a
    # developer with a collector configured locally must not fail this file,
    # and one app's environment must not leak into the next
    my @keys = do { my %s; grep { !$s{$_}++ } (@OTEL, keys %$env) };
    local @ENV{@keys};
    delete @ENV{@keys};
    @ENV{ keys %$env } = values %$env;

    # THE ORDER OF THE TWO KEYWORDS. Both orders have to mean the same thing,
    # so every case here is built both ways round.
    my $decl = $opt{declare} || '';
    my $plug = "plugin 'OpenTelemetry' => "
             . "\$main::PLUGIN_OPTS{'$pkg'};";
    my $body = $opt{plugin_first} ? "$plug\n$decl" : "$decl\n$plug";

    my $src = qq{
        package $pkg;
        use Punk;
        use Punk::Plugin::OpenTelemetry;
        $body
        get '@{[ $opt{route} || '/users/:id' ]}' => sub { \$_[0]->render(text => 'ok') };
        1;
    };
    eval $src or die "building $pkg: $@";

    # to_app is the compile point - where middleware is constructed, and so
    # where the plugin reads its configuration. That is what makes the order
    # above not matter.
    my $psgi = $pkg->to_app;
    return ($pkg, $psgi);
}

sub state_of { Punk::Plugin::OpenTelemetry->state_for($_[0]) }

# ---- the keyword records, and beats the environment -------------------------
{
    my ($pkg) = build_app(
        env     => { OTEL_SERVICE_NAME => 'from-env',
                     OTEL_EXPORTER_OTLP_ENDPOINT => 'http://env:4318' },
        declare => q{ otel service_name => 'from-keyword'; },
    );
    my $st  = state_of($pkg);
    my $cfg = $st->{config};

    is($cfg->{service_name}, 'from-keyword',
        'the otel keyword beats OTEL_SERVICE_NAME');
    is($cfg->{endpoint}, 'http://env:4318',
        'and the environment still supplies what the keyword did not');
    ok($st->{tracer}, 'a tracer was built');
    ok($st->{installed}, 'and the instrumentation went in');
}

# ---- declaring twice merges rather than replaces -----------------------------
# A base class sets the service name; a subclass adds the endpoint. Replacing
# would silently drop the base class's decision.
{
    my ($pkg) = build_app(declare => q{
        otel service_name => 'layered';
        otel endpoint     => 'http://second:4318';
    });
    my $cfg = state_of($pkg)->{config};
    is($cfg->{service_name}, 'layered', 'the first declaration survives');
    is($cfg->{endpoint}, 'http://second:4318', 'and the second is added');
}

# ---- THE ORDER OF THE KEYWORDS DOES NOT MATTER ------------------------------
# `plugin` before `otel` has to mean the same as `otel` before `plugin`.
# Reading the configuration in register would only work for one of them: an
# `otel` line below the plugin would record into a config that had already
# been read, and the app would export under whatever the environment said
# while the declaration sat in the source looking effective.
{
    my ($first) = build_app(
        plugin_first => 1,
        env          => { OTEL_SERVICE_NAME => 'from-env' },
        declare      => q{ otel service_name => 'declared-after'; },
    );
    is(state_of($first)->{config}{service_name}, 'declared-after',
        'an otel declaration BELOW plugin is still honoured');

    my ($second) = build_app(
        env     => { OTEL_SERVICE_NAME => 'from-env' },
        declare => q{ otel service_name => 'declared-after'; },
    );
    is(state_of($second)->{config}{service_name}, 'declared-after',
        'and above it, identically - the two orders are the same program');
}

# ---- the plugin's own options are the most specific layer -------------------
{
    my ($pkg) = build_app(
        declare => q{ otel service_name => 'keyword'; },
        plugin  => { service_name => 'plugin-call' },
    );
    is(state_of($pkg)->{config}{service_name},
       'plugin-call',
        'plugin OpenTelemetry => {...} beats the keyword: it is the more '
      . 'specific of the two');
}

# ---- OTEL_SDK_DISABLED: inert, not merely quiet -----------------------------
# The point of the escape hatch is that the process stops PAYING for
# telemetry. An SDK that still builds a tracer and throws the spans away has
# not been disabled, it has been made pointless.
{
    my ($pkg, $psgi) = build_app(env => { OTEL_SDK_DISABLED => 'true' });
    my $st = state_of($pkg);

    ok($st->{disabled}, 'the plugin records that it is off');
    ok(!$st->{tracer},   'NO tracer was built');
    ok(!$st->{exporter}, 'no exporter');
    ok(!$st->{meter},    'no meter');
    ok(!$st->{installed},
        'and nothing was installed into the request path at all');
}

# ---- ... and false does not disable it ---------------------------------------
{
    my ($pkg) = build_app(env => { OTEL_SDK_DISABLED => 'false' });
    ok(state_of($pkg)->{tracer},
        'OTEL_SDK_DISABLED=false leaves the SDK ON - under Perl truth the '
      . 'string "false" would have switched it off');
}

# ---- the sampler names -------------------------------------------------------
{
    my %want = (
        always_on                 => 'always_on',
        always_off                => 'always_off',
        parentbased_always_off    => 'always_off',
        parentbased_always_on     => 'parent_ratio',
        traceidratio              => 'parent_ratio',
        parentbased_traceidratio  => 'parent_ratio',
    );
    for my $name (sort keys %want) {
        my ($s) = Punk::Plugin::OpenTelemetry::_sampler({ sampler => $name });
        is($s, $want{$name}, "OTEL_TRACES_SAMPLER=$name maps to $want{$name}");
    }
    my (undef, $r) = Punk::Plugin::OpenTelemetry::_sampler(
        { sampler => 'traceidratio', sampler_arg => '0.05' });
    is($r, 0.05, 'and the sampler argument becomes the ratio');

    my (undef, $bad) = Punk::Plugin::OpenTelemetry::_sampler(
        { sampler => 'traceidratio', sampler_arg => 'half' });
    is($bad, 1.0,
        'an unparseable ratio samples EVERYTHING rather than nothing: '
      . 'too much telemetry is a bill, none is an outage nobody can see');
}

# ---- the boot diagnostic reaches the log ------------------------------------
{
    my @said;
    my ($pkg, $psgi) = build_app(
        declare => q{ otel service_name => 'diagnosed'; },
    );
    # the plugin logs through the app at register time, which has already
    # happened - so assert on the line it produces from the same config
    my $line = Punk::OpenTelemetry::Config::diagnostic(
        state_of($pkg)->{config});
    like($line, qr/service=diagnosed/, 'the diagnostic names the service');
    like($line, qr/enabled/, 'and says it is on');
}

# ---- a live request produces a server span ----------------------------------
# The end-to-end assertion: an ordinary Punk request, through the ordinary
# request path, arriving in the tracer's queue as a span. Nothing here calls
# the tracer directly - if the pk_abi wiring is not live, there is no span.
{
    my ($pkg, $psgi) = build_app(
        declare => q{ otel service_name => 'live'; },
        route   => "/health",
    );
    my $tracer = state_of($pkg)->{tracer};

    my $before = $tracer->queued;
    my $res = eval {
        $psgi->({
            REQUEST_METHOD => 'GET', PATH_INFO => '/health',
            SCRIPT_NAME => '', QUERY_STRING => '', SERVER_NAME => 'localhost',
            SERVER_PORT => 80, 'psgi.url_scheme' => 'http',
            'psgi.input' => undef, 'psgi.errors' => \*STDERR,
        });
    };
    ok($res, 'the request was served') or diag $@;
    cmp_ok($tracer->queued, '>', $before,
        'a span reached the queue - and nothing in this test called the '
      . 'tracer, so the pk_abi wiring is what put it there');

    my $payload = $tracer->drain;
    my $span = $payload->{resource_spans}[0]{scope_spans}[0]{spans}[-1];
    is($span->{attributes}{'http.request.method'}, 'GET', 'the method');
    is($span->{attributes}{'http.route'}, '/health', 'and the route');
    like($span->{name}, qr{^GET /health$},
        'the span name is METHOD plus route, which is what keeps it '
      . 'low-cardinality');

    # the resource travels with it
    my $res_attrs = $payload->{resource_spans}[0]{resource}{attributes};
    is($res_attrs->{'service.name'}, 'live',
        'the configured service name reached the resource');
    ok($res_attrs->{'service.instance.id'}, 'and an instance id');
}

# ---- http.route is the PATTERN, not the path --------------------------------
# The whole reason the route is read from the router rather than from
# PATH_INFO: /users/7 and /users/8 are the same route, and a trace bill that
# treats them as two is a trace bill nobody pays twice.
{
    my ($pkg, $psgi) = build_app(
        declare => q{ otel service_name => 'patterned'; },
        route   => "/users/:id",
    );
    my $tracer = state_of($pkg)->{tracer};

    # Punk's dispatcher reaches for Open::API's C ABI on the dynamic-route
    # path, so a checkout sitting beside a mismatched Open::API cannot serve
    # one at all. That is an environment mismatch rather than anything this
    # dist can assert around.
    my $res = eval {
        $psgi->({
            REQUEST_METHOD => 'GET', PATH_INFO => '/users/7',
            SCRIPT_NAME => '', QUERY_STRING => '', SERVER_NAME => 'localhost',
            SERVER_PORT => 80, 'psgi.url_scheme' => 'http',
            'psgi.input' => undef, 'psgi.errors' => \*STDERR,
        });
    };
    SKIP: {
        skip "this Punk cannot serve a dynamic route here: $@", 2 unless $res;
        my $span = $tracer->drain
            ->{resource_spans}[0]{scope_spans}[0]{spans}[-1];
        is($span->{attributes}{'http.route'}, '/users/:id',
            'http.route is the declared PATTERN, not /users/7');
        unlike($span->{name}, qr/7/, 'and the span name carries no id either');
    }
}

# ---- THE EXPORT ACTUALLY HAPPENS --------------------------------------------
# Producing spans and never draining them is not "telemetry that is not
# configured yet" - it is a bounded queue quietly dropping its oldest entries
# forever, which from the outside looks exactly like a collector that is up
# and receiving nothing. So: does a flush put encoded bytes on the wire.
{
    package MockFuture;
    sub new { bless { res => $_[1] }, $_[0] }
    sub on_ready { my ($s, $cb) = @_; $cb->($s); return $s }
    sub get { $_[0]{res} }

    package MockRes;
    sub new     { bless { status => $_[1] }, $_[0] }
    sub status  { $_[0]{status} }
    sub headers { [] }
    sub content { '' }

    package MockUA;
    sub new     { bless { calls => [] }, shift }
    sub request { my ($s, @a) = @_; push @{ $s->{calls} }, \@a;
                  return MockFuture->new(MockRes->new($s->{status} || 200)) }
    sub loop    { undef }

    package main;

    my $ua = MockUA->new;
    my ($pkg, $psgi) = build_app(
        route  => '/health',
        plugin => { service_name => 'shipped',
                    endpoint     => 'http://collector:4318',
                    ua           => $ua },
    );
    my $st = state_of($pkg);

    $psgi->({
        REQUEST_METHOD => 'GET', PATH_INFO => '/health', SCRIPT_NAME => '',
        QUERY_STRING => '', SERVER_NAME => 'l', SERVER_PORT => 80,
        'psgi.url_scheme' => 'http', 'psgi.input' => undef,
        'psgi.errors' => \*STDERR,
    });
    cmp_ok($st->{tracer}->queued, '>', 0, 'a span is queued');

    Punk::Plugin::OpenTelemetry::flush($st);
    is($st->{tracer}->queued, 0, 'flush emptied the queue');
    ok(scalar @{ $ua->{calls} }, 'and something was actually SENT')
        or diag 'nothing reached the ua';

    my ($method, $url, %opt) = @{ $ua->{calls}[0] };
    is($method, 'POST', 'OTLP/HTTP is a POST');
    is($url, 'http://collector:4318/v1/traces',
        'to the resolved traces endpoint - the signal path is APPENDED to a '
      . 'general endpoint');
    ok(length $opt{body}, 'carrying an encoded body');
    is($st->{exporter}{stats}{exported}, 1,
        'and the 200 was counted as an export');
}

# ---- a flush with nothing to send sends nothing ------------------------------
# The common case by a wide margin, and the one that must not allocate or
# post an empty batch at a collector every few seconds forever.
{
    my $ua = MockUA->new;
    my ($pkg) = build_app(
        plugin => { service_name => 'quiet', endpoint => 'http://c:4318',
                    ua => $ua },
    );
    Punk::Plugin::OpenTelemetry::flush(state_of($pkg));
    is(scalar @{ $ua->{calls} }, 0,
        'an empty queue produces no request at all');
}

# ---- a failing collector does not reach the application ---------------------
{
    my $ua = MockUA->new;
    $ua->{status} = 500;                     # permanent: no retry, but counted
    my ($pkg, $psgi) = build_app(
        route  => '/health',
        plugin => { service_name => 'failing', endpoint => 'http://c:4318',
                    ua => $ua },
    );
    my $st = state_of($pkg);
    $psgi->({
        REQUEST_METHOD => 'GET', PATH_INFO => '/health', SCRIPT_NAME => '',
        QUERY_STRING => '', SERVER_NAME => 'l', SERVER_PORT => 80,
        'psgi.url_scheme' => 'http', 'psgi.input' => undef,
        'psgi.errors' => \*STDERR,
    });
    ok(eval { Punk::Plugin::OpenTelemetry::flush($st); 1 },
        'a collector saying 500 does not throw into the application');
    is($st->{exporter}{stats}{rejected}, 1, 'it is counted as rejected');
    is($st->{exporter}{stats}{dropped}, 1,
        'and as dropped - a telemetry layer that cannot report its own '
      . 'losses is asking to be trusted for no reason');
}

done_testing;
