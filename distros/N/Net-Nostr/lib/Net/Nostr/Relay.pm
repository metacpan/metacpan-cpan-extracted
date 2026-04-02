package Net::Nostr::Relay;

use strictures 2;

use Net::Nostr::Message;
use Net::Nostr::Filter;
use Net::Nostr::Deletion;

use AnyEvent::Socket qw(tcp_server);
use AnyEvent::WebSocket::Server;
use Crypt::PK::ECC;
use Crypt::PK::ECC::Schnorr;
use Crypt::PRNG qw(random_bytes);
use Digest::SHA qw(sha256_hex);
use JSON;

use Class::Tiny qw(
    _server
    connections
    subscriptions
    events
    _guard
    verify_signatures
    max_connections_per_ip
    relay_url
    _conn_count_by_ip
    _run_cv
    _challenges
    _authenticated
);

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    $self->verify_signatures(1) unless defined $self->verify_signatures;
    $self->_server(AnyEvent::WebSocket::Server->new());
    return $self;
}

sub start {
    my ($self, $host, $port) = @_;
    $self->_conn_count_by_ip({});
    $self->_guard(tcp_server($host, $port, sub {
        my ($fh, $peer_host) = @_;
        if (defined $self->max_connections_per_ip) {
            my $count = $self->_conn_count_by_ip->{$peer_host} || 0;
            if ($count >= $self->max_connections_per_ip) {
                close $fh;
                return;
            }
        }
        $self->_conn_count_by_ip->{$peer_host}++;
        $self->_server->establish($fh)->cb(sub {
            my $conn = eval { shift->recv };
            if ($@) {
                $self->_conn_count_by_ip->{$peer_host}--;
                warn "WebSocket handshake failed: $@\n";
                return;
            }
            $self->_on_connection($conn, $peer_host);
        });
    }));
}

sub run {
    my ($self, $host, $port) = @_;
    $self->start($host, $port);
    $self->_run_cv(AnyEvent->condvar);
    $self->_run_cv->recv;
    $self->_run_cv(undef);
    $self->_stop_cleanup;
}

sub stop {
    my ($self) = @_;
    if ($self->_run_cv) {
        $self->_run_cv->send;
        return;
    }
    $self->_stop_cleanup;
}

sub authenticated_pubkeys {
    my ($self) = @_;
    return { %{$self->_authenticated || {}} };
}

sub _stop_cleanup {
    my ($self) = @_;
    $self->_guard(undef);
    for my $conn (values %{$self->connections || {}}) {
        $conn->close;
    }
    $self->connections({});
    $self->subscriptions({});
    $self->_conn_count_by_ip({});
    $self->_challenges({});
    $self->_authenticated({});
}

sub broadcast {
    my ($self, $event) = @_;
    my $subs = $self->subscriptions || {};
    for my $conn_id (keys %$subs) {
        my $conn = $self->connections->{$conn_id} or next;
        for my $sub_id (keys %{$subs->{$conn_id}}) {
            my $filters = $subs->{$conn_id}{$sub_id};
            if (Net::Nostr::Filter->matches_any($event, @$filters)) {
                $conn->send(Net::Nostr::Message->new(type => 'EVENT', subscription_id => $sub_id, event => $event)->serialize);
            }
        }
    }
}

my $CONN_ID = 0;

