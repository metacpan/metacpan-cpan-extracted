package SignalWire::Relay::Client;
use strict;
use warnings;
use Moo;

use JSON qw(encode_json decode_json);
use IO::Socket::INET;
use IO::Socket::SSL;
use Protocol::WebSocket::Client;
use SignalWire::Relay::Constants qw(
    PROTOCOL_VERSION
    CALL_TERMINAL_STATES
    DIAL_STATE_ANSWERED DIAL_STATE_FAILED
    MESSAGE_TERMINAL_STATES
);
use SignalWire::Relay::Event;
use SignalWire::Relay::Call;
use SignalWire::Relay::Message;
use SignalWire::Logging;

my $logger = SignalWire::Logging->get_logger('relay_client');

has 'project'  => ( is => 'ro', default => sub { '' } );
has 'token'    => ( is => 'ro', default => sub { '' } );
has 'host'     => ( is => 'ro', required => 1 );
has 'contexts' => ( is => 'rw', default => sub { [] } );
has 'agent'    => ( is => 'ro', default => sub { 'signalwire-agents-perl/1.0' } );
# Optional JWT-based authentication (alternative to project/token).
has 'jwt_token' => ( is => 'ro', default => sub { '' } );
has '_jwt_token' => ( is => 'rw', default => sub { '' } );
# Scheme: "wss" (production, TLS — the default) or "ws" (plain, used by
# the local audit fixture in audit_relay_handshake.py). Keeping this
# explicit lets the same client drive both real RELAY and a 127.0.0.1
# fixture without forking the transport.
has 'scheme'   => ( is => 'ro', default => sub { 'wss' } );
# Path component appended to the host. Defaults to '/api/relay/ws' (the
# documented production endpoint per RELAY_IMPLEMENTATION_GUIDE).
has 'path'     => ( is => 'ro', default => sub { '/api/relay/ws' } );

# Connection state
has 'protocol'            => ( is => 'rw', default => sub { '' } );
has 'authorization_state' => ( is => 'rw', default => sub { '' } );
has 'connected'           => ( is => 'rw', default => sub { 0 } );
has 'session_id'          => ( is => 'rw', default => sub { '' } );

# Aliases for Python parity (same value, different names).
sub relay_protocol { $_[0]->protocol }
sub _connected     { $_[0]->connected }
sub _authorization_state { $_[0]->authorization_state }

# Correlation maps
has '_pending'       => ( is => 'rw', default => sub { {} } );  # rpc_id => { resolve => sub, reject => sub }
has '_calls'         => ( is => 'rw', default => sub { {} } );  # call_id => Call
has '_pending_dials' => ( is => 'rw', default => sub { {} } );  # tag => { resolve => sub, reject => sub }
has '_messages'      => ( is => 'rw', default => sub { {} } );  # message_id => Message

# WebSocket internals
has '_socket' => ( is => 'rw', default => sub { undef } );
has '_ws'     => ( is => 'rw', default => sub { undef } );

# Reconnect state
has '_reconnect_attempts' => ( is => 'rw', default => sub { 0 } );
has '_max_backoff'        => ( is => 'ro', default => sub { 30 } );

# Callbacks
has '_on_call'    => ( is => 'rw', default => sub { undef } );
has '_on_message' => ( is => 'rw', default => sub { undef } );
has '_on_event'   => ( is => 'rw', default => sub { undef } );

# --- UUID generation ---
sub _generate_uuid {
    my @hex = map { sprintf('%02x', int(rand(256))) } 1..16;
    $hex[6] = sprintf('%02x', (hex($hex[6]) & 0x0f) | 0x40);
    $hex[8] = sprintf('%02x', (hex($hex[8]) & 0x3f) | 0x80);
    return join('-',
        join('', @hex[0..3]),
        join('', @hex[4..5]),
        join('', @hex[6..7]),
        join('', @hex[8..9]),
        join('', @hex[10..15]),
    );
}

