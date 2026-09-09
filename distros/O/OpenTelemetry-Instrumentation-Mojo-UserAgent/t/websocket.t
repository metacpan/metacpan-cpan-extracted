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
use Mojo::Promise;
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

# Plain echo
websocket '/echo' => sub { shift->on(message => sub { shift->send(shift) }) };

# Echoes the traceparent the handshake received, so that tests can
# check what the client actually sent on the wire
websocket '/trace' => sub {
  my $c = shift;
  $c->on(message => sub {
    my ($c, $msg) = @_;
    $c->send("$msg:" . ($c->req->headers->header('traceparent') // 'none'));
  });
};

websocket '/denied' => sub { shift->render(text => 'denied', status => 403) };

websocket '/dead' => sub { die 'i see dead processes' };

# Opens a nested WebSocket connection from inside the server
websocket '/subreq' => sub {
  my $c = shift;
  $c->ua->websocket(
    '/echo' => sub {
      my ($ua, $tx) = @_;
      $tx->on(
        message => sub {
          my ($tx, $msg) = @_;
          $c->send($msg);
          $tx->finish;
          $c->finish;
        }
      );
      $tx->send('inner');
    }
  );
};

get '/ping' => sub { shift->render(text => 'pong') };

# Silence
app->log->level('fatal');

# Run the event loop, but never longer than 10 seconds, so that an
# exchange that never completes fails the test instead of hanging it
sub run_loop {
  my $timer = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($timer);
}

my $CLASS = 'OpenTelemetry::Instrumentation::Mojo::UserAgent';
my $sink  = TestSink->new;
my $provider = OpenTelemetry::SDK::Trace::TracerProvider->new;
$provider->add_span_processor(
  OpenTelemetry::SDK::Trace::Span::Processor::Simple->new(exporter => $sink));
OpenTelemetry->tracer_provider = $provider;

my $ua = app->ua;

# Note: like the Mojolicious core test suite, this test uses relative
# urls. Absolute ws:// urls do not work reliably through app->ua in
# this version, and the request url is only absolutized against the
# app server after the instrumentation has already recorded it, so
# the span attributes below reflect the relative form

# Warm up the in-process server
$ua->get('/ping');

# Instrument every user agent from here on
ok $CLASS->install, 'instrumentation installed';

subtest 'Plain WebSocket' => sub {
  $CLASS->uninstall;
  $sink->clear;
  ok $CLASS->install, 'instrumentation installed';

  my ($code, $result);
  $ua->websocket(
    '/echo' => sub {
      my ($ua, $tx) = @_;
      $code = $tx->res->code;
      $tx->on(finish  => sub { Mojo::IOLoop->stop });
      $tx->on(message => sub { shift->finish; $result = pop });
      $tx->send('test1');
    }
  );
  run_loop;

  is $code,   101,   'handshake succeeded';
  is $result, 'test1', 'messages still flow through the instrumented user agent';

  is scalar $sink->spans, 1, 'one span was created';
  my ($span) = $sink->spans;
  is $span->name, 'GET', 'span is named after the handshake method';
  is $span->kind, SPAN_KIND_CLIENT, 'span is a client span';
  is $span->attributes->{'http.request.method'}, 'GET', 'right request method';
  is $span->attributes->{'url.full'}, '/echo', 'right full url';
  is $span->attributes->{'server.port'}, 80, 'default server port for relative urls';
  ok !exists $span->attributes->{'server.address'}, 'no server address for relative urls';
  is $span->attributes->{'http.response.status_code'}, 101, 'right handshake status code';
  ok !exists $span->attributes->{'http.resend_count'}, 'no redirect attributes for websockets';
  ok $span->status->is_unset, 'successful handshakes leave the status unset';
  ok $span->end_timestamp, 'span was ended when the handshake completed';
};

subtest 'Propagation' => sub {
  $CLASS->uninstall;
  $sink->clear;
  ok $CLASS->install, 'instrumentation installed';

  my $result;
  $ua->websocket(
    '/trace' => sub {
      my ($ua, $tx) = @_;
      $tx->on(finish  => sub { Mojo::IOLoop->stop });
      $tx->on(message => sub { shift->finish; $result = pop });
      $tx->send('hello');
    }
  );
  run_loop;

  like $result, qr/^hello:00-[0-9a-f]{32}-[0-9a-f]{16}-0[01]$/,
    'propagation data was sent with the handshake';

  is scalar $sink->spans, 1, 'one span was created';
  my ($span) = $sink->spans;
  my ($trace_id) = $result =~ /^hello:00-([0-9a-f]{32})-/;
  is $trace_id, $span->hex_trace_id, 'propagated trace id matches the span';
};

subtest 'Promises' => sub {
  $CLASS->uninstall;
  $sink->clear;
  ok $CLASS->install, 'instrumentation installed';

  my ($established, $result);
  $ua->websocket_p('/echo')->then(sub {
    my $tx = shift;
    $established = $tx->established;
    my $promise = Mojo::Promise->new;
    $tx->on(finish  => sub { $promise->resolve });
    $tx->on(message => sub { shift->finish; $result = pop });
    $tx->send('test2');
    return $promise;
  })->wait;

  ok $established, 'connection established';
  is $result, 'test2', 'promise-based websockets still work';

  is scalar $sink->spans, 1, 'one span was created';
  my ($span) = $sink->spans;
  is $span->attributes->{'http.response.status_code'}, 101, 'right handshake status code';
  ok $span->end_timestamp, 'span was ended';
};

subtest 'Connection denied' => sub {
  $CLASS->uninstall;
  $sink->clear;
  ok $CLASS->install, 'instrumentation installed';

  my ($ws, $code);
  $ua->websocket(
    '/denied' => sub {
      my ($ua, $tx) = @_;
      ($ws, $code) = ($tx->is_websocket, $tx->res->code);
      Mojo::IOLoop->stop;
    }
  );
  run_loop;

  ok !$ws, 'not a WebSocket';
  is $code, 403, 'right status';

  is scalar $sink->spans, 1, 'one span was created';
  my ($span) = $sink->spans;
  is $span->attributes->{'http.response.status_code'}, 403, 'right response status code';
  is $span->status->code, SPAN_STATUS_ERROR, 'error status for 4xx';
  is $span->status->description, 403, 'status description is the status code';
  ok $span->end_timestamp, 'span was ended';
};

subtest 'Dies' => sub {
  $CLASS->uninstall;
  $sink->clear;
  ok $CLASS->install, 'instrumentation installed';

  my ($ws, $code);
  $ua->websocket(
    '/dead' => sub {
      my ($ua, $tx) = @_;
      ($ws, $code) = ($tx->is_websocket, $tx->res->code);
      Mojo::IOLoop->stop;
    }
  );
  run_loop;

  ok !$ws, 'not a websocket';
  is $code, 500, 'right status';

  is scalar $sink->spans, 1, 'one span was created';
  my ($span) = $sink->spans;
  is $span->attributes->{'http.response.status_code'}, 500, 'right response status code';
  is $span->status->code, SPAN_STATUS_ERROR, 'error status for 5xx';
  ok $span->end_timestamp, 'span was ended';
};

subtest 'Subrequests' => sub {
  $CLASS->uninstall;
  $sink->clear;
  ok $CLASS->install, 'instrumentation installed';

  my $result;
  $ua->websocket(
    '/subreq' => sub {
      my ($ua, $tx) = @_;
      $tx->on(message => sub { shift->finish; $result = pop });
      $tx->on(finish  => sub { Mojo::IOLoop->stop });
    }
  );
  run_loop;

  is $result, 'inner', 'nested websockets still work';

  is scalar $sink->spans, 2, 'one span for each handshake';
  my @spans = $sink->spans;
  my ($outer) = grep { $_->attributes->{'url.full'} eq '/subreq' } @spans;
  my ($inner) = grep { $_->attributes->{'url.full'} eq '/echo' } @spans;
  ok $outer, 'outer handshake was recorded';
  ok $inner, 'inner handshake was recorded';
  is $outer->attributes->{'http.response.status_code'}, 101, 'outer handshake status code';
  is $inner->attributes->{'http.response.status_code'}, 101, 'inner handshake status code';
  ok $_->end_timestamp, 'both spans were ended' for $outer, $inner;
};

subtest 'Unsupported protocol' => sub {
  $CLASS->uninstall;
  $sink->clear;
  ok $CLASS->install, 'instrumentation installed';

  my $error;
  $ua->websocket(
    'wsss://example.com' => sub {
      my ($ua, $tx) = @_;
      $error = $tx->error;
      Mojo::IOLoop->stop;
    }
  );
  run_loop;

  is $error->{message}, 'Unsupported protocol: wsss', 'right error';

  is scalar $sink->spans, 1, 'one span was created';
  my ($span) = $sink->spans;
  my @events = $span->events;
  is scalar @events, 1, 'exception was recorded';
  is $span->status->code, SPAN_STATUS_ERROR, 'error status on failed connection';
  ok $span->end_timestamp, 'span was ended';
};

subtest 'Uninstall' => sub {
  my $prev = scalar $sink->spans;
  $CLASS->uninstall;

  my $result;
  $ua->websocket(
    '/echo' => sub {
      my ($ua, $tx) = @_;
      $tx->on(finish  => sub { Mojo::IOLoop->stop });
      $tx->on(message => sub { shift->finish; $result = pop });
      $tx->send('test3');
    }
  );
  run_loop;

  is $result, 'test3', 'websockets still work after uninstall';
  is scalar $sink->spans, $prev, 'no spans after uninstall';
};

done_testing;
