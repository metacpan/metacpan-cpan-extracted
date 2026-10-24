package Net::Async::MCP;
# ABSTRACT: Async MCP (Model Context Protocol) client for IO::Async

use strict;
use warnings;
use parent 'IO::Async::Notifier';

use Future::AsyncAwait;
use Carp qw( croak );
use Scalar::Util qw( blessed looks_like_number weaken );

our $VERSION = '0.007';


# The modern protocol revisions this client speaks, newest first: the first of
# them is what a client that was not told otherwise sends, and they are the
# only ones a refused request may be renegotiated into.
#
# What belongs in here is decided by the code below and by nothing else: an
# entry means that what this file builds is what that revision defines - today
# a server/discover handshake with no initialize/initialized pair, the
# io.modelcontextprotocol/* keys in _meta, and input_required results answered
# with inputResponses. So adding one means first teaching this client to build
# that revision's request shapes. A revision some dependency happens to know
# about is not one this client can speak, and switching to it on that strength
# would put a new version string on requests that revision never had - trading
# a clear "unsupported protocol version" for a confusing "method not found".
#
# Deliberately not MCP::Constants::SUPPORTED_VERSIONS: that list says what the
# installed server library accepts, which is a different question whose answer
# only happens to be the same one today.
my @MODERN_PROTOCOL_VERSIONS = ('2026-07-28');

# The legacy revisions this client speaks, newest first: the ones with an
# initialize/initialized handshake and no protocol keys in _meta, which is what
# every third-party server speaks today. The same rule as above decides what
# goes in here - what this file builds for them, the handshake, the plain
# requests and the absent _meta, is the same in all four, and a revision whose
# requests differ from that is not one to add without teaching the client the
# difference first.
my @LEGACY_PROTOCOL_VERSIONS = ('2025-11-25', '2025-06-18', '2025-03-26', '2024-11-05');

# What this client sends when the caller named no protocol_version: the newest
# revision it speaks. Deliberately not MCP::Constants::PROTOCOL_VERSION - that
# is the revision the installed server library implements, and following it
# onto a newer one would put that version string on requests this file still
# builds in the old one, for the reason spelled out above.
my $DEFAULT_PROTOCOL_VERSION = $MODERN_PROTOCOL_VERSIONS[0];

# The code a server answers a request made in a revision it does not speak
# with. The number the specification gives it, written out rather than read
# from L<MCP::Constants>: it is compared against what a remote server sent, so
# a locally installed library has no say in it, and a client on stdio or HTTP
# has no reason to have L<MCP> installed at all.
my $UNSUPPORTED_PROTOCOL_VERSION = -32022;

# The errors only a modern server answers with - HeaderMismatch,
# MissingRequiredClientCapability and UnsupportedProtocolVersion. A probe
# refused with one of them was refused by a modern server, and must not fall
# back to initialize; any other error says the server is legacy.
my %MODERN_ERROR_CODES = map { $_ => 1 } ( -32020, -32021, $UNSUPPORTED_PROTOCOL_VERSION );

# How long the server/discover probe of a stdio server may stay unanswered
# before the server is taken to be legacy. Generous because a slow start - an
# npx that first has to fetch its package - looks exactly like a server that
# will never answer.
my $DEFAULT_DISCOVER_TIMEOUT = 10;

# The settings this client keeps to itself, whichever transport it ends up
# with.
my @CLIENT_KEYS = qw( server command url protocol_version client_capabilities
  on_input_request discover_timeout );

# The settings handed on to the transport instead, each with the class a
# transport has to be for it to reach it. Kept apart from @CLIENT_KEYS because
# they are passed on only when the caller actually gave them: the transport's
# own default for stall_timeout has to survive a client that was never asked
# about it.
#
# Which transport takes what is one decision per key rather than one for the
# lot. headers and stall_timeout describe an HTTP request, and handing one to
# the Stdio transport is not a setting it ignores but an "Unrecognised
# configuration keys" croak; timeout, the limit on waiting for an answer, and
# on_notification, an event, are what both wire transports have.
# on_subscription_end has only the HTTP transport to go to, a stream being the
# one thing a subscription can end on. The InProcess transport is no
# L<IO::Async::Notifier>, has no C<configure> and no events at all, so it
# matches nothing here and is handed nothing. env, cwd and on_stderr describe
# a subprocess, which only the Stdio transport has.
my %TRANSPORT_KEYS = (
  headers               => 'Net::Async::MCP::Transport::HTTP',
  timeout               => 'IO::Async::Notifier',
  stall_timeout         => 'Net::Async::MCP::Transport::HTTP',
  on_notification       => 'IO::Async::Notifier',
  on_subscription_end   => 'Net::Async::MCP::Transport::HTTP',
  env                   => 'Net::Async::MCP::Transport::Stdio',
  cwd                   => 'Net::Async::MCP::Transport::Stdio',
  on_stderr             => 'Net::Async::MCP::Transport::Stdio',
);

# The keys of %TRANSPORT_KEYS that are events of this client rather than
# settings. They travel to the transport wrapped - see _event_handler - and
# are asked for by event rather than by key, because a subclass method of that
# name is a handler just as much as a configured code ref is.
my %EVENT_KEYS = map { $_ => 1 } qw( on_notification on_subscription_end on_stderr );

sub _init {
  my ( $self, $params ) = @_;
  $self->{protocol_version_pinned} = defined $params->{protocol_version};
  for my $key (@CLIENT_KEYS, keys %TRANSPORT_KEYS) {
    $self->{$key} = delete $params->{$key} if exists $params->{$key};
  }
  $self->{protocol_version}    //= $DEFAULT_PROTOCOL_VERSION;
  $self->{client_capabilities} //= {};
  $self->SUPER::_init($params);
}

sub configure {
  my ( $self, %params ) = @_;
  my @changed = grep { exists $params{$_} } sort keys %TRANSPORT_KEYS;

  # A protocol_version the caller names is a pin, which decides the handshake
  # - see initialize. One left to its default is not, and neither is the
  # version a handshake agreed on, which is set without passing through here.
  $self->{protocol_version_pinned} = defined $params{protocol_version}
    if exists $params{protocol_version};

  for my $key (@CLIENT_KEYS, keys %TRANSPORT_KEYS) {
    $self->{$key} = delete $params{$key} if exists $params{$key};
  }
  $self->{protocol_version}    //= $DEFAULT_PROTOCOL_VERSION;
  $self->{client_capabilities} //= {};

  # A transport that already exists takes the change too: the transport is
  # built when this client joins a loop, and a bearer token that has to be
  # rotated, or a handler for the notifications of a call about to be made,
  # arrives long after that. Only the keys that transport takes, though - see
  # %TRANSPORT_KEYS for why that is asked per key and not once for the lot.
  if ( my $transport = $self->{transport} ) {
    my @keys = grep { $transport->isa($TRANSPORT_KEYS{$_}) } @changed;
    $transport->configure($self->_transport_params(@keys)) if @keys;
  }

  $self->SUPER::configure(%params);
}

# Private: the named settings as the transport takes them. All of them travel
# as they stand except the events among them, which the transport would
# otherwise invoke with itself - see _event_handler.
sub _transport_params {
  my ( $self, @keys ) = @_;
  my %params = map { $_ => $self->{$_} } @keys;
  for my $event (grep { $EVENT_KEYS{$_} } keys %params) {
    $params{$event} = $self->_event_handler($event);
  }
  return %params;
}

# Private: the handler handed to the transport for an event of this client's
# own. It is the transport that receives the underlying thing - a notification,
# an ended subscription - and invokes the event, so a handler passed on as it
# stands would be called with the transport, while every other event of this
# client is called with the client. This wrapper puts the client back in front,
# and leaves the choice of handler to the client's own event dispatch, so a
# subclass method serves as well as a configured code ref.
#
# The client holds the transport, so what the transport holds must not hold the
# client: a strong reference in here would close the cycle. It is never undef
# where it matters - a transport that can still deliver anything is in a loop,
# and the loop holds the client that holds it.
sub _event_handler {
  my ( $self, $event ) = @_;
  return undef unless $self->can_event($event);

  weaken( my $weak_self = $self );
  return sub {
    my ( undef, @args ) = @_;
    my $client = $weak_self or return;
    return $client->maybe_invoke_event($event => @args);
  };
}