# --- Public API: register handlers ---

sub on_call {
    my ($self, $cb) = @_;
    $self->_on_call($cb);
    return $self;
}

sub on_message {
    my ($self, $cb) = @_;
    $self->_on_message($cb);
    return $self;
}

sub on_event {
    my ($self, $cb) = @_;
    $self->_on_event($cb);
    return $self;
}

# --- Connection ---

# Public connect: opens the WebSocket and runs the signalwire.connect
# handshake in one call (matches Python RelayClient.connect()). Returns
# the authenticate result hashref on success, dies on failure.
sub connect {
    my ($self) = @_;
    die "project and token are required (or jwt_token)"
        unless ($self->project && $self->token) || $self->jwt_token || $self->_jwt_token;
    my $ok = $self->connect_ws;
    die "WebSocket connect failed" unless $ok;
    return $self->authenticate;
}

# Public disconnect: tears down the WebSocket transport. Mirrors
# Python RelayClient.disconnect().
sub disconnect {
    my ($self) = @_;
    return $self->disconnect_ws;
}

sub connect_ws {
    my ($self) = @_;

    my $scheme = $self->scheme || 'wss';
    my $raw_host = $self->host;

    # `host` may be a bare hostname ("example.com") or a hostname+port
    # ("127.0.0.1:9000"). Split if needed; otherwise pick the default
    # port for the scheme.
    my ($host, $port);
    if ($raw_host =~ /^(.+):(\d+)$/) {
        ($host, $port) = ($1, $2);
    } else {
        $host = $raw_host;
        $port = ($scheme eq 'ws') ? 80 : 443;
    }

    my $url = "$scheme://$raw_host" . $self->path;
    $logger->debug("Connecting to $url");

    my $socket;
    if ($scheme eq 'ws') {
        # Plain TCP — used by the local audit fixture. No TLS, no
        # certificate validation. Production relay never runs over
        # plain ws://.
        $socket = IO::Socket::INET->new(
            PeerHost => $host,
            PeerPort => $port,
            Proto    => 'tcp',
            Timeout  => 10,
        );
        unless ($socket) {
            $logger->error("TCP connection failed: $!");
            return 0;
        }
    } else {
        $socket = IO::Socket::SSL->new(
            PeerHost        => $host,
            PeerPort        => $port,
            SSL_verify_mode => SSL_VERIFY_PEER,
            Timeout         => 10,
        );
        unless ($socket) {
            $logger->error("SSL connection failed: $! $IO::Socket::SSL::SSL_ERROR");
            return 0;
        }
    }

    my $ws = Protocol::WebSocket::Client->new(url => $url);

    $ws->on(write => sub {
        my ($ws_client, $buf) = @_;
        syswrite($socket, $buf);
    });

    $ws->on(connect => sub {
        $logger->debug("WebSocket connected");
    });

    $ws->on(error => sub {
        my ($ws_client, $error) = @_;
        $logger->error("WebSocket error: $error");
    });

    $ws->on(read => sub {
        my ($ws_client, $message) = @_;
        $self->_handle_message($message);
    });

    $self->_socket($socket);
    $self->_ws($ws);

    # Initiate the WebSocket handshake
    $ws->connect;

    # Read the handshake response
    my $buf = '';
    while (my $bytes = sysread($socket, $buf, 4096, length($buf))) {
        $ws->read($buf);
        $buf = '';
        last if $ws->{hs}->is_done;
    }

    $self->connected(1);
    $self->_reconnect_attempts(0);
    return 1;
}

