#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;

# A Punk application with Punk::Plugin::OpenTelemetry: every request is a
# server span, an outbound call is a client span beneath it, and both are
# exported to whatever is listening on OTEL_EXPORTER_OTLP_ENDPOINT.
#
#   plackup -s Hyperman -p 5000 example/app.psgi
#
# Point it at the collector beside this file and watch the spans arrive:
#
#   OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318 \
#   OTEL_EXPORTER_OTLP_PROTOCOL=http/json \
#     plackup -s Hyperman -p 5000 example/app.psgi

use Punk;
use Punk::Plugin::OpenTelemetry;
use Hyperman ();          # the worker loop this example flushes on

# The keyword layer. It wins over punk.yml and over the environment, EXCEPT
# where this example deliberately leaves the endpoint to the environment, so
# the same file runs against a collector, a vendor, or nothing at all.
otel service_name => 'punk-otel-example',
     resource_attributes => { 'deployment.environment' => 'demo' };

plugin 'OpenTelemetry';

# ---- shipping the spans -----------------------------------------------------
#
# There is nothing to write here. The plugin drains the tracer and posts the
# batch itself: on a loop (which is what `plackup -s Hyperman` gives it) that
# is a repeating timer every OTEL_BSP_SCHEDULE_DELAY, so nothing is sent from
# the request path and a collector that is down costs this application
# nothing. With no loop it flushes after a response instead, once there is a
# batch to send or the delay has passed.
#
# Punk::Plugin::OpenTelemetry::flush($state) forces one, which is what a test
# or a shutdown hook wants; ordinary code never calls it.

# ---- the application --------------------------------------------------------

get '/' => sub {
    my ($c) = @_;
    $c->text("try /hello/world, /work, /slow, /boom\n");
};

get '/hello/:name' => sub {
    my ($c) = @_;
    # $c->otel is the tracer. A span started here is a child of the server
    # span the instrumentation already opened for this request.
    # `kind` is the OTLP enum as a NUMBER (1 internal, 2 server, 3 client);
    # internal is the default, so this omits it
    my $span = $c->otel->start('greet');
    if ($span) {                     # undef when the trace was not sampled
        $span->attr('greeting.name' => $c->param('name'));
        $span->event('composed');
        $span->end;
        $c->otel->enqueue($span);
    }
    $c->json({ hello => $c->param('name') });
};

# an outbound call: the client span appears under the server span, and the
# traceparent goes out on the wire so the other side can continue the trace
get '/work' => sub {
    my ($c) = @_;
    my $res = eval { $c->ua->get('http://127.0.0.1:4318/stats')->get };
    $c->json({ called_collector => ($res ? 1 : 0) });
};

get '/slow' => sub {
    my ($c) = @_;
    my $span = $c->otel->start('slow.thing');
    select undef, undef, undef, 0.25;
    if ($span) { $span->end; $c->otel->enqueue($span) }
    $c->text("that took a moment\n");
};

# a handler that dies: the server span is still ended, and still exported,
# carrying the error. Telemetry that only survives the happy path is telemetry
# you cannot use on the day you need it.
get '/boom' => sub { die "the demo exploded on purpose\n" };

__PACKAGE__->to_app;
