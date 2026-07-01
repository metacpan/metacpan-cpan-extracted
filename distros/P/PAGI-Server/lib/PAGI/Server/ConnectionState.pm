package PAGI::Server::ConnectionState;

use strict;
use warnings;

our $VERSION = '0.002005';

use Scalar::Util qw(weaken);

=encoding utf8

=head1 NAME

PAGI::Server::ConnectionState - Connection state tracking for HTTP requests

=head1 SYNOPSIS

    my $conn = $scope->{'pagi.connection'};

    # Synchronous, non-destructive check
    if ($conn->is_connected) {
        # Client still connected
    }

    # Get disconnect reason (undef while connected)
    my $reason = $conn->disconnect_reason;

    # Register a callback for an abnormal end (client gone, timeout, error)
    $conn->on_disconnect(sub {
        my ($reason) = @_;
        rollback();
    });

    # ...and its counterpart for a clean finish. Exactly one of the two fires.
    $conn->on_complete(sub {
        commit();
    });

    # Await abnormal disconnect (if Future provided)
    if (my $future = $conn->disconnect_future) {
        my $reason = await $future;
    }

=head1 DESCRIPTION

PAGI::Server::ConnectionState provides a mechanism for applications to detect
client disconnection without consuming messages from the receive queue.

This addresses a fundamental limitation in the PAGI (and ASGI) model where
checking for disconnect via C<receive()> may inadvertently consume request
body data.

The C<disconnect_future()> method lazily creates a Future only when called,
avoiding allocation overhead for simple request/response handlers that don't
need async disconnect detection.

See the "Connection State" section in L<PAGI::Spec::Www> for the full
specification.

=head1 METHODS

=head2 new

    my $conn = PAGI::Server::ConnectionState->new(connection => $connection);

Creates a new connection state object. The C<connection> argument provides
a reference to the parent Connection object for lazy Future creation.

=cut

sub new {
    my ($class, %args) = @_;

    my $connected = 1;
    my $reason = undef;

    my $self = bless {
        # Connection reference for lazy Future creation (will be weakened)
        _connection => $args{connection},

        # State (scalar refs - for internal consistency)
        _connected => \$connected,
        _reason    => \$reason,

        # Distinguishes the two terminal states once _connected is false:
        # an abnormal disconnect (false) vs. a clean completion (true).
        _completed => 0,

        # Response progress (HTTP): set when http.response.start is emitted.
        _response_started => 0,

        # Lazy Future (only created if disconnect_future() called)
        _future => undef,

        # Callbacks registered via on_disconnect()
        _callbacks => [],

        # Callbacks registered via on_complete()
        _complete_callbacks => [],
    }, $class;

    # Weaken to avoid circular reference: Connection -> ConnectionState -> Connection
    weaken($self->{_connection}) if $self->{_connection};

    return $self;
}

=head2 is_connected

    my $connected = $conn->is_connected;  # Boolean

Returns true if the connection is still open, false if disconnected.

This is a synchronous, non-destructive check that does not consume
messages from the receive queue.

=cut

sub is_connected {
    my $self = shift;
    return ${$self->{_connected}} ? 1 : 0;
}

=head2 response_started

    my $started = $conn->response_started;  # 0 or 1

True once the server has started this request's response (C<http.response.start>
emitted -- by the application, a framework, a middleware, or a server-synthesized
error/backstop response). Server-owned; read-only to applications.

=cut

sub response_started { return $_[0]->{_response_started} ? 1 : 0 }

# Server-internal: called from the send path when http.response.start is emitted.
sub _mark_response_started { $_[0]->{_response_started} = 1; return }

=head2 disconnect_reason

    my $reason = $conn->disconnect_reason;  # String or undef

Returns the disconnect reason string, or C<undef> if still connected B<or if the
request completed normally> -- every reason below describes an abnormal end.

Standard reason strings:

=over 4

=item * C<client_closed> - Client initiated clean close (TCP FIN) mid-request

=item * C<client_timeout> - Client stopped responding (read timeout)

=item * C<idle_timeout> - Connection idle too long before the request arrived

=item * C<keepalive_timeout> - Keep-alive connection idled out between requests

=item * C<write_timeout> - Response write timed out

=item * C<write_error> - Socket write failed (EPIPE, ECONNRESET)

