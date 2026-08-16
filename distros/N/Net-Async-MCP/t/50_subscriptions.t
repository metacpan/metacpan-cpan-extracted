use strict;
use warnings;
use Test2::V0;

use Future;
use JSON::MaybeXS;

use Net::Async::MCP;
use Net::Async::MCP::Transport::HTTP;

# Subscriptions only exist over a transport that has a stream to carry them,
# which is the HTTP one, and it reaches this distribution only through
# Net::Async::HTTP - a recommendation, not a requirement.
skip_all 'HTTP::Message is required for the subscription tests'
  unless eval { require HTTP::Response; require HTTP::Request; 1 };

# A subscriptions/listen is the one request a server never answers with a
# JSON-RPC response. MCP::Server::Transport::HTTP::_handle_subscription opens
# the SSE stream, writes MCP::Server::Subscription::acknowledgement - a
# notification - and then holds the stream open for the notifications that were
# subscribed to. So the request is settled by a message in the middle of a
# stream that only ends when one side closes it, and everything in here is
# about that shape.

my $SUBSCRIPTION_ID = 'io.modelcontextprotocol/subscriptionId';
my $ACKNOWLEDGED    = 'notifications/subscriptions/acknowledged';

my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1, convert_blessed => 1);

sub sse {
  my ( $message ) = @_;
  return 'data: ' . $json->encode($message) . "\n\n";
}

# The acknowledgement as MCP::Server::Subscription builds it: the subscription
# id in _meta, the notification types the server honoured beside it. Called
# without an id for the server that leaves it out.
sub acknowledgement {
  my ( $id, @notifications ) = @_;
  return sse({
    jsonrpc => '2.0',
    method  => $ACKNOWLEDGED,
    params  => {
      defined $id ? ( _meta => { $SUBSCRIPTION_ID => $id } ) : (),
      notifications => { map { $_ => \1 } @notifications },
    },
  });
}

sub list_changed {
  my ( $id, $what ) = @_;
  return sse({
    jsonrpc => '2.0',
    method  => "notifications/$what/list_changed",
    params  => { _meta => { $SUBSCRIPTION_ID => $id } },
  });
}

# A Net::Async::HTTP whose streams the test drives by hand. The mocks in
# t/30_http.t feed a whole body and end it in the same call, which is exactly
# what a subscription never does: here do_request hands back the body callback
# and a Future that stays pending until the stream is ended or closed, so the
# test can send events onto a stream that is still open and look at what the
# transport did with it.
{
  package Test::LiveHTTP;

  sub new { return bless { streams => [], requests => [] }, shift }

  sub do_request {
    my ( $self, %args ) = @_;
    push @{ $self->{requests} }, $args{request};

    my $header = HTTP::Response->new(200, 'OK',
      [ 'Content-Type' => 'text/event-stream' ], '');

    my $stream = {
      chunk  => $args{on_header}->($header),
      future => Future->new,
    };
    push @{ $self->{streams} }, $stream;

    return $stream->{future};
  }

  # The stream of the nth request, latest by default: a test with two
  # subscriptions running names which one it means.
  sub stream { return $_[0]{streams}[ defined $_[1] ? $_[1] : -1 ] }

  sub requests { return @{ $_[0]{requests} } }

  sub feed {
    my ( $self, $text, $which ) = @_;
    my $stream = $self->stream($which);
    $stream->{chunk}->($text) unless $stream->{future}->is_ready;
    return $self;
  }

  # The server closing the stream from its end, which is a body that simply
  # stops arriving.
  sub finish {
    my ( $self, $which ) = @_;
    my $stream = $self->stream($which);
    $stream->{future}->done($stream->{chunk}->()) unless $stream->{future}->is_ready;
    return $self;
  }

  # The connection dying underneath the stream, which is what a server restart
  # or a gateway giving up looks like from the transport: the exchange fails
  # rather than ending cleanly.
  sub fail {
    my ( $self, $message, $which ) = @_;
    my $stream = $self->stream($which);
    $stream->{future}->fail($message) unless $stream->{future}->is_ready;
    return $self;
  }
}

sub transport {
  my ( $notifications, $ends ) = @_;

  my $t = Net::Async::MCP::Transport::HTTP->new(
    url                  => 'http://mcp.invalid/mcp',
    on_notification      => sub { push @$notifications, $_[1] },
    on_subscription_end  => sub { push @$ends, $_[1] if $ends },
  );
  $t->{http} = Test::LiveHTTP->new;

  return ( $t, $t->{http} );
}

sub subscribe {
  my ( $transport, %notifications ) = @_;
  return $transport->send_request('subscriptions/listen',
    { notifications => \%notifications },
    resolve_on_notification => $ACKNOWLEDGED);
}

