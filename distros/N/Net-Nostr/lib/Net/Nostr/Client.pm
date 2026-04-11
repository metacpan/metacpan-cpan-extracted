package Net::Nostr::Client;

use strictures 2;

use Carp qw(croak);
use Scalar::Util qw(weaken);
use AnyEvent;
use AnyEvent::WebSocket::Client;
use Net::Nostr::Message;

use Class::Tiny qw(
    _ws_client
    _conn
    _callbacks
    challenge
);

sub new {
    my $class = shift;
    my %args = @_;
    croak "unknown argument(s): " . join(', ', sort keys %args) if %args;
    my $self = bless {}, $class;
    $self->_ws_client(AnyEvent::WebSocket::Client->new);
    $self->_callbacks({});
    return $self;
}

sub connect {
    my ($self, $url, $cb) = @_;
    croak "url is required" unless defined $url;
    croak "callback must be a CODE ref" if defined $cb && ref($cb) ne 'CODE';

    my $cv = AnyEvent->condvar;
    $self->_ws_client->connect($url)->cb(sub {
        my $conn = eval { shift->recv };
        if ($@) {
            $cv->croak("connect failed: $@");
            return;
        }
        $self->_conn($conn);
        $self->_setup_handlers;
        $cv->send;
    });

    if ($cb) {
        $cv->cb(sub { eval { shift->recv }; $cb->($@ || undef) });
        return;
    }

    $cv->recv;
    return $self;
}

sub is_connected {
    my ($self) = @_;
    return defined $self->_conn ? 1 : 0;
}

sub disconnect {
    my ($self) = @_;
    if ($self->_conn) {
        $self->_conn->close;
        $self->_conn(undef);
    }
}

sub publish {
    my ($self, $event) = @_;
    croak "not connected" unless $self->is_connected;
    my $msg = Net::Nostr::Message->new(type => 'EVENT', event => $event);
    $self->_conn->send($msg->serialize);
}

sub subscribe {
    my ($self, $sub_id, @filters) = @_;
    croak "not connected" unless $self->is_connected;
    my $msg = Net::Nostr::Message->new(
        type            => 'REQ',
        subscription_id => $sub_id,
        filters         => \@filters,
    );
    $self->_conn->send($msg->serialize);
}

sub count {
    my ($self, $sub_id, @filters) = @_;
    croak "not connected" unless $self->is_connected;
    my $msg = Net::Nostr::Message->new(
        type            => 'COUNT',
        subscription_id => $sub_id,
        filters         => \@filters,
    );
    $self->_conn->send($msg->serialize);
}

sub close {
    my ($self, $sub_id) = @_;
    croak "not connected" unless $self->is_connected;
    my $msg = Net::Nostr::Message->new(type => 'CLOSE', subscription_id => $sub_id);
    $self->_conn->send($msg->serialize);
}

sub neg_open {
    my ($self, $sub_id, $filter, $initial_msg) = @_;
    croak "not connected" unless $self->is_connected;
    my $msg = Net::Nostr::Message->new(
        type            => 'NEG-OPEN',
        subscription_id => $sub_id,
        filter          => $filter,
        neg_msg         => $initial_msg,
    );
    $self->_conn->send($msg->serialize);
}

sub neg_msg {
    my ($self, $sub_id, $neg_msg) = @_;
    croak "not connected" unless $self->is_connected;
    my $msg = Net::Nostr::Message->new(
        type            => 'NEG-MSG',
        subscription_id => $sub_id,
        neg_msg         => $neg_msg,
    );
    $self->_conn->send($msg->serialize);
}

sub neg_close {
    my ($self, $sub_id) = @_;
    croak "not connected" unless $self->is_connected;
    my $msg = Net::Nostr::Message->new(
        type            => 'NEG-CLOSE',
        subscription_id => $sub_id,
    );
    $self->_conn->send($msg->serialize);
}

sub authenticate {
    my ($self, $key, $relay_url) = @_;
    croak "not connected" unless $self->is_connected;
    croak "key is required" unless $key;
    croak "relay_url is required" unless $relay_url;
    croak "no challenge received" unless defined $self->challenge;

    my $auth_event = $key->create_event(
        kind    => 22242,
        content => '',
        tags    => [
            ['relay', $relay_url],
            ['challenge', $self->challenge],
        ],
    );
    my $msg = Net::Nostr::Message->new(type => 'AUTH', event => $auth_event);
    $self->_conn->send($msg->serialize);
}

sub on {
    my ($self, $type, $cb) = @_;
    croak "callback must be a CODE ref" unless defined $cb && ref($cb) eq 'CODE';
    $self->_callbacks->{$type} = $cb;
}

sub _emit {
    my ($self, $type, @args) = @_;
    my $cb = $self->_callbacks->{$type} or return;
    eval { $cb->(@args); 1 } or warn "callback '$type' died: $@";
}

