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
use OpenTelemetry::Baggage;
use OpenTelemetry::Constants -span;
use OpenTelemetry::Context;
use OpenTelemetry::Exporter;
use OpenTelemetry::Propagator::Baggage;
use OpenTelemetry::SDK;
use OpenTelemetry::SDK::Trace::Span::Processor::Simple;
use OpenTelemetry::SDK::Trace::TracerProvider;
use OpenTelemetry::Trace;
use Syntax::Keyword::Dynamically;

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

# Echo the baggage we received, so that tests can check what the
# client actually sent on the wire
any '/echo' => sub {
  my $c = shift;
  $c->render(text => $c->req->headers->header('baggage') // 'none');
};

# Reply with a set of headers for the tests to capture. Header names
# are matched literally, so the response_[0-9] entry in the capture
# list below will not match any of these
any '/headers' => sub {
  my $c = shift;
  $c->res->headers->header('Response_1' => 1);
  $c->res->headers->header('ReSponse_2' => 2);
  $c->res->headers->add('ReSponse_2' => 'two');
  $c->res->headers->header('response_3' => 3);
  $c->render(text => 'headers!');
};

use Test::Mojo;

# Route every span into our in-memory sink
my $sink     = TestSink->new;
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

is_deeply [$CLASS->dependencies], ['Mojo::UserAgent'], 'reports dependencies';

subtest 'No headers' => sub {
  $CLASS->uninstall;
  $sink->clear;

  dynamically OpenTelemetry::Context->current
    = OpenTelemetry::Baggage->set(foo => 123, 'META');
  dynamically OpenTelemetry->propagator
    = OpenTelemetry::Propagator::Baggage->new;

  ok $CLASS->install, 'instrumentation installed';

  $t->post_ok("http://user:password\@127.0.0.1:$port/echo" => {'Content-Type' => 'text/plain'} => '0123456789')
    ->status_is(200)
    ->content_is('foo=123;META', 'propagation data was injected');
  is scalar $sink->spans, 1, 'one span was created';
  my ($span) = $sink->spans;
  is $span->name, 'POST', 'span is named after the request method';
  is $span->kind, SPAN_KIND_CLIENT, 'span is a client span';
  is_deeply $span->attributes, {
    'http.request.body.size'    => 10,
    'http.request.method'       => 'POST',
    'http.response.body.size'   => 12,
    'http.response.status_code' => 200,
    'network.protocol.name'     => 'http',
    'network.protocol.version'  => '1.1',
    'network.transport'         => 'tcp',
    'server.address'            => '127.0.0.1',
    'server.port'               => $port,
    'url.full'                  => "$base/echo",
    'user_agent.original'       => $t->ua->transactor->name,
  }, 'captured basic data';
};

subtest 'HTTP error' => sub {
  $CLASS->uninstall;
  $sink->clear;

  ok $CLASS->install, 'instrumentation installed';

  $t->get_ok("$base/missing")->status_is(404, 'request returned an error response');
  my $size = $t->tx->res->body_size;

  is scalar $sink->spans, 1, 'one span was created';
  my ($span) = $sink->spans;
  is $span->name, 'GET', 'span is named after the request method';
  is $span->kind, SPAN_KIND_CLIENT, 'span is a client span';
  is_deeply $span->attributes, {
    'http.request.method'       => 'GET',
    'http.response.body.size'   => $size,
    'http.response.status_code' => 404,
    'network.protocol.name'     => 'http',
    'network.protocol.version'  => '1.1',
    'network.transport'         => 'tcp',
    'server.address'            => '127.0.0.1',
    'server.port'               => $port,
    'url.full'                  => "$base/missing",
    'user_agent.original'       => $t->ua->transactor->name,
  }, 'captured basic data';
  is $span->status->code, SPAN_STATUS_ERROR, 'error status for 4xx';
  is $span->status->description, 404, 'status description is the status code';
};

subtest 'Internal error' => sub {
  $CLASS->uninstall;
  $sink->clear;

  ok $CLASS->install, 'instrumentation installed';

  # Grab a port that is very likely to refuse connections
  my $server = Mojo::IOLoop->server({address => '127.0.0.1', port => 0} => sub { });
  my $dead_port = Mojo::IOLoop->acceptor($server)->port;
  Mojo::IOLoop->remove($server);

  my $tx = $t->ua->get("http://127.0.0.1:$dead_port/");
  ok $tx->error, 'transaction reports an error';

  is scalar $sink->spans, 1, 'one span was created';
  my ($span) = $sink->spans;
  is $span->name, 'GET', 'span is named after the request method';
  is $span->kind, SPAN_KIND_CLIENT, 'span is a client span';
  is_deeply $span->attributes, {
    'http.request.method'      => 'GET',
    'network.protocol.name'    => 'http',
    'network.protocol.version' => '1.1',
    'network.transport'        => 'tcp',
    'server.address'           => '127.0.0.1',
    'server.port'              => $dead_port,
    'url.full'                 => "http://127.0.0.1:$dead_port/",
    'user_agent.original'      => $t->ua->transactor->name,
  }, 'captured basic data';
  my @events = $span->events;
  is scalar @events, 1, 'exception was recorded';
  is $events[0]->name, 'exception', 'event is an exception';
  is $span->status->code, SPAN_STATUS_ERROR, 'error status on transport failure';
  like $span->status->description, qr/\S/, 'status has the error message';
  ok $span->end_timestamp, 'span was ended';
};

subtest 'Requested headers' => sub {
  $CLASS->uninstall;
  $sink->clear;

  ok $CLASS->install(
    request_headers  => [qw(default-1 default-2 request_2 request_3)],
    response_headers => [qw(response_1 response_[0-9])],
  ) => 'instrumentation installed';

  $t->get_ok("$base/headers?query=1#fragment" => {
    'Default-1' => [1, 'one'],
    'DeFault-2' => 2,
    'Request_1' => 1,
    'ReQuest_2' => 2,
    'request_3' => [3, 'three'],
  })->status_is(200)->content_is('headers!');

  is scalar $sink->spans, 1, 'one span was created';
  my ($span) = $sink->spans;
  is $span->name, 'GET', 'span is named after the request method';
  is $span->kind, SPAN_KIND_CLIENT, 'span is a client span';
  is_deeply $span->attributes, {
    'http.request.header.default_1'   => [1, 'one'],
    'http.request.header.default_2'   => [2],
    'http.request.header.request_2'   => [2],
    'http.request.header.request_3'   => [3, 'three'],
    'http.request.method'             => 'GET',
    'http.response.body.size'         => 8,
    'http.response.header.response_1' => [1],
    'http.response.status_code'       => 200,
    'network.protocol.name'           => 'http',
    'network.protocol.version'        => '1.1',
    'network.transport'               => 'tcp',
    'server.address'                  => '127.0.0.1',
    'server.port'                     => $port,
    'url.full'                        => "$base/headers?query=1#fragment",
    'user_agent.original'             => $t->ua->transactor->name,
  }, 'captured basic data';
};

subtest 'Non-blocking request' => sub {
  $CLASS->uninstall;
  $sink->clear;

  ok $CLASS->install, 'instrumentation installed';

  # The span is only exported once it ends, which happens after the
  # callback returns. While in the callback, we can only see it
  # through the context the instrumentation restored for us
  my ($code, $cb_span_id, $recording_in_cb);
  $t->ua->get("$base/echo" => sub {
    my ($ua, $tx) = @_;
    $code            = $tx->res->code;
    my $ctx_span     = OpenTelemetry::Trace->span_from_context(OpenTelemetry::Context->current);
    $cb_span_id      = $ctx_span->context->hex_span_id;
    $recording_in_cb = $ctx_span->recording;
    Mojo::IOLoop->stop;
  });
  my $timer = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($timer);

  is $code, 200, 'non-blocking request worked';

  is scalar $sink->spans, 1, 'one span was created';
  my ($span) = $sink->spans;
  is $span->name, 'GET', 'span is named after the request method';
  is $cb_span_id, $span->hex_span_id, 'callback runs with the span in context';
  ok $recording_in_cb, 'span is still recording when the callback runs';
  ok $span->end_timestamp, 'span was ended after the callback';
  is $span->attributes->{'http.response.status_code'}, 200, 'response attributes were recorded';
};

subtest 'Promise-based request' => sub {
  $CLASS->uninstall;
  $sink->clear;

  ok $CLASS->install, 'instrumentation installed';

  my $done;
  $t->ua->get_p("$base/echo")->then(sub { ($done) = @_; Mojo::IOLoop->stop })
                         ->catch(sub { Mojo::IOLoop->stop });
  my $timer = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($timer);

  ok $done, 'promise resolved';
  is $done->res->code, 200, 'promise resolved with the response';

  is scalar $sink->spans, 1, 'one span was created';
  my ($span) = $sink->spans;
  is $span->name, 'GET', 'span is named after the request method';
  ok $span->end_timestamp, 'span was ended';
  is $span->attributes->{'http.response.status_code'}, 200, 'response attributes were recorded';
};

done_testing;