sub _on_connection {
    my ($self, $conn, $peer_host) = @_;
    my $conn_id = ++$CONN_ID;

    $self->connections($self->connections // {});
    $self->subscriptions($self->subscriptions // {});
    $self->events($self->events // []);
    $self->_challenges($self->_challenges // {});
    $self->_authenticated($self->_authenticated // {});

    $self->connections->{$conn_id} = $conn;

    # Send AUTH challenge
    my $challenge = unpack('H*', random_bytes(32));
    $self->_challenges->{$conn_id} = $challenge;
    $self->_authenticated->{$conn_id} = {};
    $conn->send(Net::Nostr::Message->new(type => 'AUTH', challenge => $challenge)->serialize);

    $conn->on(each_message => sub {
        my ($conn, $message) = @_;
        my $arr = eval { JSON::decode_json($message->body) };
        return warn "bad message: $@\n" if $@ || ref($arr) ne 'ARRAY' || !@$arr;

        my $type = $arr->[0];

        if ($type eq 'REQ') {
            my $sub_id = $arr->[1] // '';
            my $msg = eval { Net::Nostr::Message->parse($message->body) };
            if ($@) {
                $conn->send(Net::Nostr::Message->new(
                    type => 'CLOSED', subscription_id => $sub_id,
                    message => "error: $@"
                )->serialize);
                return;
            }
            $self->_handle_req($conn_id, $msg->subscription_id, @{$msg->filters});
            return;
        }

        my $msg = eval { Net::Nostr::Message->parse($message->body) };
        return warn "bad message: $@\n" if $@;

        if ($msg->type eq 'EVENT') {
            $self->_handle_event($conn_id, $msg->event);
        } elsif ($msg->type eq 'CLOSE') {
            $self->_handle_close($conn_id, $msg->subscription_id);
        } elsif ($msg->type eq 'AUTH') {
            $self->_handle_auth($conn_id, $msg->event);
        }
    });

    $conn->on(finish => sub {
        delete $self->connections->{$conn_id};
        delete $self->subscriptions->{$conn_id};
        delete $self->_challenges->{$conn_id};
        delete $self->_authenticated->{$conn_id};
        $self->_conn_count_by_ip->{$peer_host}-- if defined $peer_host;
    });
}

sub _relay_host_matches {
    my ($expected, $got) = @_;
    my ($eh) = $expected =~ m{^wss?://([^:/]+)}i;
    my ($gh) = $got      =~ m{^wss?://([^:/]+)}i;
    return 0 unless defined $eh && defined $gh;
    return lc($eh) eq lc($gh);
}

my $HEX64  = qr/\A[0-9a-f]{64}\z/;
my $HEX128 = qr/\A[0-9a-f]{128}\z/;

sub _validate_event {
    my ($self, $event) = @_;
    return 'invalid: bad id format'     unless defined $event->id     && $event->id     =~ $HEX64;
    return 'invalid: bad pubkey format' unless defined $event->pubkey && $event->pubkey =~ $HEX64;
    return 'invalid: bad sig format'    unless defined $event->sig    && $event->sig    =~ $HEX128;

    my $expected_id = sha256_hex($event->json_serialize);
    return 'invalid: id does not match hash' unless $event->id eq $expected_id;

    if ($self->verify_signatures) {
        my $sig_valid = eval {
            my $pubkey_raw = pack('H*', $event->pubkey);
            # BIP-340 x-only pubkey: prepend 02 prefix for compressed point
            my $compressed = "\x02" . $pubkey_raw;
            my $pk = Crypt::PK::ECC->new;
            $pk->import_key_raw($compressed, 'secp256k1');
            my $verifier = Crypt::PK::ECC::Schnorr->new(\$pk->export_key_der('public'));
            my $sig_raw = pack('H*', $event->sig);
            $verifier->verify_message($event->id, $sig_raw);
        };
        return 'invalid: bad signature' unless $sig_valid;
    }

    return undef;
}

sub _is_newer {
    my ($new, $existing) = @_;
    return 1 if $new->created_at > $existing->created_at;
    return 1 if $new->created_at == $existing->created_at && $new->id lt $existing->id;
    return 0;
}

sub _handle_event {
    my ($self, $conn_id, $event) = @_;
    my $conn = $self->connections->{$conn_id};

    my $error = $self->_validate_event($event);
    if ($error) {
        $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => ($event->id // ''), accepted => 0, message => $error)->serialize);
        return;
    }

    # Relays MUST exclude kind 22242 events from being broadcasted (NIP-42)
    if ($event->kind == 22242) {
        $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 0, message => 'invalid: auth events should use AUTH message')->serialize);
        return;
    }

    # duplicate detection
    for my $existing (@{$self->events}) {
        if ($existing->id eq $event->id) {
            $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 1, message => 'duplicate: already have this event')->serialize);
            return;
        }
    }

    # ephemeral events: broadcast but don't store
    if ($event->is_ephemeral) {
        $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 1, message => '')->serialize);
        $self->broadcast($event);
        return;
    }

    # replaceable events: keep only latest per pubkey+kind
    if ($event->is_replaceable) {
        for my $i (0 .. $#{$self->events}) {
            my $existing = $self->events->[$i];
            if ($existing->pubkey eq $event->pubkey && $existing->kind == $event->kind) {
                if (_is_newer($event, $existing)) {
                    splice @{$self->events}, $i, 1;
                } else {
                    $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 1, message => 'duplicate: have a newer version')->serialize);
                    return;
                }
                last;
            }
        }
    }

    # addressable events: keep only latest per pubkey+kind+d_tag
    if ($event->is_addressable) {
        my $d = $event->d_tag;
        for my $i (0 .. $#{$self->events}) {
            my $existing = $self->events->[$i];
            if ($existing->pubkey eq $event->pubkey && $existing->kind == $event->kind && $existing->d_tag eq $d) {
                if (_is_newer($event, $existing)) {
                    splice @{$self->events}, $i, 1;
                } else {
                    $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 1, message => 'duplicate: have a newer version')->serialize);
                    return;
                }
                last;
            }
        }
    }

    # deletion requests: remove matching events, but not other kind 5 events
    if ($event->kind == 5) {
        $self->_handle_deletion($event);
    }

    push @{$self->events}, $event;
    $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 1, message => '')->serialize);
    $self->broadcast($event);
}

