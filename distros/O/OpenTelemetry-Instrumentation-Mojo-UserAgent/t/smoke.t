use Mojo::Base -strict;

# The poll reactor is required: with Mojo::Reactor::EV (the default
# when EV is installed), assigning the global tracer provider
# deadlocks in the Mutex that guards it
BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;

BEGIN {
  plan skip_all => 'OpenTelemetry::Instrumentation::Mojo::UserAgent required for this test!'
    unless eval { require OpenTelemetry::Instrumentation::Mojo::UserAgent; 1 };
}

use Mojo::IOLoop;
use OpenTelemetry;
use OpenTelemetry::Constants -span;
use OpenTelemetry::Context;
use OpenTelemetry::Exporter;
use OpenTelemetry::SDK;
use OpenTelemetry::SDK::Trace::Span::Processor::Simple;
use OpenTelemetry::SDK::Trace::TracerProvider;
use OpenTelemetry::Trace;

use Object::Pad;

# Collects every span the SDK exports, so that the tests can inspect
# them without having to mock anything
class TestSink :does(OpenTelemetry::Exporter) {
  field @spans;
  method export ($spans) { push @spans, @$spans }
  method shutdown ( $timeout = undef ) { }
  method force_flush ( $timeout = undef ) { }
  method spans () { @spans }
  method clear () { @spans = () }
}

use Mojolicious::Lite;

# Echo the traceparent we received, so that tests can check what the
# client actually sent on the wire
any '/echo' => sub {
  my $c = shift;
  $c->render(text => $c->req->headers->header('traceparent') // 'none');
};

use Test::Mojo;

# Route every span into our in-memory sink
my $sink    = TestSink->new;
my $provider = OpenTelemetry::SDK::Trace::TracerProvider->new;
$provider->add_span_processor(
  OpenTelemetry::SDK::Trace::Span::Processor::Simple->new(exporter => $sink));
OpenTelemetry->tracer_provider = $provider;

my $t = Test::Mojo->new;
$t->app->log->level('fatal');

# Warm up the test server to learn the port it listens on
$t->get_ok('/echo')->status_is(200);
my $port = $t->tx->req->url->port;
my $base = "http://127.0.0.1:$port";
my $CLASS = 'OpenTelemetry::Instrumentation::Mojo::UserAgent';

# Instrument every user agent from here on
ok $CLASS->install, 'instrumentation installed';

# Blocking request, with propagation
$t->get_ok("$base/echo")->status_is(200)
  ->content_like(qr/^00-[0-9a-f]{32}-[0-9a-f]{16}-0[01]$/, 'propagation data was sent');

my ($span) = $sink->spans;
ok $span, 'span was exported';
is $span->name, 'GET', 'span is named after the request method';
is $span->kind, SPAN_KIND_CLIENT, 'span is a client span';
is $span->instrumentation_scope->name, 'OpenTelemetry::Instrumentation::Mojo::UserAgent',
  'span reports the right instrumentation scope';
is   $span->attributes->{'http.request.method'}, 'GET', 'right request method';
is   $span->attributes->{'server.address'}, '127.0.0.1', 'right server address';
is   $span->attributes->{'server.port'}, $port, 'right server port';
is   $span->attributes->{'url.full'}, "$base/echo", 'right full url';
is   $span->attributes->{'http.response.status_code'}, 200, 'right response status code';
ok   $span->status->is_unset, 'successful requests leave the status unset';
ok   $span->end_timestamp, 'span was ended';
my ($trace_id) = $t->tx->res->text =~ /^00-([0-9a-f]{32})-/;
is   $trace_id, $span->hex_trace_id, 'propagated trace id matches the span';

# Userinfo in the url does not leak into the span
$t->post_ok("http://user:secret\@127.0.0.1:$port/echo" => {'Content-Type' => 'text/plain'} => 'whatever')
  ->status_is(200);
$span = ($sink->spans)[-1];
is $span->name, 'POST', 'span is named after the request method';
is $span->attributes->{'url.full'}, "$base/echo", 'userinfo does not leak into url.full';
is $span->attributes->{'http.request.body.size'}, 8, 'right request body size';

# Error responses are recorded on the span
$t->get_ok('/missing')->status_is(404);
$span = ($sink->spans)[-1];
is $span->attributes->{'http.response.status_code'}, 404, 'right response status code';
is $span->status->code, SPAN_STATUS_ERROR, 'error status for 4xx';
is $span->status->description, 404, 'status description is the status code';
ok $span->end_timestamp, 'span was ended';

# Non-blocking requests. The span is only exported once it ends,
# which happens after the callback returns, so while in the callback
# we can only see it through the restored context
my ($done, $nb_span_id, $recording_in_cb);
my $prev = scalar $sink->spans;
$t->ua->get('/echo' => sub {
  my ($ua, $tx) = @_;
  $done            = $tx->res->code;
  my $ctx_span     = OpenTelemetry::Trace->span_from_context(OpenTelemetry::Context->current);
  $nb_span_id      = $ctx_span->context->hex_span_id;
  $recording_in_cb = $ctx_span->recording;
  Mojo::IOLoop->stop;
});
my $timer = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
Mojo::IOLoop->remove($timer);

is $done, 200, 'non-blocking request worked';
my @spans = $sink->spans;
is scalar @spans, $prev + 1, 'one span was created for the non-blocking request';
my $nb_span = $spans[-1];
is $nb_span_id, $nb_span->hex_span_id, 'callback ran with the span in context';
ok $recording_in_cb, 'span was still recording when the callback ran';
ok $nb_span->end_timestamp, 'span was ended after the callback';

# Uninstall
my $count = scalar $sink->spans;
$CLASS->uninstall;
$t->get_ok('/echo')->status_is(200);
is scalar $sink->spans, $count, 'no spans after uninstall';

done_testing;