sub _add_to_loop {
  my ( $self, $loop ) = @_;
  $self->SUPER::_add_to_loop($loop);
  $self->_ensure_transport;
}

sub _ensure_transport {
  my ( $self ) = @_;
  return if $self->{transport};

  if ($self->{server}) {
    require Net::Async::MCP::Transport::InProcess;
    $self->{transport} = Net::Async::MCP::Transport::InProcess->new(
      server => $self->{server},
    );
  }
  elsif ($self->{command}) {
    croak "Stdio transport requires being added to an IO::Async::Loop"
      unless $self->loop;
    require Net::Async::MCP::Transport::Stdio;
    $self->_build_transport('Net::Async::MCP::Transport::Stdio',
      command    => $self->{command},
      on_request => $self->_server_request_handler);
  }
  elsif ($self->{url}) {
    croak "HTTP transport requires being added to an IO::Async::Loop"
      unless $self->loop;
    require Net::Async::MCP::Transport::HTTP;
    $self->_build_transport('Net::Async::MCP::Transport::HTTP',
      url        => $self->{url},
      on_request => $self->_server_request_handler);
  }
  else {
    croak "Must provide server, command, or url";
  }
}

# Private: a transport of $class, built with the setting that selected it and
# whichever of %TRANSPORT_KEYS that class takes, and made a child of this
# client so that it joins and leaves the loop along with it.
sub _build_transport {
  my ( $self, $class, %params ) = @_;

  # Only the keys the caller actually gave: handing over a stall_timeout of
  # undef for one that was never set would switch off the transport's default
  # instead of leaving it alone. Events are asked for by name rather than by
  # key, because a subclass method of that name is a handler just as much as a
  # configured code ref is.
  my @keys = grep { $class->isa($TRANSPORT_KEYS{$_}) }
    grep { $EVENT_KEYS{$_} ? $self->can_event($_) : exists $self->{$_} }
    sort keys %TRANSPORT_KEYS;

  my $transport = $class->new(%params, $self->_transport_params(@keys));
  $self->{transport} = $transport;
  $self->add_child($transport);
  return $transport;
}

# Private: the handler the wire transports hand the requests a server sends
# to the client - off stdout over stdio, off a response stream over HTTP. Only a legacy server sends any: the modern revision has no
# server-to-client requests - a server asks through input_required results
# instead - so on a modern connection they stay unanswered, as they always
# were. A legacy server gets an empty result for ping, which every revision
# requires a client to answer, and METHOD_NOT_FOUND for everything else -
# roots/list, sampling, elicitation - since the legacy handshake declares no
# capability that would invite those. Weak for the same reason as
# _event_handler: the client holds the transport that holds this.
sub _server_request_handler {
  my ( $self ) = @_;
  weaken( my $weak_self = $self );
  return sub {
    my ( undef, $request ) = @_;
    my $client = $weak_self or return;
    return unless $client->is_legacy;

    my $method = $request->{method};
    return { result => {} } if $method eq 'ping';
    return { error => {
      code    => -32601,
      message => "Method not found: $method",
    } };
  };
}

sub protocol_version { $_[0]->{protocol_version} }