# The whole life of one subscription, in the order it happens: the request
# waits, the acknowledgement answers it, the stream carries what was subscribed
# to, and closing the stream is how it is ended - the specification defines no
# unsubscribe request, and the server drops the subscription when the stream
# finishes.
{
  my @got;
  my @ended;
  my ( $t, $http ) = transport(\@got, \@ended);

  my $f = subscribe($t, toolsListChanged => \1);

  ok(!$f->is_ready,
    'a subscription request waits for the stream to say something');

  $http->feed(acknowledgement('sub-1', 'toolsListChanged'));

  ok($f->is_done, 'and is settled by the acknowledgement, which is no response')
    or diag $f->failure;

  my $subscription = $f->get;
  is($subscription->{_meta}{$SUBSCRIPTION_ID}, 'sub-1',
    'the caller is handed the acknowledgement params, subscription id and all');
  ok($subscription->{notifications}{toolsListChanged},
    'together with the notification types the server honoured');
  is(scalar @got, 0,
    'while the acknowledgement itself is the answer and not an event of its own');

  ok(!$http->stream->{future}->is_ready,
    'the stream stays open behind the answer, which is the point of it');

  $http->feed(list_changed('sub-1', 'tools'));

  is([ map { $_->{method} } @got ], ['notifications/tools/list_changed'],
    'and what it carries from here on reaches on_notification');

  ok($t->stop_subscription('sub-1'),
    'stopping a running subscription reports that it stopped one');
  ok($http->stream->{future}->is_cancelled,
    'and closes the stream, which is what unsubscribing is over this binding');
  is([ @ended ], [],
    'while an end the caller caused itself is not reported as an on_subscription_end');

  ok(!$t->stop_subscription('sub-1'),
    'a subscription that has been stopped is no longer there to stop');

  # The transport holds the exchange for the caller now that the caller holds
  # something else, so it is the transport that has to let go of it again -
  # otherwise every request ever made stays on it.
  is($t->{pending}, {}, 'and the transport holds nothing for it any more');
  is($t->{subscriptions}, {}, 'nor a stream it could still be reached by');
}

# A stream that ends while the subscription is running ends the subscription
# with it. The request's Future was settled by the acknowledgement long ago
# and cannot report it, so on_subscription_end is what tells the caller - the
# moment it happens, rather than when it next thinks to ask.
{
  my @got;
  my @ended;
  my ( $t, $http ) = transport(\@got, \@ended);

  my $f = subscribe($t, toolsListChanged => \1);
  $http->feed(acknowledgement('sub-1', 'toolsListChanged'));
  ok($f->is_done, 'a subscription is running') or diag $f->failure;

  $http->finish;

  ok($f->is_done, 'the server ending the stream leaves the answer it gave standing');
  is([ @ended ], ['sub-1'],
    'and reports the subscription that ended on its own, with the id');
  ok(!$t->stop_subscription('sub-1'),
    'while the subscription it was carrying is gone, and says so when asked');
  is($t->{pending}, {}, 'with nothing left behind on the transport');
}

# The same end reached from the other direction: not a stream the server closed
# cleanly but a connection that died underneath it - a server that restarted,
# a gateway that gave up. Whatever ended the stream, the subscription on it is
# over, and the caller is told in the same way.
{
  my @got;
  my @ended;
  my ( $t, $http ) = transport(\@got, \@ended);

  my $f = subscribe($t, toolsListChanged => \1);
  $http->feed(acknowledgement('sub-1', 'toolsListChanged'));
  ok($f->is_done, 'a subscription is running') or diag $f->failure;

  $http->fail('connection reset by peer');

  ok($f->is_done, 'a failed connection leaves the answer it gave standing too');
  is([ @ended ], ['sub-1'],
    'and reports the same end through the same event');
  ok(!$t->stop_subscription('sub-1'),
    'with the subscription gone there as well');
  is($t->{pending}, {}, 'and nothing left behind on the transport');
}

