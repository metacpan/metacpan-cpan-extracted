package Net::Nostr::Relay;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Message;
use Net::Nostr::Filter;
use Net::Nostr::Deletion;

use AnyEvent::Socket qw(tcp_server);
use AnyEvent::WebSocket::Server;
use Crypt::PK::ECC;
use Crypt::PK::ECC::Schnorr;
use Crypt::PRNG qw(random_bytes);
use Digest::SHA qw(sha256_hex);
use JSON ();
use Socket qw(MSG_PEEK);

use Net::Nostr::Negentropy;
use Net::Nostr::RelayInfo;

use Net::Nostr::RelayStore;

use Class::Tiny qw(
    _server
    _connections
    _subscriptions
    store
    _guard
    verify_signatures
    max_connections_per_ip
    max_events
    event_rate_limit
    relay_url
    relay_info
    _conn_count_by_ip
    _run_cv
    _challenges
    _authenticated
    _nip11_watchers
    min_pow_difficulty
    _rate_state
    max_subscriptions
    max_filters
    max_content_length
    max_event_tags
    max_limit
    default_limit
    created_at_lower_limit
    created_at_upper_limit
    max_message_length
    on_event
    idle_timeout
    shutdown_timeout
    _idle_timers
    _sub_by_kind
    _sub_no_kind
    _neg_sessions
);

sub connections {
    my ($self) = @_;
    return { %{$self->_connections || {}} };
}

sub subscriptions {
    my ($self) = @_;
    my $internal = $self->_subscriptions || {};
    return { map { $_ => { %{$internal->{$_}} } } keys %$internal };
}

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    $self->verify_signatures(1) unless defined $self->verify_signatures;

    # Validate event_rate_limit format
    if (defined $self->event_rate_limit) {
        croak "event_rate_limit must be 'count/seconds' (e.g. '10/60')"
            unless $self->event_rate_limit =~ m{^(\d+)/(\d+)$} && $1 > 0 && $2 > 0;
    }

    # Validate positive integer options
    for my $opt (qw(max_subscriptions max_filters max_content_length
                     max_event_tags max_limit default_limit
                     created_at_lower_limit created_at_upper_limit
                     max_message_length)) {
        if (defined $self->$opt) {
            croak "$opt must be a positive integer"
                unless $self->$opt =~ /^\d+$/ && $self->$opt > 0;
        }
    }

    # Validate on_event callback
    if (defined $self->on_event) {
        croak "on_event must be a code reference"
            unless ref($self->on_event) eq 'CODE';
    }

    # Initialize store: use provided store, or build default
    if (!$self->store) {
        my %store_args;
        $store_args{max_events} = $self->max_events if defined $self->max_events;
        $self->store(Net::Nostr::RelayStore->new(%store_args));
    }

    # Validate idle_timeout and shutdown_timeout
    for my $opt (qw(idle_timeout shutdown_timeout)) {
        if (defined $self->$opt) {
            croak "$opt must be a positive integer"
                unless $self->$opt =~ /^\d+$/ && $self->$opt > 0;
        }
    }

    $self->_rate_state({});
    $self->_idle_timers({});
    $self->_sub_by_kind({});
    $self->_sub_no_kind({});
    $self->_server(AnyEvent::WebSocket::Server->new());
    return $self;
}

sub events {
    my ($self, @args) = @_;
    if (@args) {
        # Setter: clear store and re-populate (backward compat)
        $self->store->clear;
        my $events = $args[0] // [];
        $self->store->store($_) for @$events;
        return $events;
    }
    return $self->store->all_events;
}

sub inject_event {
    my ($self, $event) = @_;
    $self->store->store($event);
}

sub start {
    my ($self, $host, $port) = @_;
    $self->_conn_count_by_ip({});
    $self->_nip11_watchers({});
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

        if ($self->relay_info) {
            $self->_handle_nip11_or_ws($fh, $peer_host);
        } else {
            $self->_establish_ws($fh, $peer_host);
        }
    }));
}

sub _establish_ws {
    my ($self, $fh, $peer_host) = @_;
    $self->_server->establish($fh)->cb(sub {
        my $conn = eval { shift->recv };
        if ($@) {
            $self->_conn_count_by_ip->{$peer_host}--;
            warn "WebSocket handshake failed: $@\n";
            return;
        }
        $self->_on_connection($conn, $peer_host);
    });
}

