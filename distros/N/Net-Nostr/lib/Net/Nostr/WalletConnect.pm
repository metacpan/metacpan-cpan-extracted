package Net::Nostr::WalletConnect;

use strictures 2;

use Carp qw(croak);
use JSON ();
use Net::Nostr::Event;

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

###############################################################################
# URI parsing/generation
###############################################################################

sub parse_uri {
    my ($class, $uri) = @_;
    croak "URI must use nostr+walletconnect:// protocol"
        unless $uri =~ m{^nostr\+walletconnect://([0-9a-f]{64})\?(.+)$}i;

    my ($wallet_pubkey, $query) = (lc($1), $2);

    my (@relays, $secret, $lud16);
    for my $pair (split /&/, $query) {
        my ($key, $val) = split /=/, $pair, 2;
        $val = _uri_decode($val) if defined $val;
        if ($key eq 'relay')    { push @relays, $val }
        elsif ($key eq 'secret') { $secret = $val }
        elsif ($key eq 'lud16')  { $lud16  = $val }
    }

    croak "URI must contain at least one relay parameter" unless @relays;
    croak "URI must contain a secret parameter" unless defined $secret;
    croak "secret must be 64-char lowercase hex" unless $secret =~ $HEX64;

    return Net::Nostr::WalletConnect::Connection->new(
        wallet_pubkey => $wallet_pubkey,
        relays        => \@relays,
        secret        => $secret,
        lud16         => $lud16,
    );
}

sub create_uri {
    my ($class, %args) = @_;
    croak "wallet_pubkey is required" unless defined $args{wallet_pubkey};
    croak "relay is required"         unless defined $args{relay};
    croak "secret is required"        unless defined $args{secret};
    croak "wallet_pubkey must be 64-char lowercase hex" unless $args{wallet_pubkey} =~ $HEX64;
    croak "secret must be 64-char lowercase hex" unless $args{secret} =~ $HEX64;

    my @relays = ref $args{relay} eq 'ARRAY' ? @{$args{relay}} : ($args{relay});

    my $uri = "nostr+walletconnect://$args{wallet_pubkey}?";
    my @params;
    for my $r (@relays) {
        push @params, "relay=" . _uri_encode($r);
    }
    push @params, "secret=" . _uri_encode($args{secret});
    push @params, "lud16=" . _uri_encode($args{lud16}) if defined $args{lud16};

    return $uri . join('&', @params);
}

###############################################################################
# Info event (kind 13194)
###############################################################################

sub info_event {
    my ($class, %args) = @_;
    my @tags;

    if ($args{encryption} && @{$args{encryption}}) {
        push @tags, ['encryption', join(' ', @{$args{encryption}})];
    }
    if ($args{notifications} && @{$args{notifications}}) {
        push @tags, ['notifications', join(' ', @{$args{notifications}})];
    }

    return Net::Nostr::Event->new(
        kind    => 13194,
        pubkey  => $args{pubkey},
        content => join(' ', @{$args{capabilities} // []}),
        tags    => \@tags,
    );
}

sub parse_info {
    my ($class, $event) = @_;
    croak "info event MUST be kind 13194" unless $event->kind == 13194;

    my @capabilities = split / /, $event->content;
    my (@encryption, @notification_types);

    for my $tag (@{$event->tags}) {
        next unless @$tag >= 2;
        if ($tag->[0] eq 'encryption') {
            @encryption = split / /, $tag->[1];
        } elsif ($tag->[0] eq 'notifications') {
            @notification_types = split / /, $tag->[1];
        }
    }

    # Absence of encryption tag implies nip04
    @encryption = ('nip04') unless @encryption;

    return Net::Nostr::WalletConnect::Info->new(
        capabilities       => \@capabilities,
        encryption         => \@encryption,
        notification_types => \@notification_types,
    );
}

###############################################################################
# Request payload
###############################################################################

sub request {
    my ($class, %args) = @_;
    croak "request requires 'method'" unless defined $args{method};
    croak "request requires 'params'" unless defined $args{params};

    return JSON->new->utf8->canonical->encode({
        method => $args{method},
        params => $args{params},
    });
}

###############################################################################
# Request event (kind 23194)
###############################################################################

sub request_event {
    my ($class, %args) = @_;
    croak "request_event requires 'method'" unless defined $args{method};
    croak "request_event requires 'params'" unless defined $args{params};
    croak "request_event requires 'wallet_pubkey'" unless defined $args{wallet_pubkey};

    my $content = $class->request(method => $args{method}, params => $args{params});

    my @tags;
    push @tags, ['p', $args{wallet_pubkey}];
    push @tags, ['encryption', $args{encryption}] if defined $args{encryption};
    push @tags, ['expiration', '' . $args{expiration}] if defined $args{expiration};

    croak "request_event requires 'pubkey'" unless defined $args{pubkey};
    croak "pubkey must be 64-char lowercase hex" unless $args{pubkey} =~ $HEX64;

    return Net::Nostr::Event->new(
        kind    => 23194,
        pubkey  => $args{pubkey},
        content => $content,
        tags    => \@tags,
    );
}

###############################################################################
# Response payload
###############################################################################

sub parse_response {
    my ($class, $json) = @_;
    my $data = JSON->new->utf8->decode($json);

    return Net::Nostr::WalletConnect::Response->new(
        result_type   => $data->{result_type},
        error         => $data->{error},
        result        => $data->{result},
    );
}

###############################################################################
# Response event (kind 23195)
###############################################################################

sub response_event {
    my ($class, %args) = @_;

    my $content = JSON->new->utf8->canonical->encode({
        result_type => $args{result_type},
        error       => $args{error},
        result      => $args{result},
    });

    my @tags;
    push @tags, ['p', $args{client_pubkey}] if defined $args{client_pubkey};
    push @tags, ['e', $args{request_id}]    if defined $args{request_id};

    croak "response_event requires 'pubkey'" unless defined $args{pubkey};
    croak "pubkey must be 64-char lowercase hex" unless $args{pubkey} =~ $HEX64;

    return Net::Nostr::Event->new(
        kind    => 23195,
        pubkey  => $args{pubkey},
        content => $content,
        tags    => \@tags,
    );
}

###############################################################################
# Notification payload
###############################################################################

sub parse_notification {
    my ($class, $json) = @_;
    my $data = JSON->new->utf8->decode($json);

    return Net::Nostr::WalletConnect::Notification->new(
        notification_type => $data->{notification_type},
        notification      => $data->{notification},
    );
}

###############################################################################
# Notification event (kind 23197)
###############################################################################

sub notification_event {
    my ($class, %args) = @_;

    my $content = JSON->new->utf8->canonical->encode({
        notification_type => $args{notification_type},
        notification      => $args{notification},
    });

    my @tags;
    push @tags, ['p', $args{client_pubkey}] if defined $args{client_pubkey};

    # Kind 23196 for NIP-04 backwards compatibility, 23197 for NIP-44
    my $kind = (defined $args{encryption} && $args{encryption} eq 'nip04') ? 23196 : 23197;

    croak "notification_event requires 'pubkey'" unless defined $args{pubkey};
    croak "pubkey must be 64-char lowercase hex" unless $args{pubkey} =~ $HEX64;

    return Net::Nostr::Event->new(
        kind    => $kind,
        pubkey  => $args{pubkey},
        content => $content,
        tags    => \@tags,
    );
}

###############################################################################
# Metadata validation
###############################################################################

sub validate_metadata {
    my ($class, $metadata) = @_;
    my $json = JSON->new->utf8->canonical->encode($metadata);
    croak "metadata MUST be no more than 4096 characters (got " . length($json) . ")"
        if length($json) > 4096;
    return 1;
}

###############################################################################
# Event validation
###############################################################################

sub validate_request {
    my ($class, $event) = @_;
    croak "request MUST be kind 23194" unless $event->kind == 23194;

    my $has_p = grep { $_->[0] eq 'p' } @{$event->tags};
    croak "request SHOULD include a p tag" unless $has_p;

    return 1;
}

sub validate_response {
    my ($class, $event) = @_;
    croak "response MUST be kind 23195" unless $event->kind == 23195;
    return 1;
}

sub is_expired {
    my ($class, $event) = @_;
    for my $tag (@{$event->tags}) {
        if (@$tag >= 2 && $tag->[0] eq 'expiration') {
            return time() >= $tag->[1];
        }
    }
    return 0;
}

###############################################################################
# URI helpers
###############################################################################

sub _uri_encode {
    my ($str) = @_;
    $str =~ s/([^A-Za-z0-9\-_.~])/sprintf("%%%02X", ord($1))/ge;
    return $str;
}

sub _uri_decode {
    my ($str) = @_;
    $str =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
    return $str;
}

###############################################################################
# Inner classes
###############################################################################

{
    package Net::Nostr::WalletConnect::Connection;
    use Carp qw(croak);
    use Class::Tiny qw(wallet_pubkey secret lud16);
    sub new {
        my $class = shift;
        my $self = bless { @_ }, $class;
        my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
        $known{relays} = ();
        my @unknown = grep { !exists $known{$_} } keys %$self;
        croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
        $self->{relays} = [@{$self->{relays}}] if ref $self->{relays} eq 'ARRAY';
        return $self;
    }
    sub relays {
        my $self = shift;
        croak "relays is read-only" if @_;
        return defined $self->{relays} ? [@{$self->{relays}}] : undef;
    }
}

{
    package Net::Nostr::WalletConnect::Info;
    use Carp qw(croak);
    my @_ARRAY_FIELDS = qw(capabilities encryption notification_types);
    use Class::Tiny ();
    sub new {
        my $class = shift;
        my $self = bless { @_ }, $class;
        my %known = map { $_ => 1 } @_ARRAY_FIELDS;
        my @unknown = grep { !exists $known{$_} } keys %$self;
        croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
        for my $f (@_ARRAY_FIELDS) {
            $self->{$f} = [@{$self->{$f}}] if ref $self->{$f} eq 'ARRAY';
        }
        return $self;
    }
    for my $f (@_ARRAY_FIELDS) {
        no strict 'refs';
        *$f = sub {
            my $self = shift;
            croak "$f is read-only" if @_;
            return defined $self->{$f} ? [@{$self->{$f}}] : undef;
        };
    }

    sub supports_capability {
        my ($self, $cap) = @_;
        return scalar grep { $_ eq $cap } @{$self->{capabilities}};
    }

    sub supports_encryption {
        my ($self, $enc) = @_;
        return scalar grep { $_ eq $enc } @{$self->{encryption}};
    }

    sub preferred_encryption {
        my ($self) = @_;
        return 'nip44_v2' if $self->supports_encryption('nip44_v2');
        return $self->{encryption}[0];
    }
}

{
    package Net::Nostr::WalletConnect::Response;
    use Carp qw(croak);
    use Class::Tiny qw(result_type error result);
    sub new {
        my $class = shift;
        my $self = bless { @_ }, $class;
        my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
        my @unknown = grep { !exists $known{$_} } keys %$self;
        croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
        croak "result_type is required" unless defined $self->{result_type};
        return $self;
    }

    sub is_error {
        my ($self) = @_;
        return defined $self->error && ref $self->error eq 'HASH';
    }

    sub error_code {
        my ($self) = @_;
        return $self->is_error ? $self->error->{code} : undef;
    }

    sub error_message {
        my ($self) = @_;
        return $self->is_error ? $self->error->{message} : undef;
    }
}

{
    package Net::Nostr::WalletConnect::Notification;
    use Carp qw(croak);
    use Class::Tiny qw(notification_type notification);
    sub new {
        my $class = shift;
        my $self = bless { @_ }, $class;
        my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
        my @unknown = grep { !exists $known{$_} } keys %$self;
        croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
        croak "notification_type is required" unless defined $self->{notification_type};
        croak "notification is required" unless defined $self->{notification};
        return $self;
    }
}

1;

__END__

=head1 NAME

Net::Nostr::WalletConnect - NIP-47 Nostr Wallet Connect

=head1 SYNOPSIS

    use Net::Nostr::WalletConnect;

    # Parse a connection URI
    my $conn = Net::Nostr::WalletConnect->parse_uri(
        'nostr+walletconnect://b889ff5b...?relay=wss%3A%2F%2Frelay.damus.io&secret=71a8c14c...'
    );
    say $conn->wallet_pubkey;
    say $conn->secret;
    say $conn->relays->[0];

    # Create a connection URI
    my $uri = Net::Nostr::WalletConnect->create_uri(
        wallet_pubkey => $pubkey,
        relay         => 'wss://relay.damus.io',
        secret        => $secret,
        lud16         => 'alice@example.com',
    );

    # Parse wallet service info event
    my $info = Net::Nostr::WalletConnect->parse_info($info_event);
    say join ', ', @{$info->capabilities};
    say $info->preferred_encryption;  # 'nip44_v2' or 'nip04'

    # Build a request payload (JSON string, ready for encryption)
    my $payload = Net::Nostr::WalletConnect->request(
        method => 'pay_invoice',
        params => { invoice => 'lnbc50n1...' },
    );

    # Build a request event (kind 23194)
    my $event = Net::Nostr::WalletConnect->request_event(
        method        => 'pay_invoice',
        params        => { invoice => 'lnbc50n1...' },
        pubkey        => $client_pubkey,
        wallet_pubkey => $wallet_pubkey,
        encryption    => 'nip44_v2',
    );

    # Parse a decrypted response
    my $resp = Net::Nostr::WalletConnect->parse_response($decrypted_json);
    if ($resp->is_error) {
        warn $resp->error_code . ': ' . $resp->error_message;
    } else {
        say $resp->result->{preimage};
    }

    # Parse a decrypted notification
    my $notif = Net::Nostr::WalletConnect->parse_notification($decrypted_json);
    say $notif->notification_type;  # 'payment_received'
    say $notif->notification->{amount};

=head1 DESCRIPTION

Implements NIP-47 Nostr Wallet Connect (NWC), a protocol for clients to
interact with a remote lightning wallet through encrypted nostr messages.
Communication happens via E2E-encrypted direct messages over nostr relays
using dedicated ephemeral keys.

The protocol uses four event kinds:

=over 4

=item * B<Info event> (kind 13194) - Published by the wallet service to
indicate supported capabilities.

=item * B<Request> (kind 23194) - Sent by the client to the wallet service.

=item * B<Response> (kind 23195) - Sent by the wallet service back to the
client.

=item * B<Notification> (kind 23197, or 23196 for NIP-04 backwards
compatibility) - Push notifications from the wallet service to the client.

=back

Encryption of the content field is handled separately using
L<NIP-44|https://github.com/nostr-protocol/nips/blob/master/44.md>
(preferred) or NIP-04 (deprecated, for backwards compatibility). This module
handles the payload structure and event creation; the caller is responsible
for encrypting/decrypting the content.

Supported commands: C<pay_invoice>, C<pay_keysend>, C<make_invoice>,
C<lookup_invoice>, C<list_transactions>, C<get_balance>, C<get_info>,
C<make_hold_invoice>, C<cancel_hold_invoice>, C<settle_hold_invoice>.

=head1 CLASS METHODS

=head2 parse_uri

    my $conn = Net::Nostr::WalletConnect->parse_uri($uri_string);

Parses a C<nostr+walletconnect://> connection URI. Returns a
L</Connection> object. The pubkey is lowercased during parsing to
ensure consistency. Croaks if the URI is malformed or missing required
parameters (C<relay>, C<secret>).

=head2 create_uri

    my $uri = Net::Nostr::WalletConnect->create_uri(
        wallet_pubkey => $hex_pubkey,        # required
        relay         => $url_or_arrayref,   # required
        secret        => $hex_secret,        # required
        lud16         => 'user@domain.com',  # optional
    );

Creates a C<nostr+walletconnect://> URI string. The C<relay> parameter
accepts a single URL string or an arrayref of URLs.

=head2 info_event

    my $event = Net::Nostr::WalletConnect->info_event(
        pubkey        => $wallet_pubkey,
        capabilities  => [qw(pay_invoice get_balance)],
        encryption    => [qw(nip44_v2 nip04)],      # optional
        notifications => [qw(payment_received)],     # optional
    );

Creates a kind 13194 info L<Net::Nostr::Event>. The C<capabilities> are
joined as a space-separated string in the content field.

=head2 parse_info

    my $info = Net::Nostr::WalletConnect->parse_info($event);

Parses a kind 13194 info event. Returns an L</Info> object. Croaks if the
event is not kind 13194. If the event has no C<encryption> tag, defaults
to C<['nip04']> per spec.

=head2 request

    my $json = Net::Nostr::WalletConnect->request(
        method => 'pay_invoice',
        params => { invoice => 'lnbc50n1...' },
    );

Builds a JSON-encoded request payload string. This is the content that
should be encrypted before placing in the event. Croaks if C<method> or
C<params> is missing.

=head2 request_event

    my $event = Net::Nostr::WalletConnect->request_event(
        method        => 'pay_invoice',
        params        => { invoice => 'lnbc50n1...' },
        pubkey        => $client_pubkey,
        wallet_pubkey => $wallet_pubkey,
        encryption    => 'nip44_v2',       # optional
        expiration    => $unix_timestamp,  # optional
    );

Creates a kind 23194 request L<Net::Nostr::Event> with the JSON payload
as unencrypted content (the caller should encrypt before publishing).
Includes a C<p> tag with the wallet service pubkey, and optionally
C<encryption> and C<expiration> tags. Croaks if C<pubkey> is missing or
not 64-char lowercase hex.

=head2 parse_response

    my $resp = Net::Nostr::WalletConnect->parse_response($json);

Parses a decrypted JSON response payload. Returns a L</Response> object.
Croaks if C<result_type> is missing.

=head2 response_event

    my $event = Net::Nostr::WalletConnect->response_event(
        result_type   => 'pay_invoice',
        result        => { preimage => '...' },  # or undef on error
        error         => undef,                   # or { code => '...', message => '...' }
        pubkey        => $wallet_pubkey,
        client_pubkey => $client_pubkey,
        request_id    => $request_event_id,
    );

Creates a kind 23195 response L<Net::Nostr::Event> with C<p> and C<e> tags.
Croaks if C<pubkey> is missing or not 64-char lowercase hex.

=head2 parse_notification

    my $notif = Net::Nostr::WalletConnect->parse_notification($json);

Parses a decrypted JSON notification payload. Returns a L</Notification>
object. Croaks if C<notification_type> or C<notification> is missing.

=head2 notification_event

    my $event = Net::Nostr::WalletConnect->notification_event(
        notification_type => 'payment_received',
        notification      => { type => 'incoming', amount => 50000 },
        pubkey            => $wallet_pubkey,
        client_pubkey     => $client_pubkey,
        encryption        => 'nip44_v2',  # or 'nip04' for kind 23196
    );

Creates a notification L<Net::Nostr::Event> with a C<p> tag. Uses kind 23197
by default (NIP-44 encryption). Pass C<< encryption => 'nip04' >> to create
a kind 23196 event for NIP-04 backwards compatibility. Wallet services
supporting both should publish both kinds for each notification. Croaks if
C<pubkey> is missing or not 64-char lowercase hex.

=head2 validate_metadata

    Net::Nostr::WalletConnect->validate_metadata($hashref);

Validates that metadata does not exceed 4096 characters when JSON-encoded.
Returns true on success, croaks on failure.

=head2 validate_request

    Net::Nostr::WalletConnect->validate_request($event);

Validates that a request event is kind 23194 and has a C<p> tag. Croaks
on failure.

=head2 validate_response

    Net::Nostr::WalletConnect->validate_response($event);

Validates that a response event is kind 23195. Croaks on failure.

=head2 is_expired

    my $bool = Net::Nostr::WalletConnect->is_expired($event);

Returns true if the event has an C<expiration> tag with a timestamp in the
past.

=head1 OBJECTS

=head2 Connection

Returned by L</parse_uri>. Croaks on unknown arguments.

=over 4

=item C<wallet_pubkey> - 32-byte hex public key of the wallet service

=item C<relays> - Arrayref of relay URLs

=item C<secret> - 32-byte hex secret for the client

=item C<lud16> - Lightning address (optional)

=back

=head2 Info

Returned by L</parse_info>. Croaks on unknown arguments.

=over 4

=item C<capabilities> - Arrayref of supported command names

=item C<encryption> - Arrayref of supported encryption schemes

=item C<notification_types> - Arrayref of supported notification types

=item C<supports_capability($name)> - Returns true if the capability is supported

=item C<supports_encryption($scheme)> - Returns true if the encryption scheme is supported

=item C<preferred_encryption> - Returns C<'nip44_v2'> if supported, otherwise the first available scheme

=back

=head2 Response

Returned by L</parse_response>. Croaks on unknown arguments or missing
C<result_type>.

=over 4

=item C<result_type> - The method name this response corresponds to

=item C<result> - Hashref with result data, or undef on error

=item C<error> - Hashref with C<code> and C<message>, or undef on success

=item C<is_error> - Returns true if this is an error response

=item C<error_code> - Returns the error code string, or undef

=item C<error_message> - Returns the human-readable error message, or undef

=back

Error codes: C<RATE_LIMITED>, C<NOT_IMPLEMENTED>, C<INSUFFICIENT_BALANCE>,
C<QUOTA_EXCEEDED>, C<RESTRICTED>, C<UNAUTHORIZED>, C<INTERNAL>,
C<UNSUPPORTED_ENCRYPTION>, C<OTHER>, C<PAYMENT_FAILED>, C<NOT_FOUND>.

=head2 Notification

Returned by L</parse_notification>. Croaks on unknown arguments or missing
required fields (C<notification_type>, C<notification>).

=over 4

=item C<notification_type> - C<'payment_received'>, C<'payment_sent'>, or C<'hold_invoice_accepted'>

=item C<notification> - Hashref with notification data

=back

=head1 SEE ALSO

L<NIP-47|https://github.com/nostr-protocol/nips/blob/master/47.md>,
L<Net::Nostr>, L<Net::Nostr::Event>, L<Net::Nostr::Zap>

=cut