# Two at once. Each has its own request, its own stream and its own id, and
# stopping one must not touch the other - which is the whole reason the
# transport keys its streams by subscription id rather than holding one.
{
  my @got;
  my @ended;
  my ( $t, $http ) = transport(\@got, \@ended);

  my $tools = subscribe($t, toolsListChanged => \1);
  $http->feed(acknowledgement('sub-tools', 'toolsListChanged'), 0);

  my $prompts = subscribe($t, promptsListChanged => \1);
  $http->feed(acknowledgement('sub-prompts', 'promptsListChanged'), 1);

  is($tools->get->{_meta}{$SUBSCRIPTION_ID}, 'sub-tools',
    'each subscription is answered with its own acknowledgement');
  is($prompts->get->{_meta}{$SUBSCRIPTION_ID}, 'sub-prompts',
    'and the second one is not confused with the first');

  $http->feed(list_changed('sub-prompts', 'prompts'), 1);
  is([ map { $_->{method} } @got ], ['notifications/prompts/list_changed'],
    'both streams feed the same handler, tagged with the id they came from');

  ok($t->stop_subscription('sub-tools'), 'stopping one of them stops that one');
  ok($http->stream(0)->{future}->is_cancelled, 'and closes its stream');
  ok(!$http->stream(1)->{future}->is_ready,
    'while the other one keeps running');

  ok(!$t->stop_subscription('never-subscribed'),
    'an id that was never subscribed under stops nothing and says so');

  # close has to take the rest with it: a subscription outlives the request
  # that opened it, so it is the one thing this transport holds that a
  # shutdown has to end. A shutdown is a caller's own doing, so it is not
  # reported as an end that happened on its own either.
  $t->close->get;
  ok($http->stream(1)->{future}->is_cancelled,
    'closing the transport closes the streams still open on it');
  is([ @ended ], [],
    'while a shutdown ending a subscription is not reported as one ending on its own');
}

# A stream that ends before the acknowledgement answered nothing. Reporting it
# as the generic missing response would send a caller looking for a response
# the server was never going to send - and there is no subscription to report
# the end of either: one that never got its acknowledgement was never running.
{
  my @got;
  my @ended;
  my ( $t, $http ) = transport(\@got, \@ended);

  my $f = subscribe($t, toolsListChanged => \1);
  $http->finish;

  is($f->failure, 'MCP HTTP stream ended before the subscription was acknowledged',
    'a stream that ended before acknowledging names what it failed to do');
  is([ @ended ], [],
    'and no on_subscription_end, there being no subscription yet');
}

# An acknowledgement without a subscription id is a subscription that cannot be
# addressed: nothing can stop it and nothing can close it later, so it is
# refused rather than handed to a caller who would hold a stream it has no way
# of ending.
{
  my @got;
  my ( $t, $http ) = transport(\@got);

  my $f = subscribe($t, toolsListChanged => \1);
  $http->feed(acknowledgement(undef, 'toolsListChanged'));

  is($f->failure, 'MCP HTTP subscription acknowledged without a subscription id',
    'an acknowledgement with no id in _meta fails the request');
  ok($http->stream->{future}->is_cancelled,
    'and the stream nobody could have ended is closed there and then');
}

# A server that refuses the method answers with a JSON-RPC error rather than a
# stream, and a subscription request has to fail on it like any other request:
# resolve_on_notification says what settles the request when the stream carries
# it, not that nothing else can.
{
  my @got;
  my ( $t, $http ) = transport(\@got);

  my $f = subscribe($t, toolsListChanged => \1);
  $http->feed(sse({
    jsonrpc => '2.0',
    id      => 1,
    error   => { code => -32601, message => "Method 'subscriptions/listen' not found" },
  }));

  is($f->failure, "MCP error -32601: Method 'subscriptions/listen' not found",
    'an error on the stream fails the subscription request as it would any other');
}

# From here the client rather than the transport: subscriptions_listen has to
# tell the transport what settles the request, and there is no other way for
# the transport to know - it deliberately does not read the method name and
# decide for itself.
sub client {
  my ( $notifications, $ends ) = @_;

  my ( $t, $http ) = transport([]);

  my $mcp = Net::Async::MCP->new(url => 'http://mcp.invalid/mcp');
  $mcp->{transport} = $t;

  # Configured after the transport is in place, which is the path a caller
  # setting a handler on a live client takes, and the one that has to reach
  # the transport for a subscription's notifications to arrive at all.
  $mcp->configure(on_notification => sub { push @$notifications, $_[1] if $notifications });
  $mcp->configure(on_subscription_end => sub { push @$ends, [ @_ ] }) if $ends;

  return ( $mcp, $http );
}