sub _handle_nip11_or_ws {
    my ($self, $fh, $peer_host) = @_;
    my $fileno = fileno($fh);
    my $buf = '';
    my ($w, $timer);

    my $cleanup = sub {
        undef $w;
        undef $timer;
        delete $self->_nip11_watchers->{$fileno};
    };

    my $dispatch = sub {
        if ($buf =~ /^OPTIONS\s/i) {
            sysread($fh, my $discard, 8192);
            syswrite($fh, Net::Nostr::RelayInfo->cors_preflight_response);
            close $fh;
            $self->_conn_count_by_ip->{$peer_host}--;
            return;
        }

        if ($buf =~ /Accept:\s*application\/nostr\+json/i
            && $buf !~ /Upgrade:\s*websocket/i) {
            sysread($fh, my $discard, 8192);
            syswrite($fh, $self->relay_info->to_http_response);
            close $fh;
            $self->_conn_count_by_ip->{$peer_host}--;
            return;
        }

        $self->_establish_ws($fh, $peer_host);
    };

    $w = AnyEvent->io(fh => $fh, poll => 'r', cb => sub {
        my $chunk = '';
        recv($fh, $chunk, 8192, MSG_PEEK);
        $buf = $chunk;  # MSG_PEEK returns the full buffer each time

        if ($buf =~ /\r\n\r\n/ || length($buf) >= 8192) {
            $cleanup->();
            $dispatch->();
        }
    });

    $timer = AnyEvent->timer(after => 5, cb => sub {
        $cleanup->();
        # Timed out waiting for headers -- fall through to WebSocket
        $self->_establish_ws($fh, $peer_host);
    });

    $self->_nip11_watchers->{$fileno} = [$w, $timer];
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

sub graceful_stop {
    my ($self) = @_;

    # Stop accepting new connections immediately
    $self->_guard(undef);

    # Send NOTICE to all connected clients
    my $notice = Net::Nostr::Message->new(
        type => 'NOTICE',
        message => 'shutting down',
    )->serialize;
    for my $conn (values %{$self->_connections || {}}) {
        eval { $conn->send($notice) };
    }

    my $timeout = $self->shutdown_timeout // 5;
    my $t; $t = AnyEvent->timer(after => $timeout, cb => sub {
        undef $t;
        $self->stop;
    });
    # Store the timer to prevent GC
    $self->{_shutdown_timer} = $t;
}

sub authenticated_pubkeys {
    my ($self) = @_;
    my $internal = $self->_authenticated || {};
    return { map { $_ => { %{$internal->{$_}} } } keys %$internal };
}

sub _stop_cleanup {
    my ($self) = @_;
    $self->_guard(undef);
    for my $conn (values %{$self->_connections || {}}) {
        $conn->close;
    }
    $self->_connections({});
    $self->_subscriptions({});
    $self->_conn_count_by_ip({});
    $self->_challenges({});
    $self->_authenticated({});
    $self->_nip11_watchers({});
    $self->_rate_state({});
    $self->_idle_timers({});
    $self->_sub_by_kind({});
    $self->_sub_no_kind({});
    $self->_neg_sessions({});
}

sub broadcast {
    my ($self, $event) = @_;
    # NIP-40: Do not broadcast expired events
    return if $event->is_expired;

    # Collect candidate subscriptions from inverted index
    my %candidates;  # "$conn_id\0$sub_id" => [$conn_id, $sub_id]

    # Subscriptions that filter on this event's kind
    my $kind_subs = $self->_sub_by_kind->{$event->kind};
    if ($kind_subs) {
        for my $key (keys %$kind_subs) {
            $candidates{$key} = $kind_subs->{$key};
        }
    }

    # Subscriptions with no kind filter (match any kind)
    my $no_kind = $self->_sub_no_kind;
    for my $key (keys %$no_kind) {
        $candidates{$key} = $no_kind->{$key};
    }

    my $subs = $self->_subscriptions || {};
    for my $entry (values %candidates) {
        my ($conn_id, $sub_id) = @$entry;
        my $conn = $self->_connections->{$conn_id} or next;
        my $filters = $subs->{$conn_id}{$sub_id} or next;
        if (Net::Nostr::Filter->matches_any($event, @$filters)) {
            $conn->send(Net::Nostr::Message->new(type => 'EVENT', subscription_id => $sub_id, event => $event)->serialize);
        }
    }
}

my $CONN_ID = 0;

sub _on_connection {
    my ($self, $conn, $peer_host) = @_;
    my $conn_id = ++$CONN_ID;

    $self->_connections($self->_connections // {});
    $self->_subscriptions($self->_subscriptions // {});
    $self->_challenges($self->_challenges // {});
    $self->_authenticated($self->_authenticated // {});
    $self->_neg_sessions($self->_neg_sessions // {});

    $self->_connections->{$conn_id} = $conn;

    # Initialize rate limiting state for this connection
    if (defined $self->event_rate_limit) {
        my ($count, $seconds) = $self->event_rate_limit =~ m{^(\d+)/(\d+)$};
        $self->_rate_state->{$conn_id} = {
            tokens => $count,
            max_tokens => $count,
            last_refill => time(),
            refill_seconds => $seconds,
        };
    }

    # Send AUTH challenge
    my $challenge = unpack('H*', random_bytes(32));
    $self->_challenges->{$conn_id} = $challenge;
    $self->_authenticated->{$conn_id} = {};
    $conn->send(Net::Nostr::Message->new(type => 'AUTH', challenge => $challenge)->serialize);

    # Idle timeout: disconnect clients that send no messages
    if (defined $self->idle_timeout) {
        my $reset_idle = sub {
            $self->_idle_timers->{$conn_id} = AnyEvent->timer(
                after => $self->idle_timeout,
                cb => sub {
                    my $c = $self->_connections->{$conn_id};
                    $c->close if $c;
                },
            );
        };
        $reset_idle->();
        $self->{_reset_idle}{$conn_id} = $reset_idle;
    }

    $conn->on(each_message => sub {
        my ($conn, $message) = @_;
        my $raw = $message->body;

        # Reset idle timer on any activity
        if ($self->{_reset_idle} && $self->{_reset_idle}{$conn_id}) {
            $self->{_reset_idle}{$conn_id}->();
        }

        if (defined $self->max_message_length && length($raw) > $self->max_message_length) {
            $conn->send(Net::Nostr::Message->new(
                type => 'NOTICE', message => "error: message too large",
            )->serialize);
            return;
        }

        my $arr = eval { JSON::decode_json($raw) };
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

        if ($type eq 'COUNT') {
            my $sub_id = $arr->[1] // '';
            my $msg = eval { Net::Nostr::Message->parse($message->body) };
            if ($@) {
                $conn->send(Net::Nostr::Message->new(
                    type => 'CLOSED', subscription_id => $sub_id,
                    message => "error: $@"
                )->serialize);
                return;
            }
            $self->_handle_count($conn_id, $msg->subscription_id, @{$msg->filters});
            return;
        }

        if ($type eq 'NEG-OPEN') {
            my $sub_id = $arr->[1] // '';
            my $msg = eval { Net::Nostr::Message->parse($message->body) };
            if ($@) {
                my $reason = $@;
                $reason =~ s/\n\z//;
                $conn->send(Net::Nostr::Message->new(
                    type => 'NEG-ERR', subscription_id => $sub_id,
                    message => "error: $reason",
                )->serialize);
                return;
            }
            $self->_handle_neg_open($conn_id, $msg);
            return;
        }

        if ($type eq 'NEG-MSG') {
            my $sub_id = $arr->[1] // '';
            my $msg = eval { Net::Nostr::Message->parse($message->body) };
            if ($@) {
                my $reason = $@;
                $reason =~ s/\n\z//;
                $conn->send(Net::Nostr::Message->new(
                    type => 'NEG-ERR', subscription_id => $sub_id,
                    message => "error: $reason",
                )->serialize);
                return;
            }
            $self->_handle_neg_msg($conn_id, $msg);
            return;
        }

        if ($type eq 'NEG-CLOSE') {
            $self->_handle_neg_close($conn_id, $arr->[1] // '');
            return;
        }

        my $msg = eval { Net::Nostr::Message->parse($message->body) };
        if ($@) {
            if ($type eq 'EVENT' || $type eq 'AUTH') {
                my $raw_id = (ref($arr->[1]) eq 'HASH' ? $arr->[1]{id} : '') // '';
                my $event_id = $raw_id =~ /\A[0-9a-f]{64}\z/ ? $raw_id : ('0' x 64);
                my $reason = $@;
                $reason =~ s/\n\z//;
                $conn->send(Net::Nostr::Message->new(
                    type => 'OK', event_id => $event_id,
                    accepted => 0, message => "invalid: $reason"
                )->serialize);
            }
            return;
        }

        if ($msg->type eq 'EVENT') {
            $self->_handle_event($conn_id, $msg->event);
        } elsif ($msg->type eq 'CLOSE') {
            $self->_handle_close($conn_id, $msg->subscription_id);
        } elsif ($msg->type eq 'AUTH') {
            $self->_handle_auth($conn_id, $msg->event);
        }
    });

    $conn->on(finish => sub {
        $self->_remove_all_sub_indexes($conn_id);
        delete $self->_connections->{$conn_id};
        delete $self->_subscriptions->{$conn_id};
        delete $self->_challenges->{$conn_id};
        delete $self->_authenticated->{$conn_id};
        delete $self->_rate_state->{$conn_id};
        delete $self->_idle_timers->{$conn_id};
        delete $self->{_reset_idle}{$conn_id} if $self->{_reset_idle};
        delete $self->_neg_sessions->{$conn_id};
        $self->_conn_count_by_ip->{$peer_host}-- if defined $peer_host;
    });
}

sub _relay_host_matches {
    my ($expected, $got) = @_;
    my $host_re = qr{ ( \[ [^\]]+ \] | [^:/]+ ) }x;
    my ($es, $eh, $ep, $epath) = $expected =~ m{^(wss?)://$host_re(?::(\d+))?(/.*)?\z}i;
    my ($gs, $gh, $gp, $gpath) = $got      =~ m{^(wss?)://$host_re(?::(\d+))?(/.*)?\z}i;
    return 0 unless defined $es && defined $gs;
    return 0 unless lc($es) eq lc($gs);
    return 0 unless lc($eh) eq lc($gh);
    my %defaults = (wss => 443, ws => 80);
    $ep //= $defaults{lc $es};
    $gp //= $defaults{lc $gs};
    return 0 unless $ep == $gp;
    $epath = '/' unless defined $epath && length $epath;
    $gpath = '/' unless defined $gpath && length $gpath;
    return $epath eq $gpath;
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

sub _check_rate_limit {
    my ($self, $conn_id) = @_;
    return 1 unless defined $self->event_rate_limit;
    my $state = $self->_rate_state->{$conn_id} or return 1;

    my $now = time();
    my $elapsed = $now - $state->{last_refill};
    if ($elapsed >= $state->{refill_seconds}) {
        $state->{tokens} = $state->{max_tokens};
        $state->{last_refill} = $now;
    }

    if ($state->{tokens} > 0) {
        $state->{tokens}--;
        return 1;
    }
    return 0;
}

sub _handle_event {
    my ($self, $conn_id, $event) = @_;
    my $conn = $self->_connections->{$conn_id};

    my $error = $self->_validate_event($event);
    if ($error) {
        $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => ($event->id // ''), accepted => 0, message => $error)->serialize);
        return;
    }

    # Content length limit
    if (defined $self->max_content_length && length($event->content) > $self->max_content_length) {
        $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 0, message => 'invalid: content too long')->serialize);
        return;
    }

    # Tag count limit
    if (defined $self->max_event_tags && scalar(@{$event->_tags}) > $self->max_event_tags) {
        $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 0, message => 'invalid: too many tags')->serialize);
        return;
    }

    # created_at lower bound (reject events too far in the past)
    if (defined $self->created_at_lower_limit) {
        if ($event->created_at < time() - $self->created_at_lower_limit) {
            $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 0, message => 'invalid: event too old')->serialize);
            return;
        }
    }

    # created_at upper bound (reject events too far in the future)
    if (defined $self->created_at_upper_limit) {
        if ($event->created_at > time() + $self->created_at_upper_limit) {
            $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 0, message => 'invalid: event too far in the future')->serialize);
            return;
        }
    }

    # Policy callback
    if ($self->on_event) {
        my ($ok, $msg) = $self->on_event->($event);
        unless ($ok) {
            $msg = 'blocked: rejected by policy' unless defined $msg && length $msg;
            $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 0, message => $msg)->serialize);
            return;
        }
    }

    # Rate limiting check
    unless ($self->_check_rate_limit($conn_id)) {
        $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 0, message => 'rate-limited: slow down')->serialize);
        return;
    }

    # NIP-13: Proof of Work check
    if (defined $self->min_pow_difficulty) {
        my $min = $self->min_pow_difficulty;
        my $committed = $event->committed_target_difficulty;
        if (!defined $committed || $committed < $min) {
            $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 0, message => "pow: difficulty commitment below required $min")->serialize);
            return;
        }
        if ($event->difficulty < $min) {
            $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 0, message => "pow: insufficient proof of work (need $min bits)")->serialize);
            return;
        }
    }

    # NIP-40: Relays SHOULD drop expired events on publish
    # (expiration does not affect ephemeral events)
    if ($event->is_expired && !$event->is_ephemeral) {
        $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 0, message => 'invalid: event has expired')->serialize);
        return;
    }

    # NIP-70: default behavior MUST reject events with ["-"] tag
    if ($event->is_protected) {
        my $authed = $self->_authenticated->{$conn_id} || {};
        unless ($authed->{$event->pubkey}) {
            $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 0, message => 'auth-required: this event may only be published by its author')->serialize);
            return;
        }
    }

    # Relays MUST exclude kind 22242 events from being broadcasted (NIP-42)
    if ($event->kind == 22242) {
        $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 0, message => 'invalid: auth events should use AUTH message')->serialize);
        return;
    }

    # duplicate detection
    if ($self->store->get_by_id($event->id)) {
        $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 1, message => 'duplicate: already have this event')->serialize);
        return;
    }

    # ephemeral events: broadcast but don't store
    if ($event->is_ephemeral) {
        $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 1, message => '')->serialize);
        $self->broadcast($event);
        return;
    }

    # replaceable events: keep only latest per pubkey+kind
    if ($event->is_replaceable) {
        my $existing = $self->store->find_replaceable($event->pubkey, $event->kind);
        if ($existing) {
            if (_is_newer($event, $existing)) {
                $self->store->delete_by_id($existing->id);
            } else {
                $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 1, message => 'duplicate: have a newer version')->serialize);
                return;
            }
        }
    }

    # addressable events: keep only latest per pubkey+kind+d_tag
    if ($event->is_addressable) {
        my $existing = $self->store->find_addressable($event->pubkey, $event->kind, $event->d_tag);
        if ($existing) {
            if (_is_newer($event, $existing)) {
                $self->store->delete_by_id($existing->id);
            } else {
                $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 1, message => 'duplicate: have a newer version')->serialize);
                return;
            }
        }
    }

    # deletion requests: remove matching events, but not other kind 5 events
    if ($event->kind == 5) {
        $self->_handle_deletion($event);
    }

    $self->store->store($event);
    $conn->send(Net::Nostr::Message->new(type => 'OK', event_id => $event->id, accepted => 1, message => '')->serialize);
    $self->broadcast($event);
}