sub is_legacy { ( $_[0]->{era} // '' ) eq 'legacy' ? 1 : 0 }


sub discover_timeout { $_[0]->{discover_timeout} // $DEFAULT_DISCOVER_TIMEOUT }


sub instructions { $_[0]->{instructions} }


sub client_capabilities { $_[0]->{client_capabilities} }


sub headers { $_[0]->{headers} }


sub timeout { $_[0]->{timeout} }


sub stall_timeout { $_[0]->{stall_timeout} }





# Private: the C<_meta> fields carried on every JSON-RPC request, as required
# by the current MCP revision.
sub _meta {
  my ( $self ) = @_;
  return {
    'io.modelcontextprotocol/protocolVersion'    => $self->{protocol_version},
    'io.modelcontextprotocol/clientCapabilities' => $self->{client_capabilities},
    'io.modelcontextprotocol/clientInfo'         => $self->_client_info,
  };
}

# Private: who this client is, as both eras' handshakes tell the server.
sub _client_info { return { name => 'Net::Async::MCP', version => $VERSION } }

# Private: merge a caller's C<_meta> (if any) into the standard one, returning
# params that carry C<_meta> on every request. A legacy revision has no
# standard _meta: its requests carry the caller's own, if any, and otherwise
# none at all.
sub _with_meta {
  my ( $self, $params ) = @_;
  my %params = %{ $params // {} };
  return \%params if $self->is_legacy;
  my %meta   = (%{ $self->_meta }, %{ $params{_meta} // {} });
  return { %params, _meta => \%meta };
}

# Private: how many input_required results one request may collect before the
# client gives up on it. A server is allowed to ask again after being answered
# - a confirmation can lead to a second question - but one that never arrives
# at a final result would keep this going for as long as it feels like.
my $MAX_INPUT_ROUNDS = 8;

# Private: the protocol revision to send a refused request again with, or undef
# if there is none. A server that does not speak the revision a request was
# made with answers UNSUPPORTED_PROTOCOL_VERSION and lists the ones it does
# speak in error.data.supported, newest first; the first of those this client
# speaks too is the one to switch to.
sub _renegotiated_version {
  my ( $self, $failed ) = @_;

  my ( undef, $category, $error ) = $failed->failure;
  return undef unless ( $category // '' ) eq 'mcp' && ref $error eq 'HASH';
  return undef unless ( $error->{code} // 0 ) == $UNSUPPORTED_PROTOCOL_VERSION;

  my $supported = ref $error->{data} eq 'HASH' ? $error->{data}{supported} : undef;
  return undef unless ref $supported eq 'ARRAY';

  my %usable = map { $_ => 1 } @MODERN_PROTOCOL_VERSIONS;
  for my $version (@$supported) {
    next unless defined $version && !ref $version && $usable{$version};

    # The one offer that is no answer: the request that was just refused
    # carried this very version, so sending it again would be sending the same
    # request twice and getting the same refusal back.
    return undef if $version eq $self->{protocol_version};
    return $version;
  }

  return undef;
}

# Private: one MCP request, from a method's own params to the final result.
# Every method goes through here, because this is the one place that holds what
# is true of all of them: the _meta every request carries, the input_required
# round trips a result may take before it is one, and the one retry a refused
# protocol version is worth.
async sub _request {
  my ( $self, $method, $params, %options ) = @_;

  my ( %retry, $rounds, $renegotiated, $renewed );
  while ( 1 ) {
    # A request made while a new legacy session is being started waits for
    # it, rather than going out in no session at all - all but the initialize
    # that starts it. Without cancel, so that a caller giving up on its own
    # request does not take the session from everybody else waiting on it.
    if ( ( my $renewal = $self->{session_renewal} ) && !$options{start_session} ) {
      await $renewal->without_cancel;
    }

    # Awaited as a completed Future rather than for its value: a failure has
    # more to it than its message, and the server's error object - which is
    # where a refused version names the ones it would accept instead - travels
    # as the failure's details.
    my $answered = await $self->{transport}->send_request($method,
      $self->_with_meta({ %{ $params // {} }, %retry }), %options)
      ->followed_by(sub { Future->done( $_[0] ) });

    my ( $why, $category, $expired ) = $answered->is_failed ? $answered->failure : ();
    if ( ( $category // '' ) eq 'mcp_session_expired' && $self->is_legacy ) {
      # The server ended the session. The specification has the client start
      # a new one and nothing else, and the request goes out again in it -
      # once: a server that ends the new session as well is not one more
      # session away from answering.
      return await Future->fail("MCP $method: the server ended the new "
        . "session as well ($why)", $category, $expired)
        if $renewed++;
      await $self->_renew_session($expired)->without_cancel;
      next;
    }

    if ( $answered->is_failed ) {
      # Renegotiation is the modern revision's: a legacy server agreed on its
      # version in the handshake and has no -32022 to refuse one with.
      my $version = $renegotiated || $self->is_legacy
        ? undef : $self->_renegotiated_version($answered);

      # Nothing to switch to, or one switch already made - which makes a second
      # refusal the server's problem and not one more version away from being
      # solved. Either way the server's own error is what the caller gets, code
      # and data and all, rather than a summary of it written here.
      return await $answered unless defined $version;

      # Kept on the client, not just used for the retry: every following
      # request would otherwise pay for the same refusal again. The _meta at
      # the top of this loop is built afresh, so the retry carries the version
      # agreed on here and the answers of any input_required round already
      # walked.
      $renegotiated = 1;
      $self->{protocol_version} = $version;
      next;
    }

    my $result = $answered->get;

    # So is the input_required round trip: a legacy result is final whatever
    # it carries, and one without a resultType is complete in every revision.
    return $result if $self->is_legacy;
    return $result
      unless ref $result eq 'HASH'
      && ( $result->{resultType} // '' ) eq 'input_required';

    croak "MCP $method: server answered with input_required more than "
      . "$MAX_INPUT_ROUNDS times without returning a result"
      if ++$rounds > $MAX_INPUT_ROUNDS;

    %retry = await $self->_input_required($method, $result);
  }
}

# Private: the top-level params that turn a request into the retry an
# input_required result asks for. Both of them are optional and each is sent
# only when the result actually carried it.
async sub _input_required {
  my ( $self, $method, $result ) = @_;

  my %retry;

  # Mirrored back exactly as it arrived. The server sealed it against its own
  # secret and bound it to this caller and this primitive, so there is nothing
  # here to read and everything to break by touching it.
  $retry{requestState} = $result->{requestState} if defined $result->{requestState};

  my $requests = $result->{inputRequests};
  if ( ref $requests eq 'HASH' && keys %$requests ) {
    $retry{inputResponses} = await $self->_input_responses($method, $requests);
  }
  elsif ( !%retry ) {
    # Neither half: no question to answer, and nothing to hand back that would
    # make the second attempt any different from the first.
    croak "MCP $method: server sent an input_required result with neither "
      . "inputRequests nor requestState";
  }

  return %retry;
}

# Private: the answers to a server's input requests, under the keys it asked
# them by - the same keys it reads its own responses back from.
async sub _input_responses {
  my ( $self, $method, $requests ) = @_;

  # Checked over the whole ask before a single answer is gathered: a server
  # that asks for an undeclared capability has broken its side of the
  # capability promise, and no part of that ask should be acted on.
  my $capabilities = $self->{client_capabilities} // {};
  for my $key (sort keys %$requests) {
    my $request = $requests->{$key};
    my $wanted  = ref $request eq 'HASH' ? $request->{method} : undef;

    croak "MCP $method: server sent an input request '$key' without a method"
      unless defined $wanted && length $wanted;

    # The capability is the namespace of the method asked for:
    # elicitation/create needs elicitation, sampling/createMessage needs
    # sampling, roots/list needs roots.
    my $capability = ( split m{/}, $wanted, 2 )[0];
    croak "MCP $method: server sent input request '$key' for '$wanted', "
      . "a capability this client did not declare in client_capabilities"
      unless exists $capabilities->{$capability};
  }

  croak "MCP $method: server sent input requests ("
    . join(', ', sort keys %$requests)
    . ") but no on_input_request handler is set to answer them"
    unless $self->can_event('on_input_request');

  my %responses;
  for my $key (sort keys %$requests) {
    my $request  = $requests->{$key};
    my $response = $self->invoke_event(on_input_request =>
      $request->{method}, $request->{params} // {});

    # A handler that has to ask a human answers with a Future instead of an
    # answer, and the retry waits for it.
    $response = await $response if blessed($response) && $response->isa('Future');

    croak "MCP $method: on_input_request answered input request '$key' with "
      . "something that is not a HashRef"
      unless ref $response eq 'HASH';

    $responses{$key} = $response;
  }

  return \%responses;
}

sub server_info { $_[0]->{server_info} }


sub server_capabilities { $_[0]->{server_capabilities} }


async sub initialize {
  my ( $self ) = @_;
  $self->_ensure_transport;

  # The era is the server's, so once a handshake has found it out it is not
  # asked again; before that, a pin decides it, and without one the probe does.
  my $era = $self->{era} // $self->_pinned_era // '';
  return await $self->_legacy_handshake($self->{protocol_version}) if $era eq 'legacy';
  return await $self->_modern_handshake if $era eq 'modern';
  return await $self->_probe_handshake;
}


# Private: the era a pinned protocol_version asks for, or nothing for a client
# that pinned none.
sub _pinned_era {
  my ( $self ) = @_;
  return unless $self->{protocol_version_pinned};
  my $version = $self->{protocol_version};
  return ( grep { $_ eq $version } @LEGACY_PROTOCOL_VERSIONS ) ? 'legacy' : 'modern';
}

# Private: the modern handshake, a server/discover and nothing else.
async sub _modern_handshake {
  my ( $self ) = @_;
  my $result = await $self->_request('server/discover');
  return $self->_modern_result($result);
}

# Private: what a DiscoverResult tells about the server, kept on the client.
sub _modern_result {
  my ( $self, $result ) = @_;
  $self->{era} = 'modern';

  # Read without autovivifying an _meta key into the result we hand back.
  my $meta = $result->{_meta} // {};
  $self->{server_info} = $meta->{'io.modelcontextprotocol/serverInfo'} // {};
  $self->{server_capabilities} = $result->{capabilities} // {};
  $self->{instructions} = $result->{instructions};

  return $result;
}

# Private: the handshake of a client that speaks both eras and was not told
# which one the server speaks - see initialize for the three outcomes.
async sub _probe_handshake {
  my ( $self ) = @_;

  my $probe = $self->_request('server/discover');

  # Only a stdio server may answer an unknown request with nothing at all;
  # over HTTP every request is answered with a status, and in process on the
  # spot. Losing the race cancels the probe, which drops it from the
  # transport, so an answer that still arrives finds nothing to settle.
  my $timeout = $self->{transport}->isa('Net::Async::MCP::Transport::Stdio')
    ? $self->discover_timeout : 0;
  if ($timeout) {
    $probe = Future->wait_any(
      $probe,
      $self->loop->delay_future(after => $timeout)->then(sub {
        Future->fail("server/discover got no answer within ${timeout}s",
          'mcp_probe_timeout');
      }),
    );
  }

  my $answered = await $probe->followed_by(sub { Future->done( $_[0] ) });
  return $self->_modern_result($answered->get) if $answered->is_done;

  my ( $why, $category, $error ) = $answered->failure;
  $category //= '';
  my $code = $category eq 'mcp' && ref $error eq 'HASH' ? $error->{code} : undef;

  # A modern server that turned the request down. Falling back to initialize
  # is what the specification rules out here - unless the versions it offers
  # instead are all legacy ones, and taking one of them up is doing what it
  # asks.
  if (defined $code && $MODERN_ERROR_CODES{$code}) {
    my $version = $code == $UNSUPPORTED_PROTOCOL_VERSION
      ? $self->_legacy_offer($error) : undef;
    return await $answered unless defined $version;
    return await $self->_legacy_handshake($version);
  }

  # A failure the server did not send is no sign of a legacy server, and an
  # initialize sent after it would only fail with a less telling message. Over
  # stdio that is a process gone; over HTTP a connection that could not be
  # made or broke off, which the HTTP transport reports in a category of its
  # own (connect, http, timeout, ...). What is left
  # is an answer: a JSON-RPC error, a probe that got none in time, and an HTTP
  # status with no JSON-RPC error in its body, which the HTTP transport reports
  # without a category - the 400 or 404 a legacy server answers a request it
  # does not know before initialize with, above all. A stdio probe that ran
  # out of the request timeout got no answer in time too, only within a
  # shorter limit than discover_timeout - unlike an HTTP timeout, which is a
  # connection that never delivered a status.
  my $stdio_timeout = $category eq 'timeout'
    && $self->{transport}->isa('Net::Async::MCP::Transport::Stdio');
  return await $answered
    unless $category eq 'mcp' || $category eq 'mcp_probe_timeout' || $stdio_timeout
    || ( $category eq '' && $self->{transport}->is_alive );

  my $fallback = await $self->_legacy_handshake($LEGACY_PROTOCOL_VERSIONS[0])
    ->followed_by(sub { Future->done( $_[0] ) });
  return $fallback->get if $fallback->is_done;

  # A server that refused both handshakes speaks neither era, and only both
  # refusals together say so. Anything else - an unspoken version, a process
  # that died - is told best by its own message.
  my ( $failure, $fallback_category, @details ) = $fallback->failure;
  return await $fallback unless ( $fallback_category // '' ) eq 'mcp';
  return await Future->fail("MCP handshake failed: server/discover ($why) and "
    . "initialize ($failure) were both refused", $fallback_category, @details);
}

# Private: the legacy revision to take up from a -32022 that lists no modern
# revision this client speaks - the newest legacy one both sides speak - or
# nothing.
sub _legacy_offer {
  my ( $self, $error ) = @_;
  my $supported = ref $error->{data} eq 'HASH' ? $error->{data}{supported} : undef;
  return unless ref $supported eq 'ARRAY';

  my %offered = map { $_ => 1 } grep { defined && !ref } @$supported;
  for my $version (@LEGACY_PROTOCOL_VERSIONS) {
    return $version if $offered{$version};
  }
  return;
}

# Private: the legacy handshake, asking for $version: initialize, its answer
# checked and kept, then notifications/initialized. With renewal set it starts
# a new session of a connection already legacy, and a failure leaves the era
# as it is.
async sub _legacy_handshake {
  my ( $self, $version, %args ) = @_;
  my $transport = $self->{transport};

  # Set before the request goes out rather than once it is answered: the
  # initialize is a legacy request itself, with no protocol keys in _meta, and
  # a server may ping its client before it answers. The transport switches
  # with it, to a binding where a session is opened by this very request.
  $self->{era} = 'legacy';
  $transport->start_legacy_session if $transport->can('start_legacy_session');

  my $answered = await $self->_request('initialize', {
    protocolVersion => $version,
    capabilities    => {},
    clientInfo      => $self->_client_info,
  }, start_session => 1)->followed_by(sub { Future->done( $_[0] ) });

  unless ( $answered->is_done ) {
    $self->_abandon_legacy unless $args{renewal};
    return await $answered;
  }

  my $result = $answered->get;
  my $agreed = ref $result eq 'HASH' ? $result->{protocolVersion} : undef;

  # The specification leaves a client that does not speak the answered
  # revision one thing to do, which is to stop. The transport is left alone
  # for the caller to shut down.
  unless ( defined $agreed && !ref $agreed
    && grep { $_ eq $agreed } @LEGACY_PROTOCOL_VERSIONS ) {
    $self->_abandon_legacy unless $args{renewal};
    croak "MCP server answered initialize with protocol version '"
      . ( $agreed // '(none)' ) . "', which this client does not speak (it "
      . "speaks " . join(', ', @LEGACY_PROTOCOL_VERSIONS) . " over initialize)";
  }

  $self->{protocol_version}    = $agreed;
  $self->{server_info}         = $result->{serverInfo} // {};
  $self->{server_capabilities} = $result->{capabilities} // {};
  $self->{instructions}        = $result->{instructions};

  # Before the notification rather than after it: everything after the
  # initialize answer carries the agreed revision, notifications/initialized
  # included.
  $transport->set_legacy_protocol_version($agreed)
    if $transport->can('set_legacy_protocol_version');

  await $transport->send_notification('notifications/initialized');

  return $result;
}

# Private: back out of a legacy handshake that did not come off, on the client
# and on a transport that switched binding for it.
sub _abandon_legacy {
  my ( $self ) = @_;
  delete $self->{era};
  my $transport = $self->{transport};
  $transport->end_legacy_session if $transport->can('end_legacy_session');
  return;
}

# Private: a Future for a new legacy session, after a request that went out in
# $expired was answered with the end of that session. Shared by every request
# that needs it, so requests that all ran into the same expired session start
# one new session between them rather than one each; and one that ran into a
# session already replaced needs no new session at all, only to be sent again.
sub _renew_session {
  my ( $self, $expired ) = @_;
  return $self->{session_renewal} if $self->{session_renewal};

  my $transport = $self->{transport};
  my $current   = $transport->can('session_id') ? $transport->session_id : undef;
  return Future->done if defined $current && $current ne $expired;

  my $renewal = $self->_legacy_handshake($self->{protocol_version}, renewal => 1);
  $self->{session_renewal} = $renewal;

  weaken( my $weak_self = $self );
  $renewal->on_ready(sub {
    my $self = $weak_self or return;
    delete $self->{session_renewal};
  });

  return $renewal;
}

# Private: how many pages a list method walks before giving up. Only a cursor
# that comes round again proves a server is looping; one that keeps changing
# while never running out cannot be told apart from a genuinely long list, so
# there has to be an end to it somewhere.
my $MAX_LIST_PAGES = 100;

# Private: every entry of a paginated list method, following nextCursor until
# the server stops handing one out. $key is the result key holding the entries,
# and each page is appended in the order the server sent it.
#
# Anything short of the full list is failed rather than returned. Handing back
# the pages collected so far would be indistinguishable from a server that
# really has that many entries, which is exactly the bug this walk exists to
# fix - it would just move from the first page to the hundredth.
async sub _list_all {
  my ( $self, $method, $key ) = @_;

  my ( @entries, %seen, $cursor );

  for my $page ( 1 .. $MAX_LIST_PAGES ) {
    my $result = await $self->_request($method,
      defined $cursor ? { cursor => $cursor } : undef);

    push @entries, @{ $result->{$key} // [] };

    $cursor = $result->{nextCursor};
    return \@entries unless defined $cursor;

    # A cursor is a position in the list, so being handed one back that was
    # already followed means the server is not moving. Left alone that spins
    # for as long as the server keeps answering.
    croak "MCP $method pagination: server repeated cursor '$cursor'"
      if $seen{$cursor}++;
  }

  croak "MCP $method pagination: server offered more than $MAX_LIST_PAGES pages";
}

async sub list_tools {
  my ( $self ) = @_;
  my $tools = await $self->_list_all('tools/list', 'tools');

  # A fresh listing is the whole truth about the server's tools, so it replaces
  # the cache rather than adding to it - and the whole truth is every page,
  # which is why this runs on the merged list once the walk is through. A walk
  # that failed part way leaves the cache as it was instead of replacing it with
  # what happens to have arrived.
  $self->{tool_header_params} = {
    map { $_->{name} => _header_params($_->{inputSchema}) }
    grep { ref $_ eq 'HASH' && defined $_->{name} } @$tools
  };

  return $tools;
}


# Private: the arguments a server expects mirrored into Mcp-Param-{Name}
# headers - every property annotated with x-mcp-header, reachable from the
# schema root through a chain of "properties" keys and nothing else. Same walk
# as MCP::Tool::_header_params, whose result the server checks the headers
# against, down to sorting by key so both sides agree on order.
sub _header_params {
  my ( $schema, $path ) = @_;
  $path //= [];

  return [] unless ref $schema eq 'HASH' && ref $schema->{properties} eq 'HASH';

  my $properties = $schema->{properties};
  my @params;
  for my $key (sort keys %$properties) {
    my $property = $properties->{$key};
    next unless ref $property eq 'HASH';

    my @next = ( @$path, $key );
    push @params, {
      name => $property->{'x-mcp-header'},
      path => \@next,
      type => $property->{type} // '',
    } if defined $property->{'x-mcp-header'};
    push @params, @{ _header_params($property, \@next) };
  }

  return \@params;
}

# Private: the argument a header parameter points at, or undef if the caller
# passed none. Same walk as MCP::Server::Transport::HTTP::_arg_value, which is
# what the server compares the header against.
sub _arg_value {
  my ( $arguments, $path ) = @_;

  my $value = $arguments;
  for my $key (@$path) {
    return undef unless ref $value eq 'HASH';
    $value = $value->{$key};
  }
  return $value;
}

# Private: an argument value in the form the server's _match_value compares it
# in. Getting this wrong is not a degradation but a rejection: the server
# answers -32020 (HEADER_MISMATCH) for a header that disagrees with the body.
sub _header_value {
  my ( $type, $value ) = @_;

  if ($type eq 'boolean') {
    # A JSON false reaches us either as \0, which JSON::MaybeXS encodes as
    # false, or as a JSON::PP::Boolean. The latter knows it is false, but \0 is
    # a reference and so a *true* Perl value: asking it directly would put
    # "true" in the header while the body says false. Unwrap plain scalar
    # references first, and let an object's own boolean overload speak.
    $value = $$value while ref $value eq 'SCALAR' || ref $value eq 'REF';
    return $value ? 'true' : 'false';
  }

  # Compared numerically by the server, so the number decides, not its
  # spelling. Anything that is not a number at all is passed through as text
  # for the server to reject.
  return 0 + $value if $type eq 'integer' && !ref $value && looks_like_number($value);

  return "$value";
}

# Private: the Mcp-Param-{Name} bindings for a tools/call, as a list of
# name/value pairs with each value already formatted the way the server
# compares it.
async sub _tool_header_params {
  my ( $self, $name, $arguments ) = @_;

  my $transport = $self->{transport};
  return () unless $transport->can('mirrors_header_params')
    && $transport->mirrors_header_params;

  unless (exists $self->{tool_header_params}{$name}) {
    # Calling a tool whose schema this client has never seen is not safe over a
    # binding that mirrors arguments into headers: an annotated argument
    # without its header is rejected outright, so the schema has to be fetched
    # before the call goes out. A failure is deliberately swallowed - the tool
    # may well have no annotated argument at all, and must not become
    # uncallable because an unrelated tools/list failed. The request then goes
    # out bare and the server decides.
    await $self->list_tools->else(sub { Future->done });
  }

  my @params;
  for my $param (@{ $self->{tool_header_params}{$name} // [] }) {
    my $value = _arg_value($arguments, $param->{path});

    # A header the server does not expect is rejected exactly like a missing
    # one, so an argument the caller left out gets no header.
    next unless defined $value;

    push @params, {
      name  => $param->{name},
      value => _header_value($param->{type}, $value),
    };
  }

  return @params;
}

async sub call_tool {
  my ( $self, $name, $arguments ) = @_;
  $arguments //= {};

  my @header_params = await $self->_tool_header_params($name, $arguments);

  my $result = await $self->_request('tools/call',
    {
      name      => $name,
      arguments => $arguments,
    },
    @header_params ? ( header_params => \@header_params ) : (),
  );
  return $result;
}


async sub list_prompts {
  my ( $self ) = @_;
  return await $self->_list_all('prompts/list', 'prompts');
}


async sub get_prompt {
  my ( $self, $name, $arguments ) = @_;
  my $result = await $self->_request('prompts/get', {
    name      => $name,
    arguments => $arguments // {},
  });
  return $result;
}


async sub list_resources {
  my ( $self ) = @_;
  return await $self->_list_all('resources/list', 'resources');
}


async sub read_resource {
  my ( $self, $uri ) = @_;
  my $result = await $self->_request('resources/read', {
    uri => $uri,
  });
  return $result;
}


# Private: the notification a server answers a subscriptions/listen with in
# place of a response. Named to the transport rather than recognised by it -
# see subscriptions_listen.
my $SUBSCRIPTION_ACKNOWLEDGED = 'notifications/subscriptions/acknowledged';

async sub subscriptions_listen {
  my ( $self, $notifications ) = @_;

  # A legacy server sends its list_changed notifications without being asked,
  # and has no subscriptions/listen to ask for them with.
  croak "MCP subscriptions/listen needs protocol revision "
    . "$DEFAULT_PROTOCOL_VERSION; this server speaks legacy revision "
    . "$self->{protocol_version}, which has no subscriptions"
    if $self->is_legacy;

  my $result = await $self->_request('subscriptions/listen',
    { notifications => $notifications // {} },
    resolve_on_notification => $SUBSCRIPTION_ACKNOWLEDGED);
  return $result;
}


async sub subscriptions_stop {
  my ( $self, $subscription_id ) = @_;
  $self->_ensure_transport;

  my $transport = $self->{transport};
  return 0 unless $transport->can('stop_subscription');
  return $transport->stop_subscription($subscription_id);
}


async sub ping {
  my ( $self ) = @_;
  # The current MCP revision moved liveness to the transport level and has no
  # client-addressable JSON-RPC "ping" request. Sending one would fail against
  # MCP::Server >= 0.15 (InProcess errors with -32601); stdio only "succeeded"
  # via an accidental legacy latch. Ask the transport whether it is still
  # usable instead of reporting success unconditionally.
  $self->_ensure_transport;
  croak "MCP transport is not alive" unless $self->{transport}->is_alive;
  return 1;
}


async sub shutdown {
  my ( $self ) = @_;
  if ($self->{transport} && $self->{transport}->can('close')) {
    await $self->{transport}->close;
  }
  return 1;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::MCP - Async MCP (Model Context Protocol) client for IO::Async

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    use IO::Async::Loop;
    use Net::Async::MCP;
    use Future::AsyncAwait;

    my $loop = IO::Async::Loop->new;

    # In-process transport (Perl MCP::Server in same process)
    use MCP::Server;
    my $server = MCP::Server->new(name => 'MyServer');
    $server->tool(
        name         => 'echo',
        description  => 'Echo text',
        input_schema => {
            type       => 'object',
            properties => { message => { type => 'string' } },
            required   => ['message'],
        },
        code => sub { return "Echo: $_[1]->{message}" },
    );

    my $mcp = Net::Async::MCP->new(server => $server);
    $loop->add($mcp);

    # Stdio transport (external MCP server subprocess)
    my $mcp_stdio = Net::Async::MCP->new(
        command => ['npx', '@anthropic/mcp-server-web-search'],
    );
    $loop->add($mcp_stdio);

    # HTTP transport (remote MCP server)
    my $mcp_http = Net::Async::MCP->new(
        url     => 'https://example.com/mcp',
        headers => { Authorization => "Bearer $token" },
    );
    $loop->add($mcp_http);

    # All transports share the same async API:
    async sub main {
        await $mcp->initialize;

        my $tools = await $mcp->list_tools;
        # [{name => 'echo', description => '...', inputSchema => {...}}]

        my $result = await $mcp->call_tool('echo', { message => 'Hello' });
        # {content => [{type => 'text', text => 'Echo: Hello'}], isError => \0}

        await $mcp->shutdown;
    }

    main()->get;

=head1 DESCRIPTION

L<Net::Async::MCP> is an asynchronous client for the MCP (Model Context
Protocol) built on L<IO::Async>. It connects to MCP servers via pluggable
transports:

=over 4

=item * B<InProcess> - Direct calls to an L<MCP::Server> instance in the same
process. See L<Net::Async::MCP::Transport::InProcess>.

=item * B<Stdio> - Subprocess communication over stdin/stdout using
newline-delimited JSON-RPC. Works with any MCP server implementation (Perl,
Node.js, Python, etc.). See L<Net::Async::MCP::Transport::Stdio>.

=item * B<HTTP> - Streamable HTTP transport for remote MCP servers. Supports
both JSON and SSE responses. See L<Net::Async::MCP::Transport::HTTP>.

=back

All methods return L<Future> objects and work with L<Future::AsyncAwait>.
Call L</initialize> first before using any other MCP methods. The client
speaks both eras of the protocol: the modern revision C<2026-07-28>, whose
handshake is a single C<server/discover> and whose requests carry the
client's protocol version, capabilities and info in C<_meta>, and the legacy
revisions C<2025-11-25> back to C<2024-11-05> with their C<initialize>
handshake, which is what servers built on today's SDKs speak. Unless told
otherwise through L</protocol_version>, L</initialize> finds out which one the
server speaks.

Cancelling the L<Future> of a request cancels the request itself - the
transport drops it and, over Stdio, tells the server - on perl 5.24 and later.
On older perls L<Future::AsyncAwait> does not hand a cancel on to the future an
C<async sub> is waiting on: the caller's future is cancelled, but the request
stays pending in the transport until its answer, its timeout or the end of the
connection.

=head2 protocol_version

    my $version = $mcp->protocol_version;

Returns (or via C<configure>/constructor argument C<protocol_version> sets) the
MCP protocol revision this client speaks on the wire, such as C<'2026-07-28'>.
After L</initialize> it is the revision the handshake agreed on. Defaults to
the newest revision this client builds the requests of.

Naming one is a B<pin>, and decides which handshake L</initialize> performs.
Left unset, the client speaks either era and finds out which one the server
speaks - see L</initialize>. Pinned to one of the legacy revisions this client
speaks - C<2025-11-25>, C<2025-06-18>, C<2025-03-26> or C<2024-11-05> - it goes
straight to the C<initialize> handshake and asks for that revision, without
probing first. Pinned to anything else, C<2026-07-28> above all, it speaks the
modern revision only: a C<server/discover> carrying that version, and no
falling back to C<initialize> if the server refuses it.

In the modern revision it is sent on every request inside C<_meta>. A server
that does not speak this revision answers with
C<UNSUPPORTED_PROTOCOL_VERSION> (-32022) and names the ones it does. Where one
of those is a modern revision this client speaks too - one whose request shapes
it builds, which today is exactly one - the request goes out again in it, and this
attribute keeps it, so every following request carries the agreed revision from
the start.

Which revisions those are, and which of them is the default, is this
distribution's own to say. An installed L<MCP::Server> has no part in it:
its C<PROTOCOL_VERSION> is the revision that library implements, and taking
that for the default would put a new version string on requests still built in
the old revision the moment the library learns a newer one - trading a clear
"unsupported protocol version" for a confusing "method not found".

Nothing beyond that one retry: a refusal that offers no usable revision, and a
second refusal after the switch, both reach the caller as the server's own
error with its code and C<data>, because the revisions it named are in there
and in nothing this client could put in its place.

=head2 is_legacy

    await $mcp->initialize;
    say 'legacy server, ', $mcp->protocol_version if $mcp->is_legacy;

True once L</initialize> has settled on a legacy revision - one with the
C<initialize> handshake - and false before that and on a modern connection.
The era is a property of the server, so it is decided by the handshake once
and kept for as long as this client lives.

What differs on a legacy connection: requests carry no
C<io.modelcontextprotocol/*> keys in C<_meta> (a C<_meta> the caller passes
travels as it is), the C<input_required> round trip and the renegotiation of a
refused protocol version are modern-only and do not happen,
L</subscriptions_listen> fails, and a C<ping> the server sends is answered
while every other request it sends is refused with C<-32601>.

Over HTTP a legacy connection is a session: see
L<Net::Async::MCP::Transport::HTTP/Legacy sessions> for the headers it
carries. A server may end the session at any time, which it says by answering
C<404>; the request that ran into it is then sent once more in a new session,
started with a new C<initialize> and C<notifications/initialized> as the
specification asks. Requests that run into the same ended session share one
new session, and requests made while it is being started wait for it. A
request whose new session the server ends straight away as well fails with
C<MCP METHOD: the server ended the new session as well (...)> in category
C<mcp_session_expired>.

=head2 discover_timeout

    my $mcp = Net::Async::MCP->new(
        command          => [ 'npx', '-y', 'some-mcp-server' ],
        discover_timeout => 30,
    );

Returns (or via C<configure>/constructor argument C<discover_timeout> sets) how
many seconds the C<server/discover> probe of L</initialize> waits for an
answer from a stdio server before taking it to be legacy and falling back to
the C<initialize> handshake. Defaults to 10. Set it to C<0> to wait for as
long as it takes.

The trade-off is real and has no right answer: a legacy server may answer an
unknown request with nothing at all, and a modern server that is slow to start
- an C<npx> that first has to fetch its package - looks exactly the same until
it answers. Too short a limit takes a slow modern server for a legacy one, and
its C<initialize> is then refused; too long a limit makes every start of a
silent legacy server wait that long. A server whose era is known is better
pinned through L</protocol_version>, which skips the probe altogether.

Only the stdio transport waits on it. Over HTTP every request is answered with
a status, and the InProcess transport answers on the spot.

A L</timeout> limits the probe as well, being a limit on every request, and
over stdio its running out counts the same as this one: no answer, so the
server is taken to be legacy. Whichever of the two is shorter decides, and a
C<discover_timeout> of C<0> leaves the probe to L</timeout> alone.

=head2 instructions

    my $text = $mcp->instructions;

The free-form usage instructions for a model that the server sent with its
handshake - C<instructions> of the C<server/discover> or the C<initialize>
result - or undef where it sent none. Only available after L</initialize>.

=head2 client_capabilities

    my $caps = $mcp->client_capabilities;
    $mcp->configure(client_capabilities => { sampling => {} });

Returns (or via C<configure>/constructor argument C<client_capabilities> sets)
the HashRef of client capabilities sent on every request inside C<_meta>.
Defaults to C<{}>, an empty declaration, which is what a client that never
touches this attribute keeps sending.

Setting this is a B<promise>, not a hint. A conforming server may not send an
C<inputRequest> for a capability the client did not declare, so the empty
default is precisely what keeps a server from asking this client for anything
it cannot do. Declaring C<sampling>, C<elicitation> or C<roots> here tells the
server it may ask, and what answers it is L</on_input_request> that gives, so
declare a capability only once that handler serves it. This client holds both
ends of the promise: an input request for a capability that is not declared
here is refused as a server violation rather than passed on to the handler.

=head2 headers

    my $headers = $mcp->headers;
    $mcp->configure(headers => { Authorization => "Bearer $token" });

Returns (or via C<configure>/constructor argument C<headers> sets) a HashRef of
extra headers sent with every HTTP request, which is how a server behind OAuth
is reached: nothing else in this client sets an C<Authorization>. Configuring
them after the client has joined a loop works too, so a token can be rotated on
a live client.

They cannot take over a header the MCP binding derives from the request body -
see L<Net::Async::MCP::Transport::HTTP/new> for why that is a rejection rather
than an override. Only the HTTP transport sends headers at all; the InProcess
and Stdio transports ignore this.

=head2 timeout

    my $timeout = $mcp->timeout;

Returns (or via C<configure>/constructor argument C<timeout> sets) the
wall-clock limit in seconds on a single request. Unset by default, because an
MCP C<tools/call> may legitimately run for minutes and a default would break
such a setup. Note that C<0> is a limit of zero seconds rather than "no
limit".

Over HTTP it limits each request the transport sends, and a request that runs
into it fails with C<Timed out> in category C<timeout>, as
L<Net::Async::HTTP> fails it; L</stall_timeout> is the one there that guards
against a hung server without a limit of this kind. Over stdio it is the only
guard against a server that lives but never answers: without it such a request
waits for as long as the subprocess runs. A stdio request that runs into it is
cancelled - the server is sent C<notifications/cancelled> for it - and fails
with C<MCP stdio request METHOD timed out after Ns>, in category C<timeout> as
well, so one check serves both transports. See
L<Net::Async::MCP::Transport::Stdio/timeout>.

Either way the limit is per JSON-RPC request: a call that takes
C<input_required> round trips or a renegotiated version sends several, and
each of them gets the whole limit. The InProcess transport ignores it.

=head2 stall_timeout

    my $stall_timeout = $mcp->stall_timeout;

Returns (or via C<configure>/constructor argument C<stall_timeout> sets) how
many seconds an HTTP request may go without a single byte moving before it is
given up on. Set it to C<0> to switch it off. Undef here means it was never
configured and L<Net::Async::MCP::Transport::HTTP>'s default of 60 seconds
applies. HTTP transport only.

=head2 on_notification

    my $mcp = Net::Async::MCP->new(
        url             => 'https://example.com/mcp',
        on_notification => sub {
            my ( $mcp, $notification ) = @_;
            warn "$notification->{method}\n";
        },
    );

Invoked for every server-initiated notification the transport reads, with the
decoded JSON-RPC notification as it stood on the wire -
C<method> and, where the notification has any, C<params>. The
C<notifications/progress> of a long C<tools/call> is the usual reason to want
one, and it is only worth anything while that call is still running, which is
why it is an event and not part of the L<Future> the call resolves with.

Set it through C<new> or C<configure> like any other event, or implement a
method of this name in a subclass; configuring it on a client that is already
in a loop reaches the transport it built. The first argument is this client,
the same as L</on_input_request> and every other event here gets, even though
it is the transport that receives the notification and starts the call.

A handler set directly on a transport object rather than here is that
transport's own event and is called with the transport - see
L<Net::Async::MCP::Transport::HTTP/on_notification> and
L<Net::Async::MCP::Transport::Stdio/on_notification>.

The HTTP and Stdio transports both deliver what their server sends, and a
handler set here reaches whichever of the two this client built. What reaches
them differs: the HTTP transport reads notifications off the response stream of
a request it is running, while the Stdio transport reads whatever the
subprocess writes, whether a request is in flight or not. The InProcess
transport has nothing a notification could arrive over - it is a direct call
and its return value - so setting this on an in-process client is silently
without effect.

=head2 on_subscription_end

    my $mcp = Net::Async::MCP->new(
        url                  => 'https://example.com/mcp',
        on_subscription_end  => sub {
            my ( $mcp, $subscription_id ) = @_;
        },
    );

Invoked when the stream a subscription runs on ends on its own, with the
subscription id as its second argument - the same id L</subscriptions_listen>
handed back and L</subscriptions_stop> takes. The first argument is this
client, the same as L</on_notification> and every other event here gets, even
though it is the transport that watches the stream and starts the call.

A subscription is answered by its acknowledgement, and the L<Future> of
L</subscriptions_listen> is settled there and then; the stream then runs for
as long as the subscription does. So the only way a subscription can come to
the caller's attention again is its end - and there are two kinds. An end the
caller caused itself, through L</subscriptions_stop>, happens because it asked
for it and is not reported. An end that comes from the server's side - the
server closing the stream, the connection failing underneath it, a gateway
giving up on it - reaches a caller holding nothing but an already-settled
L<Future>, and that is the end this event reports, the moment the stream ends.
A caller waiting on L</subscriptions_stop> for false, to learn the same thing,
would learn it only when it thought to ask.

Set it through C<new> or C<configure> like any other event, or implement a
method of this name in a subclass; configuring it on a client that is already
in a loop reaches the transport it built. A handler set directly on a
transport object rather than here is that transport's own event and is called
with the transport - see L<Net::Async::MCP::Transport::HTTP/on_subscription_end>.

Only L<Net::Async::MCP::Transport::HTTP> can fire it: it is the only transport
with a stream a subscription runs on, and L</subscriptions_listen> says as
much. Setting this on a Stdio or InProcess client is therefore silently
without effect.

=head2 env

    my $mcp = Net::Async::MCP->new(
        command => [ 'npx', '-y', '@modelcontextprotocol/server-github' ],
        env     => { GITHUB_PERSONAL_ACCESS_TOKEN => $token },
    );

A HashRef laid over C<%ENV> for the server subprocess: a key with a value sets
that variable, a key whose value is C<undef> removes it. Stdio transport only -
see L<Net::Async::MCP::Transport::Stdio/env>.

=head2 cwd

The working directory the server subprocess starts in. Stdio transport only -
see L<Net::Async::MCP::Transport::Stdio/cwd>.

=head2 on_stderr

    my $mcp = Net::Async::MCP->new(
        command   => [ 'my-mcp-server' ],
        on_stderr => sub {
            my ( $mcp, $line ) = @_;
            warn "mcp: $line\n";
        },
    );

Invoked for every line the server subprocess writes to its stderr, decoded and
without its line ending, with this client as the first argument. Stderr is the
server's free-form log, never an error; the last 20 lines of it are quoted in
the failure of every request the subprocess leaves unanswered when it exits,
whether or not this is set. Stdio transport only - see
L<Net::Async::MCP::Transport::Stdio/on_stderr>.

=head2 on_input_request

    my $mcp = Net::Async::MCP->new(
        server              => $server,
        client_capabilities => { elicitation => {} },
        on_input_request    => sub {
            my ( $mcp, $method, $params ) = @_;
            # $method is 'elicitation/create', 'sampling/createMessage', ...
            return { action => 'accept', content => { ok => \1 } };
        },
    );

Invoked for every input request a server embeds in a result, and returns the
response to it - either the response structure itself, or a L<Future> that will
resolve with one, which is what lets a handler go and ask a human. The
C<$params> are the request's own, whatever the asked-for method takes: a
C<message> and C<requestedSchema> for C<elicitation/create>, the messages for
C<sampling/createMessage>, and so on.

One handler serves every kind of input request rather than one attribute per
capability, because the set of methods a server may ask for is the
specification's to grow, and a caller branching on C<$method> keeps working
when it does.

Set it through C<new> or C<configure>, or implement a method of this name in a
subclass - it is an ordinary L<IO::Async::Notifier> event, so both work.
Handlers are called one after another, in the order of the request keys, so a
handler that asks a user two questions asks them one at a time.

Its return value goes on the wire as it is, under the key the server gave the
request, and must be a HashRef; C<< { action => 'accept', content => {...} } >>
is what a server expects for an C<elicitation/create>. See
L</Input required results> for the round trip this handler is one half of.

=head2 Input required results

A server that needs something from the client before it can finish answers with
an C<input_required> result instead of a final one - C<resultType> set to
C<input_required>, optionally C<inputRequests> naming what it wants, and
optionally an opaque C<requestState>. SEP-2322 made this the way sampling,
elicitation and roots reach a client: not as requests the server sends, but as
a result the client answers by asking the same question again.

Every method of this client walks that round trip itself and returns the final
result, so a caller never sees an C<input_required>:

=over 4

=item *

C<inputRequests> are handed one by one to L</on_input_request>, and its answers
travel back as C<inputResponses> under the very keys the server used.

=item *

C<requestState> is mirrored back untouched. It is sealed and bound by the
server, so this client never parses, inspects or edits it, and a result that
carries none is retried without one.

=item *

A result with a C<requestState> and no C<inputRequests> is a server asking for
nothing but the call again, and is retried straight away without troubling the
handler.

=back

Four things fail the L<Future> instead, loudly, because each of them would
otherwise leave the caller with a result that looks final and is not:

=over 4

=item *

An C<inputRequests> entry for a capability that L</client_capabilities> does
not declare. A conforming server may not ask for one, so this is named as the
server violation it is rather than passed to the handler.

=item *

An C<inputRequests> with no L</on_input_request> to answer it.

=item *

More than eight C<input_required> results in a row on one request. A server may
legitimately ask twice, but one that never arrives at a result has to be given
up on somewhere.

=item *

An C<input_required> result carrying neither of the two, which leaves nothing
to answer and nothing to send back.

=back

=head2 server_info

    my $info = $mcp->server_info;

Returns the server info hashref from the handshake - C<result._meta> of a
modern C<server/discover>, C<serverInfo> of a legacy C<initialize>. Contains at
minimum C<name> and C<version> keys. Only available after L</initialize> has
been called.

=head2 server_capabilities

    my $caps = $mcp->server_capabilities;

Returns the server capabilities hashref from the handshake response, modern or
legacy. Only available after L</initialize> has been called.

=head2 initialize

    my $result = await $mcp->initialize;

Performs the MCP handshake. Must be called before any other MCP method. This
client speaks both eras of the protocol, and which handshake this is depends on
the server:

=over 4

=item * B<Modern> - revision C<2026-07-28>. The handshake is a single
C<server/discover> request carrying the client's protocol version and
L</client_capabilities> in C<_meta>, and the server answers with its
capabilities and, in C<result._meta>, its server info. No
C<notifications/initialized> follows it: SEP-2575 removed the
C<initialize>/C<initialized> pair, and the Streamable HTTP binding of this
revision defines no client-to-server notifications at all.

=item * B<Legacy> - revisions C<2025-11-25>, C<2025-06-18>, C<2025-03-26> and
C<2024-11-05>, which every third-party server speaks today. The handshake is
an C<initialize> request carrying C<protocolVersion>, C<capabilities> and
C<clientInfo>, answered with the server's C<protocolVersion>,
C<capabilities>, C<serverInfo> and maybe C<instructions>, and followed by a
C<notifications/initialized>. A server that answers with a revision this
client does not speak fails the handshake with a message naming it and the
ones this client speaks, and the transport is left as it is for
L</shutdown>. The legacy handshake declares no client capabilities, whatever
L</client_capabilities> says: a legacy server asks for sampling, elicitation
or roots with requests of its own, which this client does not serve.

=back

Which one, is decided by L</protocol_version>. Pinned to a legacy revision,
the legacy handshake asks for it; pinned to anything else, the modern
handshake is the only one tried. Left unset, the client finds out the way the
specification gives for a client of both eras: it probes with a
C<server/discover> of the newest modern revision, and

=over 4

=item * an answer means the server is modern, and that is the handshake;

=item * one of the errors only a modern server sends (C<-32020>, C<-32021>,
C<-32022>) means the server is modern too, and its error is what the call
fails with - except a C<-32022> whose list of supported versions holds only
legacy revisions, of which the newest one this client speaks too is then
asked for with C<initialize>;

=item * any other error, or no answer within L</discover_timeout> - or
L</timeout>, where that is shorter - on a stdio server, means the server is
legacy, and the C<initialize> handshake follows
with the newest legacy revision. Should that fail as well, the failure names
what happened to both.

=back

Over HTTP an answer is anything the server sent back: a JSON-RPC error in the
body, whatever the status, is read as above - a C<400> carrying C<-32022> is a
modern server - and a status without one, the C<400> or C<404> a legacy server
answers a request before C<initialize> with, means legacy. What is not an
answer does not fall back: a probe the subprocess of a stdio server did not
live through fails with the exit, and one over a connection that could not be
made - refused, an unknown host, a timeout - fails with that. A probe answer
that arrives after the fallback has begun is dropped.

Returns the raw result hashref of the handshake: C<capabilities> plus C<_meta>
containing C<io.modelcontextprotocol/serverInfo> for a modern server, the
C<InitializeResult> for a legacy one. Also populates L</server_info>,
L</server_capabilities>, L</instructions>, L</protocol_version> and
L</is_legacy>.

=head2 list_tools

    my $tools = await $mcp->list_tools;

Returns an ArrayRef of tool definition hashrefs from the MCP server. Each
hashref contains C<name>, C<description>, and C<inputSchema> keys.

Also caches, per tool, which of its arguments are annotated with
C<x-mcp-header> in the input schema, which L</call_tool> needs to build the
C<Mcp-Param-{Name}> headers of the HTTP binding.

Paginated tool lists are walked to the end: as long as the server answers with
a C<nextCursor>, the next page is requested with that C<cursor> and its tools
appended, so both the returned list and the cache cover every page. Nothing
short of the whole list is ever returned - a server that keeps handing back a
cursor it already gave out, or that offers more than 100 pages, fails the
returned L<Future> instead, because a quietly truncated list is the same bug
this walk is here to fix.

=head2 call_tool

    my $result = await $mcp->call_tool($name, \%arguments);

Calls a named tool on the MCP server with the given arguments hashref.
Returns a hashref with C<content> (ArrayRef of content blocks) and C<isError>
(boolean).

A tool may annotate arguments in its input schema with C<x-mcp-header>, which
over the HTTP binding have to be mirrored into C<Mcp-Param-{Name}> headers; a
conforming server rejects a C<tools/call> that passes such an argument without
its header, and equally one that carries a header for an argument it did not
pass. This method resolves them from the tool's input schema, which means it
needs the schema: on a transport that mirrors headers it fetches L</list_tools>
once for a tool it has not seen, and keeps using the cached schemas afterwards.
If that fetch fails the call is still sent, without headers, leaving the
decision to the server.

Transports that do not mirror headers - InProcess and Stdio - resolve nothing
and never fetch a tool list on their own.

=head2 list_prompts

    my $prompts = await $mcp->list_prompts;

Returns an ArrayRef of prompt definition hashrefs from the MCP server.
Paginated results are followed to the end and merged, on the same terms as
L</list_tools>.

=head2 get_prompt

    my $result = await $mcp->get_prompt($name, \%arguments);

Retrieves a named prompt from the MCP server, optionally passing arguments.
Returns the prompt result hashref.

=head2 list_resources

    my $resources = await $mcp->list_resources;

Returns an ArrayRef of resource definition hashrefs from the MCP server.
Paginated results are followed to the end and merged, on the same terms as
L</list_tools>.

=head2 read_resource

    my $result = await $mcp->read_resource($uri);

Reads a resource by URI from the MCP server. Returns the resource content
hashref.

=head2 subscriptions_listen

    my $subscription = await $mcp->subscriptions_listen({ toolsListChanged => 1 });
    my $id = $subscription->{_meta}{'io.modelcontextprotocol/subscriptionId'};

Opens a C<subscriptions/listen> subscription on the MCP server, requesting
server-initiated notifications. C<$notifications> is a hashref mapping
notification types to a truthy value (e.g. C<toolsListChanged>,
C<promptsListChanged>, C<resourcesListChanged>). The request carries the
standard C<_meta> like all client methods.

A server does not answer this request with a response. It opens a stream,
writes C<notifications/subscriptions/acknowledged> onto it, and then holds the
stream open to carry the notifications that were subscribed to. This method
returns that acknowledgement's C<params>: the subscription id under C<_meta>,
and under C<notifications> the types the server actually honoured, which need
not be everything that was asked for. The notifications themselves arrive at
L</on_notification>, like every other server-initiated notification, and the
acknowledgement does not - it is this request's answer rather than something
that happened while it waited.

Which notification answers the request is told to the transport rather than
recognised by it, so that a transport executes what the protocol layer decided
instead of reading method names and deciding for itself.

Ending a subscription is L</subscriptions_stop>. There is no request for it:
closing the stream is what unsubscribes, and a server drops the subscription
when its stream finishes.

Only L<Net::Async::MCP::Transport::HTTP> has a stream to run this on. The
InProcess transport refuses C<subscriptions/listen> outright, and a server
without notification support answers JSON-RPC error -32601
(C<METHOD_NOT_FOUND>); either way the returned L<Future> fails. The Stdio
transport refuses it as well: L<MCP::Server> E<gt>= 0.15 serves the method
over stdio too, answering with a C<notifications/subscriptions/acknowledged>
notification where HTTP would answer with a response, and a transport that
cannot settle a request from a notification says so rather than wait for an
answer that will not come.

Subscriptions are the modern revision's. On a legacy connection - see
L</is_legacy> - this fails without sending anything: a legacy server sends its
notifications unasked and has no C<subscriptions/listen> to answer.

=head2 subscriptions_stop

    my $stopped = await $mcp->subscriptions_stop($subscription_id);

Ends the subscription of that id, and resolves with true if there was one to
end. The C<$subscription_id> is the one L</subscriptions_listen> handed back
in C<< $subscription->{_meta}{'io.modelcontextprotocol/subscriptionId'} >>.

Unsubscribing is closing the stream the subscription runs on. The current
revision has no request that cancels a subscription and no acknowledgement of
one, so nothing goes on the wire and the server drops the subscription when
its stream finishes.

Resolves with false for an id no subscription is running under - one that was
never opened, one already stopped, and one whose stream has ended on its own,
which are not told apart. It is also false on a transport that cannot
subscribe at all, since neither the InProcess nor the Stdio transport has a
stream a subscription could run on.

That makes this the way to ask whether a subscription is still running. The
prompt way is L</on_subscription_end>, which fires the moment a stream ends on
its own - the server closing it, the connection failing - because the
L<Future> of L</subscriptions_listen> was settled by the acknowledgement long
before and cannot report it. This method is what a caller that missed the
event, or did not set one, falls back on. See
L<Net::Async::MCP::Transport::HTTP/stop_subscription>.

=head2 ping

    await $mcp->ping;

Performs a transport-level liveness check and returns C<1>. The current MCP
revision moved liveness to the transport layer and has no client-addressable
JSON-RPC C<ping> request, so no request goes on the wire; sending one would
fail against L<MCP::Server> E<gt>= 0.15.

Instead the transport's C<is_alive> is consulted, and the returned L<Future>
fails if the transport can no longer carry requests: for
L<Net::Async::MCP::Transport::Stdio> that means the subprocess has exited,
while the InProcess and HTTP transports have no connection state and are
always alive.

=head2 shutdown

    await $mcp->shutdown;

Cleanly shuts down the MCP connection. For the Stdio transport this closes the
subprocess's stdin, sends SIGTERM if it is still running 2 seconds later and
SIGKILL 2 seconds after that, and waits for it to exit - see
L<Net::Async::MCP::Transport::Stdio/close>. For the HTTP transport it
ends every subscription still running, that being the one thing it holds which
outlives the request that opened it, and on a legacy connection with a session
sends the C<DELETE> that ends the session; a refusal of it other than C<405>
or C<404> fails the returned L<Future> - see
L<Net::Async::MCP::Transport::HTTP/close>. For the InProcess
transport it is a no-op: a direct call and its return value leave nothing
behind.

=head1 SEE ALSO

=over 4

=item * L<Net::Async::MCP::Transport::InProcess> - In-process transport for Perl MCP servers

=item * L<Net::Async::MCP::Transport::Stdio> - Subprocess transport via stdin/stdout

=item * L<Net::Async::MCP::Transport::HTTP> - Streamable HTTP transport for remote servers

=item * L<IO::Async::Notifier> - Base class

=item * L<Future::AsyncAwait> - Async/await syntax used with this module

=item * L<https://modelcontextprotocol.io> - MCP specification

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-mcp/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