sub _handle_deletion {
    my ($self, $del_event) = @_;
    my $del = Net::Nostr::Deletion->from_event($del_event);
    my $del_pubkey = $del_event->pubkey;
    my $del_ts = $del_event->created_at;

    my @kept;
    for my $stored (@{$self->events}) {
        # Never delete other kind 5 events
        if ($stored->kind == 5) {
            push @kept, $stored;
            next;
        }
        # Check e tags: delete if pubkey matches and event is referenced
        my $dominated = 0;
        if ($stored->pubkey eq $del_pubkey) {
            for my $id (@{$del->event_ids}) {
                if ($stored->id eq $id) {
                    $dominated = 1;
                    last;
                }
            }
            # Check a tags: delete addressable events up to deletion timestamp
            if (!$dominated && $stored->is_addressable) {
                my $addr = $stored->kind . ':' . $stored->pubkey . ':' . $stored->d_tag;
                for my $del_addr (@{$del->addresses}) {
                    if ($addr eq $del_addr && $stored->created_at <= $del_ts) {
                        $dominated = 1;
                        last;
                    }
                }
            }
        }
        push @kept, $stored unless $dominated;
    }
    $self->events(\@kept);
}

sub _handle_auth {
    my ($self, $conn_id, $event) = @_;
    my $conn = $self->connections->{$conn_id};

    # Validate the event structure first
    my $error = $self->_validate_event($event);
    if ($error) {
        $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => ($event->id // ''), accepted => 0, message => $error)->serialize);
        return;
    }

    # Kind must be 22242
    unless ($event->kind == 22242) {
        $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 0, message => 'invalid: auth event must be kind 22242')->serialize);
        return;
    }

    # created_at must be within ~10 minutes
    my $now = time();
    unless (abs($event->created_at - $now) <= 600) {
        $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 0, message => 'invalid: auth event timestamp too far from current time')->serialize);
        return;
    }

    # Relay tag must match (if relay_url is configured)
    if (defined $self->relay_url) {
        my $got_relay;
        for my $tag (@{$event->tags}) {
            if ($tag->[0] eq 'relay') {
                $got_relay = $tag->[1];
                last;
            }
        }
        unless (defined $got_relay && _relay_host_matches($self->relay_url, $got_relay)) {
            $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 0, message => 'invalid: relay URL does not match')->serialize);
            return;
        }
    }

    # Challenge tag must match
    my $expected_challenge = $self->_challenges->{$conn_id};
    my $got_challenge;
    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'challenge') {
            $got_challenge = $tag->[1];
            last;
        }
    }
    unless (defined $got_challenge && $got_challenge eq $expected_challenge) {
        $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 0, message => 'invalid: challenge does not match')->serialize);
        return;
    }

    # Track the authenticated pubkey for this connection
    $self->_authenticated->{$conn_id}{$event->pubkey} = 1;

    $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 1, message => '')->serialize);
}