sub authenticate {
    my ($self) = @_;

    # Build authentication block: either project/token or jwt_token.
    my %auth;
    my $jwt = $self->jwt_token || $self->_jwt_token;
    if ($jwt) {
        $auth{jwt_token} = $jwt;
    } else {
        $auth{project} = $self->project;
        $auth{token}   = $self->token;
    }

    my %params = (
        version        => PROTOCOL_VERSION,
        agent          => $self->agent,
        event_acks     => JSON::true,
        authentication => \%auth,
    );
    # Mirror project/token at the top level when not using JWT (Rust agent
    # convention; production tolerates both shapes).
    unless ($jwt) {
        $params{project} = $self->project;
        $params{token}   = $self->token;
    }

    # Add contexts if any
    if (@{$self->contexts}) {
        $params{contexts} = $self->contexts;
    }

    # Add protocol for session resume
    if ($self->protocol) {
        $params{protocol} = $self->protocol;
    }

    # Add authorization_state for fast re-auth
    if ($self->authorization_state) {
        $params{authorization_state} = $self->authorization_state;
    }

    my $result = $self->execute('signalwire.connect', \%params);

    if (ref $result eq 'HASH') {
        $self->protocol($result->{protocol}) if $result->{protocol};
        $self->session_id($result->{session_id}) if $result->{session_id};
    }

    return $result;
}

# --- JSON-RPC execute ---

sub execute {
    my ($self, $method, $params) = @_;
    $params //= {};

    my $id = _generate_uuid();

    # Add protocol to params (except for signalwire.connect itself)
    if ($method ne 'signalwire.connect' && $self->protocol) {
        $params->{protocol} = $self->protocol;
    }

    my $request = {
        jsonrpc => '2.0',
        id      => $id,
        method  => $method,
        params  => $params,
    };

    # Register pending
    my $result;
    my $done = 0;
    my $error;
    $self->_pending->{$id} = {
        resolve => sub { $result = $_[0]; $done = 1 },
        reject  => sub { $error = $_[0]; $done = 1 },
    };

    $self->_send($request);

    # Poll for response (synchronous in this implementation)
    my $timeout = 30;
    my $start = time();
    while (!$done && (time() - $start) < $timeout) {
        $self->_read_once();
    }

    delete $self->_pending->{$id};

    if ($error) {
        die "RELAY error: $error";
    }

    return $result;
}

# --- Messaging ---

sub send_message {
    my ($self, %opts) = @_;

    die "At least one of body or media is required"
        unless (defined $opts{body} && length $opts{body})
            || (ref $opts{media} eq 'ARRAY' && @{$opts{media}});

    # Default context to the relay protocol or 'default' (matches Python).
    my $msg_context = $opts{context} // $self->protocol // '';
    $msg_context = 'default' unless length $msg_context;

    my %params = (
        context     => $msg_context,
        to_number   => $opts{to_number}   // '',
        from_number => $opts{from_number} // '',
    );
    $params{body}   = $opts{body}   if defined $opts{body}   && length $opts{body};
    $params{media}  = $opts{media}  if ref $opts{media} eq 'ARRAY' && @{$opts{media}};
    $params{tags}   = $opts{tags}   if ref $opts{tags}  eq 'ARRAY' && @{$opts{tags}};
    $params{region} = $opts{region} if defined $opts{region} && length $opts{region};

    my $result = $self->execute('messaging.send', \%params);

    if (ref $result eq 'HASH' && $result->{message_id}) {
        my $msg = SignalWire::Relay::Message->new(
            message_id  => $result->{message_id},
            context     => $opts{context}     // '',
            direction   => 'outbound',
            from_number => $opts{from_number} // '',
            to_number   => $opts{to_number}   // '',
            body        => $opts{body}        // '',
            media       => $opts{media}       // [],
            tags        => $opts{tags}        // [],
            state       => 'queued',
        );
        $self->_messages->{$result->{message_id}} = $msg;

        if ($opts{on_completed}) {
            $msg->on_completed($opts{on_completed});
        }

        return $msg;
    }

    return $result;
}

# --- Context management ---