sub _setup_handlers {
    my ($self) = @_;
    weaken(my $weak_self = $self);
    $self->_conn->on(each_message => sub {
        my ($conn, $message) = @_;
        my $self = $weak_self or return;
        my $msg = eval { Net::Nostr::Message->parse($message->body) };
        return warn "bad message from relay: $@\n" if $@;

        if ($msg->type eq 'EVENT') {
            $self->_emit('event', $msg->subscription_id, $msg->event);
        } elsif ($msg->type eq 'OK') {
            $self->_emit('ok', $msg->event_id, $msg->accepted, $msg->message);
        } elsif ($msg->type eq 'EOSE') {
            $self->_emit('eose', $msg->subscription_id);
        } elsif ($msg->type eq 'NOTICE') {
            $self->_emit('notice', $msg->message);
        } elsif ($msg->type eq 'COUNT') {
            $self->_emit('count', $msg->subscription_id, $msg->count, $msg->approximate);
        } elsif ($msg->type eq 'CLOSED') {
            $self->_emit('closed', $msg->subscription_id, $msg->message);
        } elsif ($msg->type eq 'AUTH') {
            $self->challenge($msg->challenge);
            $self->_emit('auth', $msg->challenge);
        } elsif ($msg->type eq 'NEG-MSG') {
            $self->_emit('neg_msg', $msg->subscription_id, $msg->neg_msg);
        } elsif ($msg->type eq 'NEG-ERR') {
            $self->_emit('neg_err', $msg->subscription_id, $msg->message);
        }
    });

    $self->_conn->on(finish => sub {
        my $self = $weak_self or return;
        $self->_conn(undef);
    });
}

1;

__END__

=head1 NAME

Net::Nostr::Client - WebSocket client for Nostr relays

=head1 SYNOPSIS

    use Net::Nostr::Client;
    use Net::Nostr::Key;
    use Net::Nostr::Filter;

    my $key    = Net::Nostr::Key->new;
    my $client = Net::Nostr::Client->new;

    # Register callbacks before connecting
    $client->on(event => sub {
        my ($sub_id, $event) = @_;
        say "Got event: " . $event->content;
    });

    $client->on(ok => sub {
        my ($event_id, $accepted, $message) = @_;
        say $accepted ? "Accepted" : "Rejected: $message";
    });

    $client->on(eose => sub {
        my ($sub_id) = @_;
        say "End of stored events for $sub_id";
    });

    # Connect (blocks until connected, croaks on failure)
    $client->connect("wss://relay.example.com");

    # Create and publish an event
    my $event = $key->create_event(kind => 1, content => 'hello', tags => []);
    $client->publish($event);

    # Subscribe with one or more filters
    my $filter = Net::Nostr::Filter->new(kinds => [1], limit => 20);
    $client->subscribe('my-feed', $filter);

    # Close a subscription
    $client->close('my-feed');

    # Disconnect
    $client->disconnect;

=head1 DESCRIPTION

A WebSocket client for connecting to Nostr relays. Provides a callback-based
interface for publishing events, managing subscriptions, receiving relay
messages, counting events (NIP-45), and negentropy set reconciliation
(NIP-77). Supports NIP-42 authentication.

=head1 CONSTRUCTOR

=head2 new

    my $client = Net::Nostr::Client->new;

Creates a new client instance. No connection is established until
C<connect> is called. Croaks on unknown arguments.

=head1 METHODS

=head2 connect

    $client->connect($url);

    # Non-blocking with callback:
    $client->connect($url, sub { ... });

Connects to the relay at the given WebSocket URL. Blocks until the
connection is established and returns C<$self> for chaining. Croaks
if the connection fails, C<$url> is not provided, or the callback
is not a CODE ref.

If a callback is provided, connects asynchronously and returns
immediately without blocking. The callback receives a single argument:
C<undef> on success, or an error string on failure.

    $client->connect($url, sub {
        my ($err) = @_;
        if ($err) {
            warn "Connection failed: $err";
            return;
        }
        # connected successfully
    });

=head2 is_connected

    if ($client->is_connected) { ... }

Returns true if the client has an active WebSocket connection.

=head2 disconnect

    $client->disconnect;

Closes the WebSocket connection. C<is_connected> will return false
afterwards. The connection is also automatically cleared if the
relay drops the connection.

=head2 publish

    $client->publish($event);

Sends an EVENT message to the relay. The relay will respond with an OK
message (received via the C<ok> callback). Croaks if not connected.

    my $key   = Net::Nostr::Key->new;
    my $event = $key->create_event(kind => 1, content => 'hello', tags => []);
    $client->publish($event);

=head2 subscribe

    $client->subscribe('sub-id', $filter1, $filter2);

Sends a REQ message to the relay with the given subscription ID and
filters. The relay will send matching stored events (via C<event>
callback), then an EOSE message (via C<eose> callback), then live
events as they arrive. Croaks if not connected.

=head2 count

    $client->count('query-id', $filter1, $filter2);