{
  my @got;
  my ( $mcp, $http ) = client(\@got);

  my $f = $mcp->subscriptions_listen({ toolsListChanged => 1 });
  ok(!$f->is_ready, 'subscriptions_listen waits like the request underneath it');

  $http->feed(acknowledgement('sub-1', 'toolsListChanged'));

  ok($f->is_done, 'and resolves on the acknowledgement') or diag $f->failure;

  my $subscription = $f->get;
  my $id = $subscription->{_meta}{$SUBSCRIPTION_ID};
  is($id, 'sub-1', 'with the acknowledgement params the caller needs');
  ok($subscription->{notifications}{toolsListChanged},
    'including which notifications the server will actually send');

  my ( $request ) = $http->requests;
  my $body = $json->decode($request->content);
  is($body->{method}, 'subscriptions/listen', 'the request that went out is the one asked for');
  ok($body->{params}{_meta}{'io.modelcontextprotocol/protocolVersion'},
    'carrying the _meta every request of this client carries');
  is($body->{params}{notifications}, { toolsListChanged => 1 },
    'and the notification filter the caller asked for');

  $http->feed(list_changed('sub-1', 'tools'));
  is([ map { $_->{method} } @got ], ['notifications/tools/list_changed'],
    'what the subscription delivers reaches the client-level on_notification');

  ok($mcp->subscriptions_stop($id)->get, 'subscriptions_stop ends it');
  ok($http->stream->{future}->is_cancelled, 'by closing the stream it ran on');
  ok(!$mcp->subscriptions_stop($id)->get,
    'and a second stop finds nothing left to end');
}

# The whole point of on_subscription_end is that it reaches the caller - and on
# the client level, where the caller actually holds the subscription: the
# Future of subscriptions_listen was settled by the acknowledgement long ago,
# so a stream ending on its own - a server restart, a gateway giving up - has
# nothing else to report it through.
{
  my @ended;
  my ( $mcp, $http ) = client(undef, \@ended);

  my $f = $mcp->subscriptions_listen({ toolsListChanged => 1 });
  $http->feed(acknowledgement('sub-1', 'toolsListChanged'));
  ok($f->is_done, 'a subscription is running') or diag $f->failure;

  $http->finish;

  ok($f->is_done, 'the stream ending leaves the answer it gave standing');
  is(scalar @ended, 1,
    'and reaches the on_subscription_end handler of the client');
  is($ended[0][0], exact_ref($mcp),
    'with the client as its first argument, like every event of it');
  is($ended[0][1], 'sub-1',
    'and the subscription id that ended');
  ok(!$mcp->subscriptions_stop('sub-1')->get,
    'which is also what subscriptions_stop reports when asked');

  # A stream that ends after the caller stopped the subscription is the caller
  # getting what it asked for, not an end it needs to be told about.
  my $again = $mcp->subscriptions_listen({ toolsListChanged => 1 });
  $http->feed(acknowledgement('sub-2', 'toolsListChanged'), 1);
  ok($again->is_done, 'a second subscription is running') or diag $again->failure;
  ok($mcp->subscriptions_stop('sub-2')->get, 'stopped by the caller');
  $http->finish(1);

  is(scalar @ended, 1,
    'and a stream closed by subscriptions_stop is not reported as ended on its own');
}

# The other two transports have no stream a subscription could run on, so they
# have no subscription to stop either. Answering false is the same answer an
# unknown id gets, which is what it is.
{
  package Test::Streamless;

  sub new { return bless {}, shift }
  sub send_request { return Future->fail('MCP subscriptions/listen is not usable') }
}

{
  my $mcp = Net::Async::MCP->new(url => 'http://mcp.invalid/mcp');
  $mcp->{transport} = Test::Streamless->new;

  ok(!$mcp->subscriptions_stop('sub-1')->get,
    'a transport that cannot subscribe has no subscription to stop');
}

# Leaving the loop takes the HTTP client with it, so nothing that is still
# waiting can ever be answered. Same lesson as the stdio transport: a Future
# nobody will ever settle is worse than one that fails with the reason.
subtest 'leaving the loop settles what is still open' => sub {
  skip_all 'Net::Async::HTTP is required for the loop tests'
    unless eval { require Net::Async::HTTP; 1 };

  require IO::Async::Loop;
  my $loop = IO::Async::Loop->new;

  my @got;
  my $t = Net::Async::MCP::Transport::HTTP->new(
    url             => 'http://mcp.invalid/mcp',
    on_notification => sub { push @got, $_[1] },
  );
  $loop->add($t);

  # Only after joining the loop, which is where the real client is built: this
  # test is about leaving it again, not about sending anything.
  my $http = Test::LiveHTTP->new;
  $t->{http} = $http;

  my $waiting = subscribe($t, toolsListChanged => \1);

  my $running = subscribe($t, promptsListChanged => \1);
  $http->feed(acknowledgement('sub-running', 'promptsListChanged'), 1);
  ok($running->is_done, 'one subscription is up before the loop is left');

  $loop->remove($t);

  is($waiting->failure,
    'MCP HTTP transport left the loop before the request was answered',
    'a request still waiting for its stream is failed with the reason it will not come');
  ok($http->stream(0)->{future}->is_cancelled,
    'and its stream is closed rather than left behind');
  ok($http->stream(1)->{future}->is_cancelled,
    'as is the stream of the subscription that was already running');
  ok(!$t->stop_subscription('sub-running'),
    'which leaves nothing to stop afterwards');
};

done_testing;