sub receive {
    my ($self, $contexts) = @_;
    # Python parity: receive(contexts: list[str]). Canonical form takes
    # an arrayref. Backward-compat: also accept slurpy
    # (``$client->receive('ctx1', 'ctx2')``) — re-grab @_ when the first
    # arg is a string and there are extras.
    my @ctxs;
    if (ref $contexts eq 'ARRAY') {
        @ctxs = @$contexts;
    } else {
        @ctxs = @_;
        shift @ctxs;  # drop $self
    }
    return unless @ctxs;
    return $self->execute('signalwire.receive', { contexts => \@ctxs });
}

sub unreceive {
    my ($self, $contexts) = @_;
    # Python parity: unreceive(contexts: list[str]).
    my @ctxs;
    if (ref $contexts eq 'ARRAY') {
        @ctxs = @$contexts;
    } else {
        @ctxs = @_;
        shift @ctxs;  # drop $self
    }
    return unless @ctxs;
    return $self->execute('signalwire.unreceive', { contexts => \@ctxs });
}

# --- Dial ---

sub dial {
    my ($self, %opts) = @_;
    my $tag = $opts{tag} || _generate_uuid();
    my $timeout = delete $opts{timeout} || 120;
    my $on_completed = delete $opts{on_completed};

    my %params = ( tag => $tag );
    $params{devices} = $opts{devices} if $opts{devices};
    $params{region} = $opts{region} if $opts{region};
    $params{max_price_per_minute} = $opts{max_price_per_minute} if exists $opts{max_price_per_minute};

    # Register pending dial BEFORE sending RPC
    my $call;
    my $done = 0;
    my $dial_error;
    $self->_pending_dials->{$tag} = {
        resolve => sub { $call = $_[0]; $done = 1 },
        reject  => sub { $dial_error = $_[0]; $done = 1 },
    };

    # Send the RPC -- response is just {code:200, message:"Dialing"}
    eval { $self->execute('calling.dial', \%params) };
    if ($@) {
        delete $self->_pending_dials->{$tag};
        die $@;
    }

    # Wait for calling.call.dial event to resolve
    my $start = time();
    while (!$done && (time() - $start) < $timeout) {
        $self->_read_once();
    }

    delete $self->_pending_dials->{$tag};

    if ($dial_error) {
        die "Dial failed: $dial_error";
    }

    if ($call && $on_completed) {
        $call->on(sub {
            my ($c, $event) = @_;
            if ($event->event_type eq 'calling.call.state' && $event->call_state eq 'ended') {
                eval { $on_completed->($c) };
                warn "dial on_completed error: $@" if $@;
            }
        });
    }

    return $call;
}

# --- Internal: send a JSON-RPC message ---

sub _send {
    my ($self, $msg) = @_;
    my $json = encode_json($msg);
    $logger->debug("SEND: $json");
    my $ws = $self->_ws;
    if ($ws) {
        $ws->write($json);
    }
}

# --- Internal: read one frame from WebSocket ---

sub _read_once {
    my ($self) = @_;
    my $socket = $self->_socket;
    return unless $socket;

    my $buf = '';
    my $ready = '';
    vec($ready, fileno($socket), 1) = 1;
    if (select($ready, undef, undef, 0.1)) {
        my $bytes = sysread($socket, $buf, 4096);
        if ($bytes && $bytes > 0) {
            $self->_ws->read($buf);
        } elsif (!defined $bytes || $bytes == 0) {
            # Connection lost
            $self->connected(0);
        }
    }
}

# --- Internal: handle an incoming WebSocket message ---