Sends a COUNT message (NIP-45) to the relay with the given query ID and
filters. The relay will respond with a count (received via the C<count>
callback). Unlike C<subscribe>, COUNT is one-shot and does not create a
live subscription. Croaks if not connected.

    $client->on(count => sub {
        my ($query_id, $count, $approximate) = @_;
        say "Got $count events" . ($approximate ? ' (approximate)' : '');
    });
    $client->count('followers', Net::Nostr::Filter->new(
        kinds => [3], '#p' => [$pubkey],
    ));

=head2 close

    $client->close('sub-id');

Sends a CLOSE message to stop receiving events for the given
subscription ID. Croaks if not connected.

=head2 neg_open

    $client->neg_open($sub_id, $filter, $initial_msg);

Sends a NEG-OPEN message (NIP-77) to initiate negentropy set reconciliation.
C<$filter> is a L<Net::Nostr::Filter> object, and C<$initial_msg> is the
hex-encoded initial message from L<Net::Nostr::Negentropy/initiate>.
The relay will respond with a C<neg_msg> callback. Croaks if not connected.

Subscription IDs are in a separate namespace from C<subscribe>. If a
NEG-OPEN is issued for a currently open subscription ID, the relay
closes the existing session first.

    use Net::Nostr::Negentropy;

    my $ne = Net::Nostr::Negentropy->new;
    # add local events via $ne->add_item(...)
    $ne->seal;
    $client->neg_open('sync1', $filter, $ne->initiate);

=head2 neg_msg

    $client->neg_msg($sub_id, $msg);

Sends a NEG-MSG message (NIP-77) to continue a negentropy reconciliation
round. C<$msg> is the hex-encoded message from L<Net::Nostr::Negentropy/reconcile>.
Croaks if not connected.

=head2 neg_close

    $client->neg_close($sub_id);

Sends a NEG-CLOSE message (NIP-77) to terminate a negentropy session and
release relay resources. Croaks if not connected.

=head2 authenticate

    $client->authenticate($key, $relay_url);

Sends a NIP-42 AUTH event to the relay. The C<$key> is a
L<Net::Nostr::Key> object used to sign the authentication event,
and C<$relay_url> is the relay's URL for the C<relay> tag.

The client must have received an AUTH challenge from the relay first
(stored in C<challenge>). Croaks if not connected, if C<$key> or
C<$relay_url> is missing, or if no challenge has been received.

    $client->on(auth => sub {
        my ($challenge) = @_;
        $client->authenticate($key, 'wss://relay.example.com/');
    });

=head2 challenge

    my $challenge = $client->challenge;

Returns the most recent AUTH challenge string received from the relay,
or C<undef> if no challenge has been received.

=head2 on

    $client->on($event_type => sub { ... });

Registers a callback for relay messages. The callback must be a CODE
ref; croaks otherwise. Only one callback may be registered per event
type -- calling C<on> again for the same type replaces the previous
callback. Supported event types:

=over 4

=item C<event> - C<sub { my ($subscription_id, $event) = @_; }>

Called for each EVENT message from the relay (both stored and live).

=item C<ok> - C<sub { my ($event_id, $accepted, $message) = @_; }>

Called when the relay responds to a published event.

=item C<eose> - C<sub { my ($subscription_id) = @_; }>

Called when the relay finishes sending stored events for a subscription.

=item C<notice> - C<sub { my ($message) = @_; }>

Called when the relay sends a human-readable NOTICE.

=item C<count> - C<sub { my ($query_id, $count, $approximate) = @_; }>

Called when the relay responds to a COUNT request (NIP-45). C<$count> is
the number of matching events, C<$approximate> is true if the count is
probabilistic. HyperLogLog (C<hll>) values are not currently parsed.

=item C<closed> - C<sub { my ($subscription_id, $message) = @_; }>

Called when the relay closes a subscription.

=item C<auth> - C<sub { my ($challenge) = @_; }>

Called when the relay sends an AUTH challenge (NIP-42). The client
should respond by calling C<authenticate>.

=item C<neg_msg> - C<sub { my ($subscription_id, $msg) = @_; }>

Called when the relay sends a NEG-MSG response (NIP-77). C<$msg> is the
hex-encoded negentropy message to pass to L<Net::Nostr::Negentropy/reconcile>.

=item C<neg_err> - C<sub { my ($subscription_id, $message) = @_; }>

Called when the relay sends a NEG-ERR (NIP-77). The negentropy session
is considered closed after this.

=back

=head1 SEE ALSO

L<NIP-01|https://github.com/nostr-protocol/nips/blob/master/01.md>,
L<NIP-45|https://github.com/nostr-protocol/nips/blob/master/45.md>,
L<NIP-77|https://github.com/nostr-protocol/nips/blob/master/77.md>,
L<Net::Nostr>, L<Net::Nostr::Event>, L<Net::Nostr::Filter>, L<Net::Nostr::Relay>,
L<Net::Nostr::Negentropy>

=cut