sub _handle_req {
    my ($self, $conn_id, $sub_id, @filters) = @_;
    my $conn = $self->connections->{$conn_id};

    $self->subscriptions->{$conn_id} //= {};
    $self->subscriptions->{$conn_id}{$sub_id} = \@filters;

    # collect matching events
    my @matching;
    for my $event (@{$self->events}) {
        push @matching, $event if Net::Nostr::Filter->matches_any($event, @filters);
    }

    # sort by created_at DESC, then id ASC for ties
    @matching = sort {
        $b->created_at <=> $a->created_at || $a->id cmp $b->id
    } @matching;

    # apply limit (use minimum limit across filters that specify one)
    my $limit;
    for my $f (@filters) {
        if (defined $f->limit) {
            $limit = $f->limit if !defined $limit || $f->limit < $limit;
        }
    }
    splice @matching, $limit if defined $limit && $limit < @matching;

    for my $event (@matching) {
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', subscription_id => $sub_id, event => $event)->serialize);
    }

    $conn->send(Net::Nostr::Message->new(type => 'EOSE', subscription_id => $sub_id)->serialize);
}

sub _handle_close {
    my ($self, $conn_id, $sub_id) = @_;
    delete $self->subscriptions->{$conn_id}{$sub_id} if $self->subscriptions->{$conn_id};
}

1;

__END__

=head1 NAME

Net::Nostr::Relay - Nostr WebSocket relay server

=head1 SYNOPSIS

    use Net::Nostr::Relay;

    # Standalone relay (blocks until stop is called)
    my $relay = Net::Nostr::Relay->new;
    $relay->run('127.0.0.1', 8080);

    # Non-blocking: run a relay and client together
    use Net::Nostr::Key;
    use Net::Nostr::Client;

    my $relay = Net::Nostr::Relay->new;
    $relay->start('127.0.0.1', 8080);

    my $key    = Net::Nostr::Key->new;
    my $client = Net::Nostr::Client->new;
    $client->connect('ws://127.0.0.1:8080');

    my $event = $key->create_event(kind => 1, content => 'hello', tags => []);
    $client->publish($event);

=head1 DESCRIPTION

An in-process Nostr relay. Accepts WebSocket connections, stores events in
memory, manages subscriptions, and broadcasts new events to matching
subscribers. Events do not persist across restarts.

Implements:

=over 4

=item * L<NIP-01|https://github.com/nostr-protocol/nips/blob/master/01.md> - Basic protocol flow

=item * L<NIP-09|https://github.com/nostr-protocol/nips/blob/master/09.md> - Event deletion requests

=item * L<NIP-42|https://github.com/nostr-protocol/nips/blob/master/42.md> - Authentication of clients to relays

=back

Supports all NIP-01 event semantics:

=over 4

=item * Regular events - stored and broadcast

=item * Replaceable events (kinds 0, 3, 10000-19999) - only latest per pubkey+kind

=item * Ephemeral events (kinds 20000-29999) - broadcast but never stored

=item * Addressable events (kinds 30000-39999) - only latest per pubkey+kind+d_tag

=back

=head1 CONSTRUCTOR