sub _handle_deletion {
    my ($self, $del_event) = @_;
    my $del = Net::Nostr::Deletion->from_event($del_event);
    $self->store->delete_matching(
        $del_event->pubkey,
        $del->event_ids,
        $del->addresses,
        $del_event->created_at,
    );
}

sub _handle_auth {
    my ($self, $conn_id, $event) = @_;
    my $conn = $self->_connections->{$conn_id};

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
        for my $tag (@{$event->_tags}) {
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
    for my $tag (@{$event->_tags}) {
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
    my $conn = $self->_connections->{$conn_id};

    # Max filters per REQ
    if (defined $self->max_filters && @filters > $self->max_filters) {
        $conn->send(Net::Nostr::Message->new(
            type => 'CLOSED', subscription_id => $sub_id,
            message => "error: too many filters",
        )->serialize);
        return;
    }

    # Max subscriptions per connection (new subs only, replacing is free)
    if (defined $self->max_subscriptions) {
        my $existing = $self->_subscriptions->{$conn_id} // {};
        if (!exists $existing->{$sub_id}
            && scalar(keys %$existing) >= $self->max_subscriptions) {
            $conn->send(Net::Nostr::Message->new(
                type => 'CLOSED', subscription_id => $sub_id,
                message => "error: too many subscriptions",
            )->serialize);
            return;
        }
    }

    # Cap filter limits
    for my $f (@filters) {
        if (defined $self->default_limit && !defined $f->limit) {
            $f->limit($self->default_limit);
        }
        if (defined $self->max_limit) {
            if (!defined $f->limit || $f->limit > $self->max_limit) {
                $f->limit($self->max_limit);
            }
        }
    }

    $self->_subscriptions->{$conn_id} //= {};
    # Remove old index entries if replacing an existing subscription
    my $old_filters = $self->_subscriptions->{$conn_id}{$sub_id};
    $self->_remove_from_sub_index($conn_id, $sub_id, $old_filters) if $old_filters;
    $self->_subscriptions->{$conn_id}{$sub_id} = \@filters;
    $self->_add_to_sub_index($conn_id, $sub_id, \@filters);

    my $results = $self->store->query(\@filters);

    for my $event (@$results) {
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', subscription_id => $sub_id, event => $event)->serialize);
    }

    $conn->send(Net::Nostr::Message->new(type => 'EOSE', subscription_id => $sub_id)->serialize);
}

sub _handle_count {
    my ($self, $conn_id, $sub_id, @filters) = @_;
    my $conn = $self->_connections->{$conn_id};

    if (defined $self->max_filters && @filters > $self->max_filters) {
        $conn->send(Net::Nostr::Message->new(
            type => 'CLOSED', subscription_id => $sub_id,
            message => "error: too many filters",
        )->serialize);
        return;
    }

    my $count = $self->store->count(\@filters);

    $conn->send(Net::Nostr::Message->new(
        type => 'COUNT', subscription_id => $sub_id, count => $count,
    )->serialize);
}

sub _handle_close {
    my ($self, $conn_id, $sub_id) = @_;
    if ($self->_subscriptions->{$conn_id}) {
        my $filters = $self->_subscriptions->{$conn_id}{$sub_id};
        $self->_remove_from_sub_index($conn_id, $sub_id, $filters) if $filters;
        delete $self->_subscriptions->{$conn_id}{$sub_id};
    }
}

sub _handle_neg_open {
    my ($self, $conn_id, $msg) = @_;
    my $conn = $self->_connections->{$conn_id};
    my $sub_id = $msg->subscription_id;

    # Per spec: if NEG-OPEN is issued for a currently open subscription ID,
    # the existing subscription is first closed.
    delete $self->_neg_sessions->{$conn_id}{$sub_id};

    # Build server-side Negentropy from ALL matching events.
    # Negentropy requires the complete set, so strip any limit from the filter.
    my $filter_hash = $msg->filter->to_hash;
    delete $filter_hash->{limit};
    my $unlimited_filter = Net::Nostr::Filter->new(%$filter_hash);

    my $ne = Net::Nostr::Negentropy->new;
    my $events = $self->store->query([$unlimited_filter]);
    for my $ev (@$events) {
        $ne->add_item($ev->created_at, $ev->id);
    }
    $ne->seal;

    my ($response, $have, $need) = eval { $ne->reconcile($msg->neg_msg) };
    if ($@) {
        my $reason = $@;
        $reason =~ s/\n\z//;
        $conn->send(Net::Nostr::Message->new(
            type => 'NEG-ERR', subscription_id => $sub_id,
            message => "error: $reason",
        )->serialize);
        return;
    }

    if (defined $response) {
        $self->_neg_sessions->{$conn_id}{$sub_id} = $ne;
        $conn->send(Net::Nostr::Message->new(
            type => 'NEG-MSG', subscription_id => $sub_id,
            neg_msg => $response,
        )->serialize);
    } else {
        # Protocol complete in one round — send empty NEG-MSG
        # (response is undef when all ranges match)
        $conn->send(Net::Nostr::Message->new(
            type => 'NEG-MSG', subscription_id => $sub_id,
            neg_msg => $response // _empty_neg_msg(),
        )->serialize);
    }
}

sub _handle_neg_msg {
    my ($self, $conn_id, $msg) = @_;
    my $conn = $self->_connections->{$conn_id};
    my $sub_id = $msg->subscription_id;

    my $ne = $self->_neg_sessions->{$conn_id}{$sub_id};
    unless ($ne) {
        $conn->send(Net::Nostr::Message->new(
            type => 'NEG-ERR', subscription_id => $sub_id,
            message => "closed: no open negentropy session",
        )->serialize);
        return;
    }

    my ($response, $have, $need) = eval { $ne->reconcile($msg->neg_msg) };
    if ($@) {
        my $reason = $@;
        $reason =~ s/\n\z//;
        delete $self->_neg_sessions->{$conn_id}{$sub_id};
        $conn->send(Net::Nostr::Message->new(
            type => 'NEG-ERR', subscription_id => $sub_id,
            message => "error: $reason",
        )->serialize);
        return;
    }

    if (defined $response) {
        $conn->send(Net::Nostr::Message->new(
            type => 'NEG-MSG', subscription_id => $sub_id,
            neg_msg => $response,
        )->serialize);
    } else {
        delete $self->_neg_sessions->{$conn_id}{$sub_id};
    }
}

sub _handle_neg_close {
    my ($self, $conn_id, $sub_id) = @_;
    delete $self->_neg_sessions->{$conn_id}{$sub_id}
        if $self->_neg_sessions->{$conn_id};
}

# Minimal valid negentropy message: version byte + no ranges (all skip)
sub _empty_neg_msg {
    return '61';
}

sub _add_to_sub_index {
    my ($self, $conn_id, $sub_id, $filters) = @_;
    my $key = "$conn_id\0$sub_id";
    my $entry = [$conn_id, $sub_id];
    my $all_have_kinds = 1;
    for my $f (@$filters) {
        if ($f->kinds) {
            for my $k (@{$f->kinds}) {
                $self->_sub_by_kind->{$k}{$key} = $entry;
            }
        } else {
            $all_have_kinds = 0;
        }
    }
    unless ($all_have_kinds) {
        $self->_sub_no_kind->{$key} = $entry;
    }
}

sub _remove_from_sub_index {
    my ($self, $conn_id, $sub_id, $filters) = @_;
    my $key = "$conn_id\0$sub_id";
    if ($filters) {
        for my $f (@$filters) {
            if ($f->kinds) {
                for my $k (@{$f->kinds}) {
                    delete $self->_sub_by_kind->{$k}{$key};
                }
            }
        }
    }
    delete $self->_sub_no_kind->{$key};
}

sub _remove_all_sub_indexes {
    my ($self, $conn_id) = @_;
    my $conn_subs = $self->_subscriptions->{$conn_id} || {};
    for my $sub_id (keys %$conn_subs) {
        $self->_remove_from_sub_index($conn_id, $sub_id, $conn_subs->{$sub_id});
    }
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

An in-process Nostr relay. Accepts WebSocket connections, stores events
using an indexed in-memory backend (or a pluggable custom store), manages
subscriptions, and broadcasts new events to matching subscribers. Supports
configurable event capacity with oldest-first eviction and per-connection rate
limiting. Events do not persist across restarts unless a persistent storage
backend is provided.

Implements:

=over 4

=item * L<NIP-01|https://github.com/nostr-protocol/nips/blob/master/01.md> - Basic protocol flow

=item * L<NIP-09|https://github.com/nostr-protocol/nips/blob/master/09.md> - Event deletion requests

=item * L<NIP-11|https://github.com/nostr-protocol/nips/blob/master/11.md> - Relay information document

=item * L<NIP-13|https://github.com/nostr-protocol/nips/blob/master/13.md> - Proof of Work

=item * L<NIP-40|https://github.com/nostr-protocol/nips/blob/master/40.md> - Expiration timestamp

=item * L<NIP-42|https://github.com/nostr-protocol/nips/blob/master/42.md> - Authentication of clients to relays

=item * L<NIP-45|https://github.com/nostr-protocol/nips/blob/master/45.md> - Event counts (HyperLogLog not supported)

=item * L<NIP-70|https://github.com/nostr-protocol/nips/blob/master/70.md> - Protected events

=item * L<NIP-77|https://github.com/nostr-protocol/nips/blob/master/77.md> - Negentropy syncing

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
    my $relay = Net::Nostr::Relay->new(relay_info => $info);
    my $relay = Net::Nostr::Relay->new(min_pow_difficulty => 16);
    my $relay = Net::Nostr::Relay->new(max_events => 10000);
    my $relay = Net::Nostr::Relay->new(event_rate_limit => '10/60');
    my $relay = Net::Nostr::Relay->new(store => $custom_store);

Creates a new relay instance. Options:

=over 4

=item C<verify_signatures> - Enable Schnorr signature verification (default: true).
Pass C<0> to disable (useful for testing with synthetic events).

=item C<max_connections_per_ip> - Maximum simultaneous WebSocket connections
allowed from a single IP address. Connections beyond this limit are rejected
at the TCP level. Default: C<undef> (unlimited).

=item C<relay_url> - The relay's own WebSocket URL (e.g. C<wss://relay.example.com/>).
When set, NIP-42 AUTH events are validated to ensure the C<relay> tag matches
this URL. Comparison normalizes scheme and host case, default ports (80 for
C<ws>, 443 for C<wss>), and treats a missing path as C</>. Bracketed IPv6
addresses (e.g. C<ws://[::1]:8080>) are supported.
Default: C<undef> (relay tag not validated).

=item C<min_pow_difficulty> - Minimum Proof of Work difficulty required for
events (NIP-13). Events must have a C<nonce> tag committing to at least this
difficulty, and the event ID must have at least this many leading zero bits.
Events without a difficulty commitment are also rejected. Default: C<undef>
(no PoW required).

    my $relay = Net::Nostr::Relay->new(min_pow_difficulty => 16);

=item C<relay_info> - A L<Net::Nostr::RelayInfo> object (NIP-11). When set, the
relay serves the information document in response to HTTP requests with
C<Accept: application/nostr+json>, and handles CORS preflight OPTIONS requests.
Default: C<undef> (NIP-11 disabled).

    use Net::Nostr::RelayInfo;

    my $relay = Net::Nostr::Relay->new(
        relay_info => Net::Nostr::RelayInfo->new(
            name           => 'My Relay',
            supported_nips => [1, 9, 11, 42],
            version        => '1.0.0',
        ),
    );

=item C<store> - A pluggable storage backend object. Must implement the same
interface as L<Net::Nostr::RelayStore> (duck-typed). When provided,
C<max_events> is ignored (configure it on the store directly). Default: a new
L<Net::Nostr::RelayStore> instance.

    use Net::Nostr::RelayStore;

    my $store = Net::Nostr::RelayStore->new(max_events => 5000);
    my $relay = Net::Nostr::Relay->new(store => $store);

=item C<max_events> - Maximum number of events to retain in the default
in-memory store. Oldest events are evicted when the limit is exceeded.
Must be a positive integer. Default: C<undef> (unlimited). Ignored when
a custom C<store> is provided.

    my $relay = Net::Nostr::Relay->new(max_events => 10000);

=item C<event_rate_limit> - Per-connection event submission rate limit in
the format C<"count/seconds"> (e.g. C<"10/60"> for 10 events per 60 seconds).
Uses a token bucket: each connection starts with C<count> tokens, one token
is consumed per event, and all tokens are refilled when C<seconds> have
elapsed since the last refill. When no tokens remain, events are rejected
with an C<OK false> response and a C<rate-limited:> prefix. Default:
C<undef> (unlimited). Croaks if the format is invalid.

    my $relay = Net::Nostr::Relay->new(event_rate_limit => '10/60');

=item C<max_subscriptions> - Maximum number of active subscriptions per
connection. When a client sends a REQ that would exceed this limit, the
relay responds with a CLOSED message. Replacing an existing subscription
(same ID) does not count toward the limit. Must be a positive integer.
Default: C<undef> (unlimited).

    my $relay = Net::Nostr::Relay->new(max_subscriptions => 20);

=item C<max_filters> - Maximum number of filters allowed in a single REQ
or COUNT message. Requests exceeding this limit are rejected with a CLOSED
message. Must be a positive integer. Default: C<undef> (unlimited).

    my $relay = Net::Nostr::Relay->new(max_filters => 10);

=item C<max_content_length> - Maximum length (in bytes) of the C<content>
field in an event. Events exceeding this limit are rejected with C<OK false>
and an C<invalid:> prefix. Must be a positive integer. Default: C<undef>
(unlimited).

    my $relay = Net::Nostr::Relay->new(max_content_length => 8196);

=item C<max_event_tags> - Maximum number of tags allowed on an event. Events
exceeding this limit are rejected with C<OK false> and an C<invalid:> prefix.
Must be a positive integer. Default: C<undef> (unlimited).

    my $relay = Net::Nostr::Relay->new(max_event_tags => 2000);

=item C<max_limit> - Server-side cap on the C<limit> field in filters.
If a client requests a higher limit (or no limit), it is silently capped
to this value. Applies to both REQ and COUNT queries. Must be a positive
integer. Default: C<undef> (no cap).

    my $relay = Net::Nostr::Relay->new(max_limit => 500);

=item C<default_limit> - Default C<limit> applied to filters that do not
specify one. Without this, a filter with no limit returns all matching
events. Must be a positive integer. Default: C<undef> (no default limit).

    my $relay = Net::Nostr::Relay->new(default_limit => 100);

=item C<created_at_lower_limit> - Maximum age (in seconds) for events.
Events with C<created_at> older than C<now - created_at_lower_limit> are
rejected with C<OK false>. Matches the NIP-11 C<limitation> field of the
same name. Must be a positive integer. Default: C<undef> (no lower bound).

    # Reject events older than 1 year
    my $relay = Net::Nostr::Relay->new(created_at_lower_limit => 31536000);

=item C<created_at_upper_limit> - Maximum seconds into the future for events.
Events with C<created_at> more than this many seconds ahead of the current
time are rejected with C<OK false>. Matches the NIP-11 C<limitation> field
of the same name. Must be a positive integer. Default: C<undef> (no upper
bound).

    # Reject events more than 15 minutes in the future
    my $relay = Net::Nostr::Relay->new(created_at_upper_limit => 900);

=item C<max_message_length> - Maximum incoming WebSocket message size in
bytes. Messages exceeding this limit are dropped and a NOTICE is sent to
the client. This is an application-level check; for frame-level protection,
configure your reverse proxy. Must be a positive integer. Default: C<undef>
(unlimited).

    my $relay = Net::Nostr::Relay->new(max_message_length => 65536);

=item C<on_event> - A code reference called for each incoming event after
structural validation but before storage and broadcast. Receives the
L<Net::Nostr::Event> object as its sole argument. Must return a two-element
list C<($accepted, $message)>. If C<$accepted> is false, the event is
rejected with C<OK false> and the given message (or a default if empty).

    my $relay = Net::Nostr::Relay->new(
        on_event => sub {
            my ($event) = @_;
            return (0, 'blocked: spam') if $event->content =~ /spam/;
            return (1, '');
        },
    );

=item C<idle_timeout> - Seconds of client inactivity before the relay
disconnects the connection. The timer resets each time the client sends
a message. Must be a positive integer. Default: C<undef> (no timeout).

    # Disconnect clients idle for more than 5 minutes
    my $relay = Net::Nostr::Relay->new(idle_timeout => 300);

=item C<shutdown_timeout> - Seconds to wait after sending a shutdown NOTICE
before closing connections during L</graceful_stop>. Must be a positive
integer. Default: C<undef> (5 seconds when C<graceful_stop> is called).

    my $relay = Net::Nostr::Relay->new(shutdown_timeout => 10);

Croaks on unknown arguments.

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

=head2 graceful_stop

    $relay->graceful_stop;

Initiates a graceful shutdown. Stops accepting new connections immediately,
sends a C<NOTICE> ("shutting down") to all connected clients, then closes
all connections after C<shutdown_timeout> seconds (default: 5). This gives
clients time to reconnect to another relay.

    my $relay = Net::Nostr::Relay->new(shutdown_timeout => 10);
    $relay->start('0.0.0.0', 8080);
    # ... later ...
    $relay->graceful_stop;  # NOTICE sent, connections close after 10s

=head2 broadcast

    $relay->broadcast($event);

Sends the event to all connected clients whose subscriptions match.
Normally called internally when a new event is accepted. Does not store
the event -- use L</inject_event> for storing without broadcasting, or
publish via the normal EVENT protocol flow for both.

=head2 connections

    my $conns = $relay->connections;  # hashref (snapshot)

Returns a shallow copy of the active connections hash. Mutating the
returned hashref does not affect the relay's internal state. Keys are
connection IDs, values are L<AnyEvent::WebSocket::Connection> objects.

=head2 subscriptions

    my $subs = $relay->subscriptions;  # hashref (snapshot)

Returns a two-level copy of the active subscriptions hash. Mutating
the returned hashref (or its inner hashes) does not affect the relay's
internal state. Keys are connection IDs, inner keys are subscription
IDs, values are arrayrefs of L<Net::Nostr::Filter> objects.

=head2 store

    my $store = $relay->store;

Returns the storage backend object (L<Net::Nostr::RelayStore> by default).

=head2 events

    my $events = $relay->events;  # arrayref of Net::Nostr::Event

Returns a snapshot (array copy) of stored events, sorted by C<created_at>
DESC then C<id> ASC. Mutating the returned arrayref does not affect the
store. Reflects replaceable/addressable semantics (only the latest version
of each replaceable or addressable event is retained). Ephemeral events
are never stored.

Can also be used as a setter for backward compatibility. The setter clears
the store and re-stores each event individually (duplicates are silently
skipped, and C<max_events> eviction applies):

    $relay->events([]);                   # clear all events
    $relay->events([$event1, $event2]);   # replace with given events

=head2 inject_event

    my $ok = $relay->inject_event($event);

Stores an event directly into the store without validation or broadcasting.
Returns 1 on success, 0 if the event is a duplicate. Useful for tests and
programmatic seeding of relay state.

    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->inject_event($event);  # 1
    $relay->inject_event($event);  # 0 (duplicate)

=head2 max_events

    my $max = $relay->max_events;

Returns the configured maximum event capacity, or C<undef> if unlimited
(the default). This value is passed to the default store on construction.

=head2 event_rate_limit

    my $limit = $relay->event_rate_limit;  # e.g. '10/60' or undef

Returns the per-connection event rate limit string, or C<undef> if
unlimited (the default). See L</new> for token bucket semantics.

    my $relay = Net::Nostr::Relay->new(event_rate_limit => '10/60');

=head2 verify_signatures

    my $bool = $relay->verify_signatures;

Returns whether Schnorr signature verification is enabled (default: true).

=head2 max_connections_per_ip

    my $limit = $relay->max_connections_per_ip;

Returns the maximum number of simultaneous connections allowed per IP
address, or C<undef> if unlimited (the default).

    my $relay = Net::Nostr::Relay->new(max_connections_per_ip => 10);
    $relay->start('0.0.0.0', 8080);

=head2 min_pow_difficulty

    my $min = $relay->min_pow_difficulty;

Returns the minimum Proof of Work difficulty required for events (NIP-13),
or C<undef> if not set (the default).

    my $relay = Net::Nostr::Relay->new(min_pow_difficulty => 16);
    $relay->start('0.0.0.0', 8080);

=head2 relay_url

    my $url = $relay->relay_url;

Returns the relay's own WebSocket URL, or C<undef> if not set.
Used for NIP-42 relay tag validation.

    my $relay = Net::Nostr::Relay->new(relay_url => 'wss://relay.example.com/');
    $relay->start('0.0.0.0', 8080);

=head2 relay_info

    my $info = $relay->relay_info;

Returns the L<Net::Nostr::RelayInfo> object (NIP-11), or C<undef> if not set.

    my $relay = Net::Nostr::Relay->new(
        relay_info => Net::Nostr::RelayInfo->new(name => 'My Relay'),
    );
    $relay->start('0.0.0.0', 8080);

    # Clients can now fetch: curl -H 'Accept: application/nostr+json' http://localhost:8080/

=head2 max_subscriptions

    my $max = $relay->max_subscriptions;

Returns the per-connection subscription limit, or C<undef> if unlimited.

=head2 max_filters

    my $max = $relay->max_filters;

Returns the per-REQ/COUNT filter count limit, or C<undef> if unlimited.

=head2 max_content_length

    my $max = $relay->max_content_length;

Returns the maximum event content length in bytes, or C<undef> if unlimited.

=head2 max_event_tags

    my $max = $relay->max_event_tags;

Returns the maximum event tag count, or C<undef> if unlimited.

=head2 max_limit

    my $max = $relay->max_limit;

Returns the server-side cap on filter C<limit>, or C<undef> if no cap.

=head2 default_limit

    my $default = $relay->default_limit;

Returns the default limit applied to filters without one, or C<undef>.

=head2 created_at_lower_limit

    my $secs = $relay->created_at_lower_limit;

Returns the maximum event age in seconds, or C<undef> if no bound.

=head2 created_at_upper_limit

    my $secs = $relay->created_at_upper_limit;

Returns the maximum seconds-into-future for events, or C<undef> if no bound.

=head2 max_message_length

    my $max = $relay->max_message_length;

Returns the maximum incoming message size in bytes, or C<undef> if unlimited.

=head2 on_event

    my $cb = $relay->on_event;

Returns the event policy callback, or C<undef> if not set.

=head2 idle_timeout

    my $secs = $relay->idle_timeout;

Returns the idle timeout in seconds, or C<undef> if not set.

=head2 shutdown_timeout

    my $secs = $relay->shutdown_timeout;

Returns the graceful shutdown drain period in seconds, or C<undef> if not set.

=head2 authenticated_pubkeys

    my $auth = $relay->authenticated_pubkeys;  # deep snapshot

Returns a deep copy of authenticated pubkeys per connection (NIP-42).
Mutating the returned hashref does not affect the relay's internal state.
Keys are connection IDs, values are hashrefs of pubkey hex strings.

    my $auth = $relay->authenticated_pubkeys;
    for my $conn_id (keys %$auth) {
        for my $pubkey (keys %{$auth->{$conn_id}}) {
            say "Connection $conn_id authenticated as $pubkey";
        }
    }

=head1 SEE ALSO

L<NIP-01|https://github.com/nostr-protocol/nips/blob/master/01.md>,
L<NIP-42|https://github.com/nostr-protocol/nips/blob/master/42.md>,
L<NIP-45|https://github.com/nostr-protocol/nips/blob/master/45.md>,
L<NIP-77|https://github.com/nostr-protocol/nips/blob/master/77.md>,
L<Net::Nostr>, L<Net::Nostr::Client>, L<Net::Nostr::Event>,
L<Net::Nostr::RelayStore>, L<Net::Nostr::RelayInfo>

=cut
