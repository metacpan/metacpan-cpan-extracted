package PAGI::WebSocket;
$PAGI::WebSocket::VERSION = '0.002002';
use strict;
use warnings;
use Carp qw(croak);
use Encode qw(decode FB_CROAK FB_DEFAULT LEAVE_SRC);
use Hash::MultiValue;
use Future::AsyncAwait;
use Future;
use JSON::MaybeXS ();
use Scalar::Util qw(blessed);


sub new {
    my ($class, $scope, $receive, $send) = @_;

    croak "PAGI::WebSocket requires scope hashref"
        unless $scope && ref($scope) eq 'HASH';
    croak "PAGI::WebSocket requires receive coderef"
        unless $receive && ref($receive) eq 'CODE';
    croak "PAGI::WebSocket requires send coderef"
        unless $send && ref($send) eq 'CODE';
    croak "PAGI::WebSocket requires scope type 'websocket', got '$scope->{type}'"
        unless ($scope->{type} // '') eq 'websocket';

    # Return existing WebSocket object if one was already created for this scope
    # This ensures consistent state (is_connected, is_closed, callbacks) if
    # multiple code paths create WebSocket objects from the same scope.
    return $scope->{'pagi.websocket'} if $scope->{'pagi.websocket'};

    my $self = bless {
        scope   => $scope,
        receive => $receive,
        send    => $send,
        _state  => 'connecting',  # connecting -> connected -> closed
        _close_code   => undef,
        _close_reason => undef,
        _on_close     => [],
        _on_error     => [],
        _on_message   => [],
    }, $class;

    # Cache in scope for reuse (weakened to avoid circular reference leak)
    $scope->{'pagi.websocket'} = $self;
    Scalar::Util::weaken($scope->{'pagi.websocket'});

    return $self;
}

# Scope property accessors
sub scope        { shift->{scope} }
sub path         { shift->{scope}{path} }
sub raw_path     { my $s = shift; $s->{scope}{raw_path} // $s->{scope}{path} }
sub query_string { shift->{scope}{query_string} // '' }
sub scheme       { shift->{scope}{scheme} // 'ws' }
sub http_version { shift->{scope}{http_version} // '1.1' }
sub subprotocols { shift->{scope}{subprotocols} // [] }
sub client       { shift->{scope}{client} }
sub server       { shift->{scope}{server} }


# Application state (injected by PAGI::Lifespan, read-only)
sub state {
    my $self = shift;
    return $self->{scope}{state} // {};
}

# Path parameter accessors - captured from URL path by router
# Stored in scope->{path_params} for router-agnostic access
sub path_params {
    my ($self) = @_;
    return $self->{scope}{path_params} // {};
}

sub path_param {
    my ($self, $name) = @_;
    my $params = $self->{scope}{path_params} // {};
    return $params->{$name};
}

# Internal: URL decode a string (handles + as space)
sub _url_decode {
    my ($str) = @_;
    return '' unless defined $str;
    $str =~ s/\+/ /g;
    $str =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
    return $str;
}

# Internal: Decode UTF-8 with replacement or croak in strict mode
sub _decode_utf8 {
    my ($str, $strict) = @_;
    return '' unless defined $str;
    my $flag = $strict ? FB_CROAK : FB_DEFAULT;
    $flag |= LEAVE_SRC;
    return decode('UTF-8', $str, $flag);
}

# Query params as Hash::MultiValue (cached in scope)
# Options: strict => 1 (croak on invalid UTF-8), raw => 1 (skip UTF-8 decoding)
sub query_params {
    my ($self, %opts) = @_;
    my $strict = delete $opts{strict} // 0;
    my $raw    = delete $opts{raw}    // 0;
    croak("Unknown options to query_params: " . join(', ', keys %opts)) if %opts;

    my $cache_key = $raw ? 'pagi.websocket.query.raw' : ($strict ? 'pagi.websocket.query.strict' : 'pagi.websocket.query');
    return $self->{scope}{$cache_key} if $self->{scope}{$cache_key};

    my $qs = $self->query_string;
    my @pairs;

    for my $part (split /[&;]/, $qs) {
        next unless length $part;
        my ($key, $val) = split /=/, $part, 2;
        $key //= '';
        $val //= '';

        # URL decode (handles + as space)
        my $key_decoded = _url_decode($key);
        my $val_decoded = _url_decode($val);

        # UTF-8 decode unless raw mode
        my $key_final = $raw ? $key_decoded : _decode_utf8($key_decoded, $strict);
        my $val_final = $raw ? $val_decoded : _decode_utf8($val_decoded, $strict);

        push @pairs, $key_final, $val_final;
    }

    $self->{scope}{$cache_key} = Hash::MultiValue->new(@pairs);
    return $self->{scope}{$cache_key};
}

# Raw query params (no UTF-8 decoding)
sub raw_query_params {
    my $self = shift;
    return $self->query_params(raw => 1);
}

# Shortcut for single query param
sub query {
    my ($self, $name, %opts) = @_;
    return $self->query_params(%opts)->get($name);
}

# Raw single query param
sub raw_query {
    my ($self, $name) = @_;
    return $self->query($name, raw => 1);
}

# Single header lookup (case-insensitive, returns last value)
sub header {
    my ($self, $name) = @_;
    $name = lc($name);
    my $value;
    for my $pair (@{$self->{scope}{headers} // []}) {
        if (lc($pair->[0]) eq $name) {
            $value = $pair->[1];
        }
    }
    return $value;
}

# All headers as Hash::MultiValue (cached in scope)
sub headers {
    my $self = shift;
    return $self->{scope}{'pagi.request.headers'} if $self->{scope}{'pagi.request.headers'};

    my @pairs;
    for my $pair (@{$self->{scope}{headers} // []}) {
        push @pairs, lc($pair->[0]), $pair->[1];
    }

    $self->{scope}{'pagi.request.headers'} = Hash::MultiValue->new(@pairs);
    return $self->{scope}{'pagi.request.headers'};
}

# All values for a header
sub header_all {
    my ($self, $name) = @_;
    return $self->headers->get_all(lc($name));
}

# State accessors
sub connection_state { shift->{_state} }

sub is_connected {
    my $self = shift;
    return $self->{_state} eq 'connected';
}

sub is_closed {
    my $self = shift;
    return $self->{_state} eq 'closed';
}

sub close_code   { shift->{_close_code} }
sub close_reason { shift->{_close_reason} }

# Outbound flow-control introspection (delegates to the pagi.transport handle)
sub buffered_amount {
    my $self = shift;
    my $t = $self->{scope}{'pagi.transport'};
    return 0 unless $t;
    return $t->buffered_amount;
}

sub high_water_mark {
    my $self = shift;
    my $t = $self->{scope}{'pagi.transport'};
    return undef unless $t;
    return $t->high_water_mark;
}

sub low_water_mark {
    my $self = shift;
    my $t = $self->{scope}{'pagi.transport'};
    return undef unless $t;
    return $t->low_water_mark;
}

sub on_high_water {
    my ($self, $cb) = @_;
    my $t = $self->{scope}{'pagi.transport'};
    $t->on_high_water($cb) if $t && $t->can('on_high_water');
    return $self;
}

sub on_drain {
    my ($self, $cb) = @_;
    my $t = $self->{scope}{'pagi.transport'};
    $t->on_drain($cb) if $t && $t->can('on_drain');
    return $self;
}

sub is_writable {
    my $self = shift;
    my $t = $self->{scope}{'pagi.transport'};
    return 1 unless $t;
    my $high = $t->high_water_mark;
    return 1 unless defined $high;
    return $t->buffered_amount < $high ? 1 : 0;
}

# Internal state setters
sub _set_state {
    my ($self, $state) = @_;
    $self->{_state} = $state;
}

sub _set_closed {
    my ($self, $code, $reason) = @_;
    $self->{_state} = 'closed';
    $self->{_close_code} = $code // 1005;
    $self->{_close_reason} = $reason // '';
}

# Register callback to run on disconnect/close
sub on_close {
    my ($self, $callback) = @_;
    push @{$self->{_on_close}}, $callback;
    return $self;
}

# Internal: run all on_close callbacks exactly once
async sub _run_close_callbacks {
    my ($self) = @_;

    # Only run once
    return if $self->{_close_callbacks_ran};
    $self->{_close_callbacks_ran} = 1;

    my $code = $self->close_code;
    my $reason = $self->close_reason;

    for my $cb (@{$self->{_on_close}}) {
        eval {
            my $r = $cb->($code, $reason);
            # Only await if callback returns a Future
            if (blessed($r) && $r->isa('Future')) {
                await $r;
            }
        };
        if ($@) {
            warn "PAGI::WebSocket on_close callback error: $@";
        }
    }

    # Clear all callback arrays to break any closure-based cycles
    $self->{_on_close}   = [];
    $self->{_on_error}   = [];
    $self->{_on_message} = [];
}

# Internal: mark closed and fire on_close callbacks for a disconnect that
# arrived directly off the wire (not via close()). Shared by receive()'s own
# disconnect handling and PAGI::Context::WebSocket's _sync_terminal_disconnect
# hook (fired when the disconnect is instead consumed via $ctx->run()). Does
# NOT send a websocket.close wire event -- the peer is already gone.
async sub _note_disconnected {
    my ($self, $code, $reason) = @_;

    # 1005 = No Status Rcvd (RFC 6455)
    $self->_set_closed($code // 1005, $reason // '');
    await $self->_run_close_callbacks;
    return;
}

# Register callback to run on errors
sub on_error {
    my ($self, $callback) = @_;
    push @{$self->{_on_error}}, $callback;
    return $self;
}

# Register callback to run on message receive
sub on_message {
    my ($self, $callback) = @_;
    push @{$self->{_on_message}}, $callback;
    return $self;
}

# Generic event registration (Socket.IO style)
sub on {
    my ($self, $event, $callback) = @_;

    if ($event eq 'message') {
        return $self->on_message($callback);
    }
    elsif ($event eq 'close') {
        return $self->on_close($callback);
    }
    elsif ($event eq 'error') {
        return $self->on_error($callback);
    }
    else {
        croak "Unknown event type: $event (expected message, close, or error)";
    }
}

# Internal: trigger error callbacks
async sub _trigger_error {
    my ($self, $error) = @_;

    for my $cb (@{$self->{_on_error}}) {
        eval {
            my $r = $cb->($error);
            if (blessed($r) && $r->isa('Future')) {
                await $r;
            }
        };
        if ($@) {
            warn "PAGI::WebSocket on_error callback error: $@";
        }
    }

    # If no error handlers registered, warn
    if (!@{$self->{_on_error}}) {
        warn "PAGI::WebSocket error: $error";
    }
}

# Accept the WebSocket connection
async sub accept {
    my ($self, %opts) = @_;

    my $event = {
        type => 'websocket.accept',
    };
    $event->{subprotocol} = $opts{subprotocol} if exists $opts{subprotocol};
    $event->{headers} = $opts{headers} if exists $opts{headers};

    await $self->{send}->($event);
    $self->_set_state('connected');

    return $self;
}

# Close the WebSocket connection
async sub close {
    my ($self, $code, $reason) = @_;

    # Idempotent - don't send close twice
    return if $self->is_closed;

    $code //= 1000;
    $reason //= '';

    await $self->{send}->({
        type   => 'websocket.close',
        code   => $code,
        reason => $reason,
    });

    $self->_set_closed($code, $reason);
    await $self->_run_close_callbacks;

    return $self;
}

# Whether the server advertised the WebSocket denial-response extension.
# See L<PAGI::Spec::Www/"WebSocket Denial Response">.
sub supports_denial_response {
    my $self = shift;
    return $self->{scope}{extensions}{'websocket.http.response'} ? 1 : 0;
}

# Reject the handshake with a custom HTTP response (status/headers/body) instead
# of the bare 403. Falls back to a plain close when the server does not advertise
# the extension. Valid only before accept.
# See L<PAGI::Spec::Www/"WebSocket Denial Response">.
async sub deny {
    my ($self, %opts) = @_;

    my $status  = $opts{status}  // 403;
    my $headers = $opts{headers} // [];
    my $body    = defined $opts{body} ? $opts{body} : '';

    if (!$self->supports_denial_response) {
        await $self->{send}->({ type => 'websocket.close', code => 1008, reason => '' });
        $self->_set_closed(1008, '');
        return $self;
    }

    await $self->{send}->({
        type    => 'websocket.http.response.start',
        status  => $status,
        headers => $headers,
    });
    await $self->{send}->({
        type => 'websocket.http.response.body',
        body => $body,
        more => 0,
    });

    # An HTTP denial sends a response, not a WebSocket close frame — there is no
    # RFC6455 close code, so mark closed without recording one (close_code stays
    # undef). The bare-403 fallback above DID send a real close frame and keeps
    # its 1008 via _set_closed.
    $self->{_state} = 'closed';
    return $self;
}

# Send text message
async sub send_text {
    my ($self, $text) = @_;

    croak "Cannot send on closed WebSocket" if $self->is_closed;

    await $self->{send}->({
        type => 'websocket.send',
        text => $text,
    });

    return $self;
}

# Send binary message
async sub send_bytes {
    my ($self, $bytes) = @_;

    croak "Cannot send on closed WebSocket" if $self->is_closed;

    await $self->{send}->({
        type  => 'websocket.send',
        bytes => $bytes,
    });

    return $self;
}

# Send JSON-encoded message
async sub send_json {
    my ($self, $data) = @_;

    croak "Cannot send on closed WebSocket" if $self->is_closed;

    my $json = JSON::MaybeXS::encode_json($data);

    await $self->{send}->({
        type => 'websocket.send',
        text => $json,
    });

    return $self;
}

# Safe send methods - return bool instead of throwing

async sub try_send_text {
    my ($self, $text) = @_;
    return 0 if $self->is_closed;

    eval {
        await $self->{send}->({
            type => 'websocket.send',
            text => $text,
        });
    };
    # A failed send is not a disconnect (a send after close is a silent no-op per
    # spec), so return false per the try_* contract without fabricating a 1006
    # close or mutating connection state.
    return 0 if $@;
    return 1;
}

async sub try_send_bytes {
    my ($self, $bytes) = @_;
    return 0 if $self->is_closed;

    eval {
        await $self->{send}->({
            type => 'websocket.send',
            bytes => $bytes,
        });
    };
    # A failed send is not a disconnect (a send after close is a silent no-op per
    # spec), so return false per the try_* contract without fabricating a 1006
    # close or mutating connection state.
    return 0 if $@;
    return 1;
}

async sub try_send_json {
    my ($self, $data) = @_;
    return 0 if $self->is_closed;

    my $json = JSON::MaybeXS::encode_json($data);
    eval {
        await $self->{send}->({
            type => 'websocket.send',
            text => $json,
        });
    };
    # A failed send is not a disconnect (a send after close is a silent no-op per
    # spec), so return false per the try_* contract without fabricating a 1006
    # close or mutating connection state.
    return 0 if $@;
    return 1;
}

# Silent send methods - no-op when closed

async sub send_text_if_connected {
    my ($self, $text) = @_;
    return unless $self->is_connected;
    await $self->try_send_text($text);
    return;
}

async sub send_bytes_if_connected {
    my ($self, $bytes) = @_;
    return unless $self->is_connected;
    await $self->try_send_bytes($bytes);
    return;
}

async sub send_json_if_connected {
    my ($self, $data) = @_;
    return unless $self->is_connected;
    await $self->try_send_json($data);
    return;
}

# Receive methods

async sub receive {
    my ($self) = @_;

    return undef if $self->is_closed;

    while (1) {
        my $event = await $self->{receive}->();

        if (!defined($event) || $event->{type} eq 'websocket.disconnect') {
            await $self->_note_disconnected($event->{code}, $event->{reason});
            return undef;
        }

        # websocket.connect is a handshake event, not application data, so it is
        # filtered out of the message stream here. PAGI's handshake contract: the
        # server sends websocket.connect and waits for the app's reply; the app
        # replies by sending accept()/close(). The app does not need to consume
        # the connect event itself — this filter makes a stray one a no-op rather
        # than surfacing it as a message. See accept() for the contract.
        next if $event->{type} eq 'websocket.connect';

        return $event;
    }
}

async sub receive_text {
    my ($self) = @_;

    while (1) {
        my $event = await $self->receive;
        return undef unless $event;

        # Skip non-receive events and binary frames
        next unless $event->{type} eq 'websocket.receive';
        next unless exists $event->{text};

        return $event->{text};
    }
}

async sub receive_bytes {
    my ($self) = @_;

    while (1) {
        my $event = await $self->receive;
        return undef unless $event;

        # Skip non-receive events and text frames
        next unless $event->{type} eq 'websocket.receive';
        next unless exists $event->{bytes};

        return $event->{bytes};
    }
}

async sub receive_json {
    my ($self) = @_;

    my $text = await $self->receive_text;
    return undef unless defined $text;

    return JSON::MaybeXS::decode_json($text);
}

# Iteration helpers

# Internal: run one per-message callback, running on_close cleanup before
# re-raising if it dies (idempotent; _run_close_callbacks may already have run).
# Takes a thunk so each caller's varying callback arg list stays at the call
# site; awaits the thunk's Future and returns its value for callers that use it.
async sub _guarded_dispatch {
    my ($self, $thunk) = @_;

    my $result;
    my $ok = eval { $result = await $thunk->(); 1 };
    unless ($ok) {
        my $err = $@;
        await $self->_run_close_callbacks;    # idempotent; may already have run
        die $err;                             # re-raise: caller still sees the error
    }

    return $result;
}

async sub each_message {
    my ($self, $callback) = @_;

    while (my $event = await $self->receive) {
        next unless $event->{type} eq 'websocket.receive';
        await $self->_guarded_dispatch(sub { $callback->($event) });
    }

    return;
}

async sub each_text {
    my ($self, $callback) = @_;

    while (my $text = await $self->receive_text) {
        await $self->_guarded_dispatch(sub { $callback->($text) });
    }

    return;
}

async sub each_bytes {
    my ($self, $callback) = @_;

    while (my $bytes = await $self->receive_bytes) {
        await $self->_guarded_dispatch(sub { $callback->($bytes) });
    }

    return;
}

async sub each_json {
    my ($self, $callback) = @_;

    while (1) {
        my $text = await $self->receive_text;
        last unless defined $text;

        my $data = JSON::MaybeXS::decode_json($text);
        await $self->_guarded_dispatch(sub { $callback->($data) });
    }

    return;
}

# Callback-based event loop (alternative to each_* iteration)
async sub run {
    my ($self) = @_;

    while (1) {
        my $event = eval { await $self->receive };
        if (my $err = $@) {
            warn "PAGI::WebSocket receive error: $err";
            last;
        }
        last unless $event;

        next unless $event->{type} eq 'websocket.receive';

        my $data = $event->{text} // $event->{bytes};

        for my $cb (@{$self->{_on_message}}) {
            eval {
                my $r = $cb->($data, $event);
                # Await if callback returns a Future
                if (blessed($r) && $r->isa('Future')) {
                    await $r;
                }
            };
            if (my $err = $@) {
                await $self->_trigger_error($err);
            }
        }
    }

    return;
}

# Keepalive support using WebSocket protocol-level ping/pong (RFC 6455)
# Sends websocket.keepalive event to server - loop-agnostic, server handles timers
async sub keepalive {
    my ($self, $interval, $timeout) = @_;

    $interval //= 0;

    my $event = {
        type     => 'websocket.keepalive',
        interval => $interval,
    };
    $event->{timeout} = $timeout if defined $timeout;

    await $self->{send}->($event);

    return $self;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PAGI::WebSocket - Convenience wrapper for PAGI WebSocket connections

=head1 SYNOPSIS

    use PAGI::WebSocket;
    use Future::AsyncAwait;

    # Simple echo server
    async sub app {
        my ($scope, $receive, $send) = @_;

        my $ws = PAGI::WebSocket->new($scope, $receive, $send);
        await $ws->accept;

        await $ws->each_text(async sub {
            my ($text) = @_;
            await $ws->send_text("Echo: $text");
        });
    }

    # JSON API with cleanup
    async sub json_app {
        my ($scope, $receive, $send) = @_;

        my $ws = PAGI::WebSocket->new($scope, $receive, $send);
        await $ws->accept(subprotocol => 'json');

        my $user_id = generate_id();

        # Cleanup runs on any disconnect
        $ws->on_close(async sub {
            my ($code, $reason) = @_;
            await remove_user($user_id);
            log_disconnect($user_id, $code);
        });

        await $ws->each_json(async sub {
            my ($data) = @_;

            if ($data->{type} eq 'ping') {
                await $ws->send_json({ type => 'pong' });
            }
        });
    }

    # Callback-based style (alternative to iteration)
    async sub callback_app {
        my ($scope, $receive, $send) = @_;

        my $ws = PAGI::WebSocket->new($scope, $receive, $send);
        await $ws->accept;

        my $stash = PAGI::Stash->new($ws);
        $stash->set(user => 'anonymous');

        $ws->on(message => sub {
            my ($data) = @_;
            $ws->send_text("Echo: $data");
        });

        $ws->on(error => sub {
            my ($error) = @_;
            warn "WebSocket error: $error";
        });

        $ws->on(close => sub {
            print "User disconnected\n";
        });

        await $ws->run;
    }

=head1 DESCRIPTION

PAGI::WebSocket wraps the raw PAGI WebSocket protocol to provide a clean,
high-level API inspired by Starlette's WebSocket class. It eliminates
protocol boilerplate and provides:

=over 4

=item * Typed send/receive methods (text, bytes, JSON)

=item * Connection state tracking (is_connected, is_closed, close_code)

=item * Cleanup and error callback registration (on_close, on_error)

=item * Safe send methods for broadcast scenarios (try_send_*, send_*_if_connected)

=item * Message iteration helpers (each_text, each_json)

=item * Callback-based event handling (on, run)

=item * Per-connection storage (via L<PAGI::Stash>)

=back

=head1 CONSTRUCTOR

=head2 new

    my $ws = PAGI::WebSocket->new($scope, $receive, $send);

Creates a new WebSocket wrapper. Requires:

=over 4

=item * C<$scope> - PAGI scope hashref with C<< type => 'websocket' >>

=item * C<$receive> - Async coderef returning Futures for events

=item * C<$send> - Async coderef for sending events

=back

Dies if scope type is not 'websocket'.

B<Singleton pattern:> The WebSocket object is cached in C<< $scope->{'pagi.websocket'} >>.
If you call C<new()> multiple times with the same scope, you get the same
WebSocket object back. This ensures consistent state (is_connected, is_closed,
callbacks) across multiple code paths that may create WebSocket objects from
the same scope.

=head1 SCOPE ACCESSORS

=head2 scope, path, raw_path, query_string, scheme, http_version

    my $path = $ws->path;              # /chat/room1
    my $qs = $ws->query_string;        # token=abc
    my $scheme = $ws->scheme;          # ws or wss

Standard PAGI scope properties with sensible defaults.

=head2 subprotocols

    my $protos = $ws->subprotocols;    # ['chat', 'json']

Returns arrayref of requested subprotocols.

=head2 client, server

    my $client = $ws->client;          # ['192.168.1.1', 54321]

Client and server address info.

=head2 header, headers, header_all

    my $origin = $ws->header('origin');
    my $all_cookies = $ws->header_all('cookie');
    my $hmv = $ws->headers;            # Hash::MultiValue

Case-insensitive header access.

=head2 Per-Connection Shared State

See L<PAGI::Stash> for per-connection shared state:

    use PAGI::Stash;
    my $stash = PAGI::Stash->new($ws);

=cut

=head2 state

    my $db = $ws->state->{db};
    my $config = $ws->state->{config};

Application state hashref injected by PAGI::Lifespan. Read-only access
to shared application state. Returns empty hashref if not set.

Note: This is separate from L<PAGI::Stash> (per-connection data) and
C<connection_state> (internal WebSocket state).

=head2 path_param

    my $id = $ws->path_param('id');

Returns a path parameter by name. Path parameters are captured from the URL
path by a router and stored in C<< $scope->{path_params} >>.

    # Route: /chat/:room
    my $room = $ws->path_param('room');

=head2 path_params

    my $params = $ws->path_params;  # { room => 'general', id => '42' }

Returns hashref of all path parameters from scope.

=head2 query_params

    my $params = $ws->query_params;  # Hash::MultiValue
    my $params = $ws->query_params(strict => 1);  # Die on invalid UTF-8
    my $params = $ws->query_params(raw => 1);     # Skip UTF-8 decoding

Get query parameters as L<Hash::MultiValue>.

B<Options:>

=over 4

=item * C<strict> - If true, die on invalid UTF-8 sequences. Default: false
(invalid bytes replaced with U+FFFD).

=item * C<raw> - If true, skip UTF-8 decoding entirely and return raw bytes.
Default: false.

=back

=head2 query

    my $value = $ws->query('user');
    my $value = $ws->query('page', strict => 1);
    my $value = $ws->query('id', raw => 1);

Shortcut for C<< $ws->query_params(%opts)->get($name) >>. Accepts the same
C<strict> and C<raw> options as C<query_params>.

=head2 raw_query_params

    my $params = $ws->raw_query_params;

Returns query params without UTF-8 decoding. Equivalent to
C<< $ws->query_params(raw => 1) >>.

=head2 raw_query

    my $value = $ws->raw_query('user');

Returns a single query param without UTF-8 decoding. Equivalent to
C<< $ws->query($name, raw => 1) >>.

=head1 LIFECYCLE METHODS

=head2 accept

    await $ws->accept;
    await $ws->accept(subprotocol => 'chat');
    await $ws->accept(headers => [['x-custom', 'value']]);

Accepts the WebSocket connection. Optionally specify a subprotocol
to use and additional response headers.

B<Handshake contract.> The server sends a C<websocket.connect> event and waits
for the application's reply before completing the handshake; the reply is
C<accept> (this method) or C<close>/C<deny>. The application does B<not> need to
receive the C<websocket.connect> event itself — C<accept> sends the reply
directly, and any C<websocket.connect> in the receive stream is filtered out by
L</receive> rather than surfaced as a message. This matches ASGI, whose
normative requirements bind only the server (the application is never required
to consume C<connect> before accepting); the reference server, RFC 6455, and
other frameworks (e.g. Mojolicious, which auto-upgrades) impose no such app-side
ordering either.

=head2 close

    await $ws->close;
    await $ws->close(1000, 'Normal closure');
    await $ws->close(4000, 'Custom reason');

Closes the connection. Default code is 1000 (normal closure).
Idempotent - calling multiple times only sends close once.

=head2 supports_denial_response

    if ($ws->supports_denial_response) { ... }

Returns true (1) if the server advertised the C<websocket.http.response>
extension on the WebSocket scope, false (0) otherwise.

See L<PAGI::Spec::Www/"WebSocket Denial Response">.

=head2 deny

    await $ws->deny(status => 401);
    await $ws->deny(status => 401, headers => [['www-authenticate', 'Bearer']], body => '{"error":"unauthorized"}');

Rejects the WebSocket handshake with a custom HTTP response instead of the bare
C<403 Forbidden>. Valid only before C<accept>. Marks the connection closed on
return.

When the server advertises the C<websocket.http.response> extension
(C<supports_denial_response()> is true), sends two events in sequence:
C<websocket.http.response.start> (status + headers) and
C<websocket.http.response.body> (body). When the extension is absent, falls back
to a plain C<websocket.close>.

Options:

=over 4

=item C<status> - HTTP status code. Defaults to 403.

=item C<headers> - ArrayRef of C<[$name, $value]> pairs. Defaults to C<[]>.

=item C<body> - Response body as bytes. Defaults to C<"">.

=back

See L<PAGI::Spec::Www/"WebSocket Denial Response">.

=head1 STATE ACCESSORS

=head2 is_connected, is_closed, connection_state

    if ($ws->is_connected) { ... }
    if ($ws->is_closed) { ... }
    my $state = $ws->connection_state; # 'connecting', 'connected', 'closed'

=head2 close_code, close_reason

    my $code = $ws->close_code;        # 1000, 1001, etc.
    my $reason = $ws->close_reason;    # 'Normal closure'

Available after connection closes. A real close frame defaults to code=1005,
reason=''. After an HTTP denial via C<deny> on a denial-response-capable server,
C<close_code> is C<undef>: a denial sends an HTTP response, not a WebSocket
close frame, so there is no RFC6455 close code.

=head2 buffered_amount, high_water_mark, low_water_mark

    my $pending = $ws->buffered_amount;   # bytes queued, not yet on the wire
    my $ceiling = $ws->high_water_mark;    # backpressure ceiling (or undef)
    my $floor   = $ws->low_water_mark;     # backpressure floor (or undef)

Outbound flow-control introspection, delegated to the server-provided
C<pagi.transport> handle (see L<PAGI::Spec::Www/"Transport Flow Control">). Use
C<buffered_amount> to conflate, coalesce, shed load, or disconnect a slow client
instead of only blocking on drain; when the server does not provide the handle,
C<buffered_amount> returns C<0> and the watermarks return C<undef>.

=head2 on_high_water, on_drain, is_writable

    $ws->on_high_water(sub { $source->pause });    # backpressure engaged
    $ws->on_drain(sub      { $source->resume });    # backpressure cleared
    last unless $ws->is_writable;                    # below the high mark?

Backpressure controls delegated to the C<pagi.transport> handle. C<on_high_water>
and C<on_drain> register edge-triggered callbacks (the Node/Mojo C<drain> model)
for producers that cannot self-pace with a blocking send; each returns the
object for chaining. C<is_writable> is true when the outbound buffer is below the
high mark. When the server provides no transport handle (or only the read
methods), the callbacks are quiet no-ops and C<is_writable> is true.

=head1 SEND METHODS

=head2 send_text, send_bytes, send_json

    await $ws->send_text("Hello!");
    await $ws->send_bytes("\x00\x01\x02");
    await $ws->send_json({ action => 'greet', name => 'Alice' });

Send a message. Dies if connection is closed.

=head2 try_send_text, try_send_bytes, try_send_json

    my $sent = await $ws->try_send_json($data);

B<Best-effort send.> Attempts the send and B<never throws>, returning a boolean.
Intended for broadcast-style loops -- "send to many, skip the failures" -- where
one bad recipient must not abort the loop or corrupt shared connection state (a
failed send leaves C<is_closed>/C<close_code> untouched).

B<The boolean is a weak signal; do not treat it as a delivery receipt:>

=over 4

=item *

A B<false> return means the send definitely did not happen -- the socket is
already known-closed, or the underlying send raised. It tells you I<that> it
failed, not I<why>.

=item *

A B<true> return does B<not> guarantee delivery. Per the spec, a send to a peer
that has disconnected is a silent no-op, so if the client has vanished but the
server has not yet surfaced the C<websocket.disconnect> event, the send no-ops
and this still returns true. "Sent" means "the send call did not fail," not "the
client received it."

=back

If you need more than best-effort, reach for the right tool instead of inspecting
this return value:

=over 4

=item * B<Why did it fail?> Use C<send_text>/C<send_bytes>/C<send_json>, which
throw the underlying error.

=item * B<Is the peer still there?> Use C<is_connected> (or the
C<send_*_if_connected> variants) and react to the C<websocket.disconnect> event.

=item * B<Is the connection backpressured?> Use C<is_writable> /
C<buffered_amount> and the watermark / C<on_drain> controls.

=back

=head2 send_text_if_connected, send_bytes_if_connected, send_json_if_connected

    await $ws->send_json_if_connected($data);

Silent no-op if connection is closed. Useful for fire-and-forget.

=head1 RECEIVE METHODS

=head2 receive

    my $event = await $ws->receive;

Returns raw PAGI event hashref, or undef on disconnect.

=head2 receive_text, receive_bytes

    my $text = await $ws->receive_text;
    my $bytes = await $ws->receive_bytes;

Waits for specific frame type, skipping others. Returns undef on disconnect.

=head2 receive_json

    my $data = await $ws->receive_json;

Receives text frame and decodes as JSON. Dies on invalid JSON.

=head1 ITERATION HELPERS

=head2 each_message, each_text, each_bytes, each_json

    await $ws->each_text(async sub {
        my ($text) = @_;
        await $ws->send_text("Got: $text");
    });

    await $ws->each_json(async sub {
        my ($data) = @_;
        if ($data->{type} eq 'ping') {
            await $ws->send_json({ type => 'pong' });
        }
    });

Loops until disconnect, calling callback for each message.
Exceptions in callback propagate to caller.

=head1 EVENT CALLBACKS

=head2 on_close

    # Simple sync callback
    $ws->on_close(sub {
        my ($code, $reason) = @_;
        print "Disconnected: $code\n";
    });

    # Async callback for cleanup that needs await
    $ws->on_close(async sub {
        my ($code, $reason) = @_;
        await cleanup_resources();
    });

Registers cleanup callback that runs on disconnect or close().
Callbacks can be regular subs or async subs — async results are
automatically awaited. Multiple callbacks run in registration order.
Exceptions are caught and warned but don't prevent other callbacks.

Returns C<$self> for chaining.

B<Circular reference note:> If your callback captures C<$ws> in a
closure, use C<Scalar::Util::weaken> to avoid a memory leak:

    use Scalar::Util qw(weaken);
    my $weak_ws = $ws;
    weaken($weak_ws);
    $ws->on_close(sub { $weak_ws->... if $weak_ws });

The callback arrays are cleared after firing, so cycles via closures
are broken at connection close, but C<weaken> prevents the object from
being kept alive until that point.

=head2 on_error

    $ws->on_error(sub {
        my ($error) = @_;
        warn "WebSocket error: $error";
    });

    # Async callback — return value is awaited automatically
    $ws->on_error(async sub {
        my ($error) = @_;
        await log_error_async($error);
    });

Registers error callback. Called when exceptions occur in message
handlers during C<run()>. Callbacks can be regular subs or async
subs — async results are automatically awaited. Multiple callbacks
run in registration order. Exceptions in callbacks are caught and
warned but do not prevent other callbacks.

If no error handlers are registered, errors are warned to STDERR.

Returns C<$self> for chaining.

=head2 on_message

    $ws->on_message(sub {
        my ($data, $event) = @_;
        # $data is text or bytes, $event is the raw PAGI event hashref
        # Check $event->{text} vs $event->{bytes} to distinguish frame type
    });

Registers a message callback for use with C<run()>. Multiple callbacks
can be registered and all will be called for each message.

Returns C<$self> for chaining.

=head2 on

    # Generic Socket.IO-style event registration
    $ws->on(message => sub { my ($data, $event) = @_; ... });
    $ws->on(close   => sub { my ($code, $reason) = @_; ... });
    $ws->on(error   => sub { my ($error) = @_; ... });

    # Methods return $self, so calls can be chained
    $ws->on(message => sub { ... })
       ->on(close   => sub { ... })
       ->on(error   => sub { ... });

Generic event registration. Dispatches to C<on_message>, C<on_close>,
or C<on_error> based on the event name. Dies for unknown event types.

Returns C<$self> for chaining.

=head2 run

    # Register callbacks first
    $ws->on(message => sub { my ($data) = @_; ... });
    $ws->on(close => sub { ... });

    # Enter event loop
    await $ws->run;

Callback-based event loop (alternative to C<each_*> iteration).
Runs until disconnect, dispatching messages to registered callbacks.
Errors in callbacks are caught and passed to error handlers.

=head1 KEEPALIVE

WebSocket keepalive uses protocol-level ping/pong frames (RFC 6455). The server
sends ping frames automatically; clients respond with pong frames without any
application code needed.

=head2 keepalive

    await $ws->keepalive(30);       # Ping every 30 seconds
    await $ws->keepalive(30, 20);   # Ping every 30s, expect pong within 20s
    await $ws->keepalive(0);        # Disable keepalive

Enables or disables WebSocket protocol-level keepalive by sending a
C<websocket.keepalive> event to the server. The server handles the timer
and ping/pong frames.

Arguments:

=over 4

=item C<$interval> - Seconds between ping frames. Use C<0> to disable.

=item C<$timeout> - (Optional) Seconds to wait for pong response. If no pong is
received within this time, the connection is closed with code 1006 and the
application receives a disconnect event with C<reason =E<gt> 'keepalive timeout'>.

=back

Common intervals:

=over 4

=item C<25> - Safe for most proxies (30s timeout common)

=item C<55> - Safe for aggressive proxies (60s timeout)

=back

Returns C<$self> for chaining.

=head1 COMPLETE EXAMPLE

    use PAGI::WebSocket;
    use Future::AsyncAwait;

    my %connections;

    async sub chat_app {
        my ($scope, $receive, $send) = @_;

        my $ws = PAGI::WebSocket->new($scope, $receive, $send);
        await $ws->accept;

        my $user_id = generate_id();
        $connections{$user_id} = $ws;

        $ws->on_close(async sub {
            delete $connections{$user_id};
            await broadcast({ type => 'leave', user => $user_id });
        });

        await broadcast({ type => 'join', user => $user_id });

        await $ws->each_json(async sub {
            my ($data) = @_;
            $data->{from} = $user_id;
            await broadcast($data);
        });
    }

    async sub broadcast {
        my ($data) = @_;
        for my $ws (values %connections) {
            await $ws->try_send_json($data);
        }
    }

=head1 SEE ALSO

L<PAGI::Request> - Similar convenience wrapper for HTTP requests

L<PAGI::Server> - PAGI protocol server

=head1 AUTHOR

PAGI Contributors

=cut
