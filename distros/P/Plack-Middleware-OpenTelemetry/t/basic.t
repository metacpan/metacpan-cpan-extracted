use strict;
use warnings;
use Test::More;
use Plack;    # to load Plack::VERSION
use Plack::Builder;

BEGIN {
    $ENV{OTEL_TRACES_EXPORTER} = 'console';
}
use OpenTelemetry::SDK;

sub build_handler {
    my @args = @_;
    builder {
        enable "Plack::Middleware::OpenTelemetry", @args;
        sub {
            my $env = shift;

            my $tracer = OpenTelemetry->tracer_provider->tracer;

            my $span    = $tracer->create_span(name => "basic.t");
            my $span_id = $span->context->hex_trace_id;

            # warn "span_id: ", $span_id;
            ok($span_id, "got span id");
            unlike($span_id, qr/^00000/, "got valid span id");
            return [200, [], "Ok"];
        };
    };
}

my $env = {
    REQUEST_METHOD    => 'GET',
    'psgi.url_scheme' => 'http',
    HTTP_HOST         => 'example.com',
    REQUEST_URI       => '/test',
};

build_handler()->($env);

done_testing();