=item * C<read_error> - Socket read failed

=item * C<protocol_error> - HTTP parse error, invalid request

=item * C<server_shutdown> - Server shutting down gracefully

=item * C<server_error> - Unhandled server-side error aborted the request

=item * C<body_too_large> - Request body exceeded limit

=item * C<queue_overflow> - A bounded server queue overflowed; connection dropped

=back

See L<PAGI::Spec::Www/"Standard Disconnect Reasons"> for the authoritative list.

=cut

sub disconnect_reason {
    my $self = shift;
    return ${$self->{_reason}};
}

=head2 disconnect_future

    my $future = $conn->disconnect_future;  # Future or undef
    my $reason = await $future;

Returns a Future that resolves when the connection closes B<abnormally>
(client disconnect, transport error). On a clean completion the connection
closes but this Future is deliberately left pending — use C<on_complete> to
observe normal completion.

The Future is created lazily on first call, avoiding allocation overhead
for handlers that don't need async disconnect detection.

The Future resolves with the disconnect reason string.

This is useful for racing against other async operations:

    await Future->wait_any($disconnect_future, $event_future);

=cut

sub disconnect_future {
    my $self = shift;

    # Return cached Future if exists
    return $self->{_future} if $self->{_future};

    # Create new Future (lazy)
    my $conn = $self->{_connection};
    my $loop = $conn && $conn->{server} ? $conn->{server}->loop : undef;

    if ($loop) {
        $self->{_future} = $loop->new_future;
    } else {
        # Fallback if no loop available (shouldn't happen in practice)
        require Future;
        $self->{_future} = Future->new;
    }

    # If already disconnected, resolve immediately
    unless (${$self->{_connected}}) {
        $self->{_future}->done(${$self->{_reason}});
    }

    return $self->{_future};
}

=head2 on_disconnect

    $conn->on_disconnect(sub {
        my ($reason) = @_;
        # cleanup code
    });

Registers a callback to be invoked when disconnect occurs.

=over 4

=item * May be called multiple times to register multiple callbacks

=item * Callbacks are invoked in registration order

=item * Callbacks receive the disconnect reason as the first argument

=item * If registered after disconnect already occurred, callback is
invoked immediately with the reason

=item * One callback's failure does not prevent other callbacks from
being invoked

=back

=cut

sub on_disconnect {
    my ($self, $cb) = @_;

    # Still in flight: register for later.
    if (${$self->{_connected}}) {
        push @{$self->{_callbacks}}, $cb;
        return;
    }

    # Terminal: only fire if the request ended abnormally, not on clean
    # completion (on_disconnect means "something went wrong").
    return if $self->{_completed};

    eval { $cb->(${$self->{_reason}}) };
    warn "on_disconnect callback error: $@" if $@;
}

=head2 on_complete

    $conn->on_complete(sub {
        # request finished cleanly
    });

Registers a callback invoked B<only when the request completes successfully>
(the response was fully delivered without the client disconnecting). It is the
counterpart to L</on_disconnect>: exactly one of the two fires for a given
request.

=over 4

=item * May be called multiple times to register multiple callbacks

=item * Callbacks are invoked in registration order, with no arguments

=item * If registered after the request already completed, the callback is
invoked immediately

=item * If the request ended in an abnormal disconnect, the callback never fires

=item * One callback's failure does not prevent other callbacks from being
invoked

=back

=cut

sub on_complete {
    my ($self, $cb) = @_;

    # Still in flight: register for later.
    if (${$self->{_connected}}) {
        push @{$self->{_complete_callbacks}}, $cb;
        return;
    }

    # Terminal: only fire on clean completion, not on abnormal disconnect.
    return unless $self->{_completed};

    eval { $cb->() };
    warn "on_complete callback error: $@" if $@;
}

=head2 _mark_disconnected

    $conn->_mark_disconnected($reason);

B<Internal method> - Called by the server when disconnect is detected.

Updates the connection state and invokes all registered callbacks.
Applications should not call this method directly.

State transitions occur in this order:

=over 4

=item 1. C<is_connected()> returns false

=item 2. C<disconnect_reason()> returns the reason string

=item 3. C<disconnect_future()> resolves with the reason (if it was created)

=item 4. C<on_disconnect> callbacks are invoked in registration order