sub _handle_message {
    my ($self, $raw) = @_;
    $logger->debug("RECV: $raw");

    # Skip non-JSON-text frames. Protocol::WebSocket::Client doesn't
    # surface frame opcode in on_read, so we sniff: a JSON-RPC frame
    # always starts with '{'. Close/ping/pong control frames have a
    # 16-bit status code or short binary payload that won't begin with
    # '{', and decoding them as JSON would just spam the log.
    return unless defined $raw && length $raw;
    my $first;
    if (utf8::is_utf8($raw)) {
        $first = substr($raw, 0, 1);
    } else {
        $first = substr($raw, 0, 1);
    }
    return unless defined $first && $first eq '{';

    # decode_json expects a byte string; if the payload arrived flagged
    # utf8 (Perl saw a multibyte char in transit) we need to re-encode
    # before parsing. Otherwise we hit "Wide character in subroutine entry".
    my $msg;
    if (utf8::is_utf8($raw)) {
        my $bytes = $raw;
        utf8::encode($bytes);
        eval { $msg = decode_json($bytes) };
    } else {
        eval { $msg = decode_json($raw) };
    }
    if ($@) {
        $logger->error("JSON parse error: $@");
        return;
    }

    # JSON-RPC response (has "result" or "error", matched by "id")
    if (exists $msg->{result} || exists $msg->{error}) {
        my $id = $msg->{id} // '';
        if (my $pending = delete $self->_pending->{$id}) {
            if (exists $msg->{error}) {
                $pending->{reject}->($msg->{error});
            } else {
                $pending->{resolve}->($msg->{result});
            }
        }
        return;
    }

    # Server-initiated method call
    my $method = $msg->{method} // '';

    if ($method eq 'signalwire.event') {
        # ACK the event immediately
        $self->_send_ack($msg->{id});
        $self->_handle_event($msg->{params} // {});
    }
    elsif ($method eq 'signalwire.ping') {
        $self->_send_ack($msg->{id});
    }
    elsif ($method eq 'signalwire.disconnect') {
        $self->_send_ack($msg->{id});
        $self->_handle_disconnect($msg->{params} // {});
    }
}

# --- Internal: send an ACK ---

sub _send_ack {
    my ($self, $id) = @_;
    $self->_send({
        jsonrpc => '2.0',
        id      => $id,
        result  => {},
    });
}

# --- Internal: handle events ---

sub _handle_event {
    my ($self, $outer_params) = @_;
    my $event_type = $outer_params->{event_type} // '';
    my $inner_params = $outer_params->{params} // {};

    # Parse into typed event object
    my $event = SignalWire::Relay::Event->parse_event($event_type, $inner_params);

    # Fire global event callback
    if (my $cb = $self->_on_event) {
        eval { $cb->($event) };
        warn "on_event callback error: $@" if $@;
    }

    # --- Authorization state ---
    if ($event_type eq 'signalwire.authorization.state') {
        $self->authorization_state($inner_params->{authorization_state} // '');
        return;
    }

    # --- Inbound call ---
    if ($event_type eq 'calling.call.receive') {
        $self->_handle_inbound_call($event, $inner_params);
        return;
    }

    # --- Inbound message ---
    if ($event_type eq 'messaging.receive') {
        $self->_handle_inbound_message($event);
        return;
    }

    # --- Message state ---
    if ($event_type eq 'messaging.state') {
        my $message_id = $inner_params->{message_id} // '';
        if (my $msg = $self->_messages->{$message_id}) {
            $msg->dispatch_event($event);
            if ($msg->completed) {
                delete $self->_messages->{$message_id};
            }
        }
        return;
    }

    # --- Dial completion ---
    if ($event_type eq 'calling.call.dial') {
        $self->_handle_dial_event($event, $inner_params);
        return;
    }

    # --- State events during dial (call not registered yet) ---
    my $call_id = $inner_params->{call_id} // '';
    my $tag = $inner_params->{tag} // '';

    if ($event_type eq 'calling.call.state' && $tag && exists $self->_pending_dials->{$tag}) {
        if (!exists $self->_calls->{$call_id} && $call_id) {
            # Create the Call object so events route correctly
            my $call = SignalWire::Relay::Call->new(
                call_id => $call_id,
                node_id => $inner_params->{node_id} // '',
                tag     => $tag,
                device  => $inner_params->{device} // {},
                _client => $self,
            );
            $self->_calls->{$call_id} = $call;
        }
    }

    # --- Normal routing by call_id ---
    if ($call_id && (my $call = $self->_calls->{$call_id})) {
        $call->dispatch_event($event);

        # Clean up ended calls
        if ($call->state eq 'ended') {
            delete $self->_calls->{$call_id};
        }
    }
}

# --- Internal: handle inbound call ---

sub _handle_inbound_call {
    my ($self, $event, $params) = @_;
    my $call_id = $params->{call_id} // '';
    return unless $call_id;

    my $call = SignalWire::Relay::Call->new(
        call_id => $call_id,
        node_id => $params->{node_id} // '',
        tag     => $params->{tag}     // '',
        device  => $params->{device}  // {},
        context => $params->{context} // '',
        state   => $params->{call_state} // 'ringing',
        _client => $self,
    );
    $self->_calls->{$call_id} = $call;

    if (my $cb = $self->_on_call) {
        eval { $cb->($call) };
        warn "on_call callback error: $@" if $@;
    }
}

# --- Internal: handle inbound message ---

sub _handle_inbound_message {
    my ($self, $event) = @_;

    if (my $cb = $self->_on_message) {
        eval { $cb->($event) };
        warn "on_message callback error: $@" if $@;
    }
}

# --- Internal: handle dial completion event ---

sub _handle_dial_event {
    my ($self, $event, $params) = @_;
    my $tag = $params->{tag} // '';
    my $dial_state = $params->{dial_state} // '';
    my $call_info = $params->{call} // {};

    my $pending = $self->_pending_dials->{$tag};
    return unless $pending;

    if ($dial_state eq DIAL_STATE_ANSWERED) {
        my $call_id = $call_info->{call_id} // '';
        my $call = $self->_calls->{$call_id};
        unless ($call) {
            $call = SignalWire::Relay::Call->new(
                call_id     => $call_id,
                node_id     => $call_info->{node_id} // '',
                tag         => $tag,
                device      => $call_info->{device} // {},
                dial_winner => 1,
                state       => 'answered',
                _client     => $self,
            );
            $self->_calls->{$call_id} = $call;
        }
        $call->state('answered');
        $call->dial_winner(1);
        $pending->{resolve}->($call);
    }
    elsif ($dial_state eq DIAL_STATE_FAILED) {
        $pending->{reject}->("Dial failed");
    }
}

# --- Internal: handle server disconnect ---

sub _handle_disconnect {
    my ($self, $params) = @_;
    my $restart = $params->{restart} || 0;

    if ($restart) {
        # Clear session state, connect fresh
        $self->protocol('');
        $self->authorization_state('');
    }

    $self->connected(0);
    # The client should reconnect (handled by the event loop)
}

# --- Reconnection ---

sub reconnect {
    my ($self) = @_;

    # Reject all pending requests
    for my $id (keys %{$self->_pending}) {
        my $p = delete $self->_pending->{$id};
        $p->{reject}->("Disconnected") if $p;
    }

    # Reject all pending dials
    for my $tag (keys %{$self->_pending_dials}) {
        my $p = delete $self->_pending_dials->{$tag};
        $p->{reject}->("Disconnected") if $p;
    }

    # Exponential backoff: 1s, 2s, 4s, ... up to max_backoff
    my $attempts = $self->_reconnect_attempts;
    my $delay = 2 ** $attempts;
    $delay = $self->_max_backoff if $delay > $self->_max_backoff;

    $logger->info("Reconnecting in ${delay}s (attempt " . ($attempts + 1) . ")");
    select(undef, undef, undef, $delay);

    $self->_reconnect_attempts($attempts + 1);

    if ($self->connect_ws) {
        return $self->authenticate;
    }

    return undef;
}

# --- Disconnect ---

sub disconnect_ws {
    my ($self) = @_;
    $self->connected(0);
    if ($self->_socket) {
        close($self->_socket);
        $self->_socket(undef);
    }
    $self->_ws(undef);
}

# --- Run event loop ---

sub run {
    my ($self) = @_;
    while ($self->connected) {
        $self->_read_once();
    }
}

1;