=head2 new

    my $relay = Net::Nostr::Relay->new;
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    my $relay = Net::Nostr::Relay->new(max_connections_per_ip => 10);
    my $relay = Net::Nostr::Relay->new(relay_url => 'wss://relay.example.com/');

Creates a new relay instance. Options:

=over 4

=item C<verify_signatures> - Enable Schnorr signature verification (default: true).
Pass C<0> to disable (useful for testing with synthetic events).

=item C<max_connections_per_ip> - Maximum simultaneous WebSocket connections
allowed from a single IP address. Connections beyond this limit are rejected
at the TCP level. Default: C<undef> (unlimited).

=item C<relay_url> - The relay's own WebSocket URL (e.g. C<wss://relay.example.com/>).
When set, NIP-42 AUTH events are validated to ensure the C<relay> tag matches
this URL (domain comparison, case-insensitive). Default: C<undef> (relay tag
not validated).

=back

=head1 METHODS

=head2 run

    $relay->run('127.0.0.1', 8080);

Starts the relay and blocks until C<stop> is called. Equivalent to
calling C<start> followed by a blocking event loop.

=head2 start

    $relay->start('127.0.0.1', 8080);

Starts listening for WebSocket connections on the given host and port.
Returns immediately without blocking. Use this when you want to embed
the relay in a larger application, run a client and relay in the same
process, or compose with other AnyEvent watchers.

    # Run a relay and client together
    my $relay = Net::Nostr::Relay->new;
    $relay->start('127.0.0.1', 8080);

    my $client = Net::Nostr::Client->new;
    $client->connect('ws://127.0.0.1:8080');

=head2 stop

    $relay->stop;

Stops the relay, closes all connections, and clears all subscriptions.
If the relay was started with C<run>, also unblocks it.
Safe to call on an unstarted relay.

=head2 broadcast

    $relay->broadcast($event);

Sends the event to all connected clients whose subscriptions match.
Normally called internally when a new event is accepted, but can be
called directly for testing or custom event injection.

=head2 connections

    my $conns = $relay->connections;  # hashref

Returns the hashref of active connections.

=head2 subscriptions

    my $subs = $relay->subscriptions;  # hashref

Returns the hashref of active subscriptions, keyed by connection ID
then subscription ID.

=head2 events

    my $events = $relay->events;  # arrayref of Net::Nostr::Event

Returns the arrayref of stored events. This list is kept in memory only
and reflects replaceable/addressable semantics (only the latest version
of each replaceable or addressable event is retained). Ephemeral events
are never stored here.

=head2 verify_signatures

    my $bool = $relay->verify_signatures;

Returns whether Schnorr signature verification is enabled (default: true).

=head2 max_connections_per_ip

    my $limit = $relay->max_connections_per_ip;

Returns the maximum number of simultaneous connections allowed per IP
address, or C<undef> if unlimited (the default).

    my $relay = Net::Nostr::Relay->new(max_connections_per_ip => 10);
    $relay->start('0.0.0.0', 8080);

=head2 relay_url

    my $url = $relay->relay_url;

Returns the relay's own WebSocket URL, or C<undef> if not set.
Used for NIP-42 relay tag validation.

    my $relay = Net::Nostr::Relay->new(relay_url => 'wss://relay.example.com/');
    $relay->start('0.0.0.0', 8080);

=head2 authenticated_pubkeys

    my $auth = $relay->authenticated_pubkeys;

Returns a hashref of authenticated pubkeys per connection (NIP-42).
Keys are connection IDs, values are hashrefs of pubkey hex strings.

    my $auth = $relay->authenticated_pubkeys;
    for my $conn_id (keys %$auth) {
        for my $pubkey (keys %{$auth->{$conn_id}}) {
            say "Connection $conn_id authenticated as $pubkey";
        }
    }

=head1 SEE ALSO

L<Net::Nostr>, L<Net::Nostr::Client>, L<Net::Nostr::Event>

=cut