=back

=cut

sub _mark_disconnected {
    my ($self, $reason) = @_;

    # Already disconnected - no-op (idempotent)
    return unless ${$self->{_connected}};

    # 1. Update state
    ${$self->{_connected}} = 0;
    ${$self->{_reason}} = $reason // 'unknown';

    # 2. Resolve future if it exists (lazy - may not have been created)
    if ($self->{_future} && !$self->{_future}->is_ready) {
        $self->{_future}->done(${$self->{_reason}});
    }

    # 3. Invoke callbacks
    for my $cb (@{$self->{_callbacks}}) {
        eval { $cb->(${$self->{_reason}}) };
        warn "on_disconnect callback error: $@" if $@;
    }

    # 4. Clear callbacks to release references. The request ended abnormally,
    #    so on_complete callbacks never run.
    $self->{_callbacks}          = [];
    $self->{_complete_callbacks} = [];
}

=head2 _mark_complete

    $conn->_mark_complete;

B<Internal method> - Called by the server when the request completes
successfully (the response was fully delivered). Applications should not call
this method directly.

Transitions to the C<completed> terminal state and invokes C<on_complete>
callbacks in registration order. Unlike L</_mark_disconnected>, it leaves
C<disconnect_reason()> as C<undef> and does B<not> resolve C<disconnect_future()>
or fire C<on_disconnect> callbacks -- a clean completion is not a disconnect.

Idempotent, and a no-op once the connection has already reached a terminal
state (so a stray completion after an abnormal disconnect is ignored).

=cut

sub _mark_complete {
    my ($self) = @_;

    # Already terminal (disconnected or completed) - no-op (idempotent).
    return unless ${$self->{_connected}};

    # Mark the completed terminal state. Reason stays undef; the disconnect
    # Future is deliberately left pending (completion is not a disconnect).
    ${$self->{_connected}} = 0;
    $self->{_completed}    = 1;

    # Invoke completion callbacks (no reason argument).
    for my $cb (@{$self->{_complete_callbacks}}) {
        eval { $cb->() };
        warn "on_complete callback error: $@" if $@;
    }

    # Clear both lists to release references.
    $self->{_complete_callbacks} = [];
    $self->{_callbacks}          = [];
}

1;

__END__

=head1 USAGE WITH PAGI::Request

The L<PAGI::Request> class provides convenience methods that delegate
to the connection object:

    my $req = PAGI::Request->new($scope, $receive);

    # Access connection object directly
    my $conn = $req->connection;

    # Convenience delegates
    $req->is_connected;                    # $conn->is_connected
    $req->is_disconnected;                 # !$conn->is_connected
    $req->disconnect_reason;               # $conn->disconnect_reason
    $req->on_disconnect(sub { ... });      # $conn->on_disconnect(...)
    $req->disconnect_future;               # $conn->disconnect_future

=head1 EXAMPLE: Basic Connection Check

    async sub handler {
        my ($scope, $receive, $send) = @_;
        my $conn = $scope->{'pagi.connection'};

        # Check before expensive work
        return unless $conn->is_connected;

        my $result = await expensive_operation();

        # Check again before responding
        return unless $conn->is_connected;

        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => $result, more => 0 });
    }

=head1 EXAMPLE: Cleanup on Disconnect vs. Completion

    async sub handler {
        my ($scope, $receive, $send) = @_;
        my $conn = $scope->{'pagi.connection'};

        my $temp_file = create_temp_file();
        my $lock = acquire_lock();

        my $cleanup = sub { $temp_file->unlink; $lock->release };

        # Abnormal end: client vanished, or a timeout/error fired mid-request.
        $conn->on_disconnect(sub {
            my ($reason) = @_;
            $cleanup->();
            log_info("Client disconnected: $reason");
        });

        # Clean end: the response was fully delivered.
        $conn->on_complete(sub {
            $cleanup->();
            log_info("Delivered OK");
        });

        # Exactly one of the two callbacks runs, so cleanup happens once.
        my $result = await process_data($temp_file);
        await send_response($send, $result);
    }

=head1 SEE ALSO

L<PAGI::Request> - High-level request API with connection convenience methods

L<PAGI::Server> - Reference server implementation

L<PAGI::Server::Connection> - Per-connection state machine (internal)

=cut
