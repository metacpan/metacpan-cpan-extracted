package Net::Nostr::RemoteSigning;

use strictures 2;

use Carp qw(croak);
use JSON ();
use Net::Nostr::Event;

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

###############################################################################
# Bunker URI (remote-signer initiated)
###############################################################################

sub parse_bunker_uri {
    my ($class, $uri) = @_;
    croak "URI must use bunker:// protocol"
        unless $uri =~ m{^bunker://([0-9a-f]{64})\?(.+)$}i;

    my ($pubkey, $query) = (lc($1), $2);

    my (@relays, $secret);
    for my $pair (split /&/, $query) {
        my ($key, $val) = split /=/, $pair, 2;
        $val = _uri_decode($val) if defined $val;
        if ($key eq 'relay')    { push @relays, $val }
        elsif ($key eq 'secret') { $secret = $val }
    }

    croak "URI must contain at least one relay parameter" unless @relays;

    return Net::Nostr::RemoteSigning::BunkerConnection->new(
        remote_signer_pubkey => $pubkey,
        relays               => \@relays,
        secret               => $secret,
    );
}

sub create_bunker_uri {
    my ($class, %args) = @_;
    croak "remote_signer_pubkey is required" unless defined $args{remote_signer_pubkey};
    croak "remote_signer_pubkey must be 64-char lowercase hex" unless $args{remote_signer_pubkey} =~ $HEX64;
    croak "relay is required" unless defined $args{relay};

    my @relays = ref $args{relay} eq 'ARRAY' ? @{$args{relay}} : ($args{relay});

    my $uri = "bunker://$args{remote_signer_pubkey}?";
    my @params;
    for my $r (@relays) {
        push @params, "relay=" . _uri_encode($r);
    }
    push @params, "secret=" . _uri_encode($args{secret}) if defined $args{secret};

    return $uri . join('&', @params);
}

###############################################################################
# Nostrconnect URI (client initiated)
###############################################################################

sub parse_nostrconnect_uri {
    my ($class, $uri) = @_;
    croak "URI must use nostrconnect:// protocol"
        unless $uri =~ m{^nostrconnect://([0-9a-f]{64})\?(.+)$}i;

    my ($pubkey, $query) = (lc($1), $2);

    my (@relays, $secret, $perms, $name, $url, $image);
    for my $pair (split /&/, $query) {
        my ($key, $val) = split /=/, $pair, 2;
        $val = _uri_decode($val) if defined $val;
        if    ($key eq 'relay')  { push @relays, $val }
        elsif ($key eq 'secret') { $secret = $val }
        elsif ($key eq 'perms')  { $perms  = $val }
        elsif ($key eq 'name')   { $name   = $val }
        elsif ($key eq 'url')    { $url    = $val }
        elsif ($key eq 'image')  { $image  = $val }
    }

    croak "URI must contain at least one relay parameter" unless @relays;
    croak "URI must contain a secret parameter" unless defined $secret;

    return Net::Nostr::RemoteSigning::NostrConnect->new(
        client_pubkey => $pubkey,
        relays        => \@relays,
        secret        => $secret,
        perms         => $perms,
        name          => $name,
        url           => $url,
        image         => $image,
    );
}

sub create_nostrconnect_uri {
    my ($class, %args) = @_;
    croak "client_pubkey is required" unless defined $args{client_pubkey};
    croak "client_pubkey must be 64-char lowercase hex" unless $args{client_pubkey} =~ $HEX64;
    croak "relay is required" unless defined $args{relay};
    croak "secret is required" unless defined $args{secret};

    my @relays = ref $args{relay} eq 'ARRAY' ? @{$args{relay}} : ($args{relay});

    my $uri = "nostrconnect://$args{client_pubkey}?";
    my @params;
    for my $r (@relays) {
        push @params, "relay=" . _uri_encode($r);
    }
    push @params, "secret=" . _uri_encode($args{secret});
    push @params, "perms=" . _uri_encode($args{perms}) if defined $args{perms};
    push @params, "name=" . _uri_encode($args{name}) if defined $args{name};
    push @params, "url=" . _uri_encode($args{url}) if defined $args{url};
    push @params, "image=" . _uri_encode($args{image}) if defined $args{image};

    return $uri . join('&', @params);
}

###############################################################################
# Request payload
###############################################################################

sub request {
    my ($class, %args) = @_;
    croak "request requires 'method'" unless defined $args{method};
    croak "request requires 'params'" unless defined $args{params};

    my $id = $args{id} // _generate_id();

    return JSON->new->utf8->canonical->encode({
        id     => $id,
        method => $args{method},
        params => $args{params},
    });
}

###############################################################################
# Request event (kind 24133)
###############################################################################

sub request_event {
    my ($class, %args) = @_;
    croak "request_event requires 'method'" unless defined $args{method};
    croak "request_event requires 'params'" unless defined $args{params};
    croak "request_event requires 'remote_signer_pubkey'" unless defined $args{remote_signer_pubkey};
    croak "remote_signer_pubkey must be 64-char lowercase hex" unless $args{remote_signer_pubkey} =~ $HEX64;

    my $content = $class->request(
        id     => $args{id},
        method => $args{method},
        params => $args{params},
    );

    croak "request_event requires 'pubkey'" unless defined $args{pubkey};
    croak "pubkey must be 64-char lowercase hex" unless $args{pubkey} =~ $HEX64;

    return Net::Nostr::Event->new(
        kind    => 24133,
        pubkey  => $args{pubkey},
        content => $content,
        tags    => [['p', $args{remote_signer_pubkey}]],
    );
}

###############################################################################
# Response payload
###############################################################################

sub response {
    my ($class, %args) = @_;
    croak "response requires 'id'" unless defined $args{id};

    my %data = (id => $args{id});
    $data{result} = $args{result} if exists $args{result};
    $data{error}  = $args{error}  if exists $args{error};

    return JSON->new->utf8->canonical->encode(\%data);
}

###############################################################################
# Response event (kind 24133)
###############################################################################

sub response_event {
    my ($class, %args) = @_;

    my $content = $class->response(
        id     => $args{id},
        result => $args{result},
        (exists $args{error} ? (error => $args{error}) : ()),
    );

    my @tags;
    if (defined $args{client_pubkey}) {
        croak "client_pubkey must be 64-char lowercase hex" unless $args{client_pubkey} =~ $HEX64;
        push @tags, ['p', $args{client_pubkey}];
    }

    croak "response_event requires 'pubkey'" unless defined $args{pubkey};
    croak "pubkey must be 64-char lowercase hex" unless $args{pubkey} =~ $HEX64;

    return Net::Nostr::Event->new(
        kind    => 24133,
        pubkey  => $args{pubkey},
        content => $content,
        tags    => \@tags,
    );
}

###############################################################################
# Parse request/response
###############################################################################

sub parse_request {
    my ($class, $json) = @_;
    my $data = JSON->new->utf8->decode($json);

    return Net::Nostr::RemoteSigning::Request->new(
        id     => $data->{id},
        method => $data->{method},
        params => $data->{params},
    );
}

sub parse_response {
    my ($class, $json) = @_;
    my $data = JSON->new->utf8->decode($json);

    return Net::Nostr::RemoteSigning::Response->new(
        id     => $data->{id},
        result => $data->{result},
        error  => $data->{error},
    );
}

###############################################################################
# Permissions parsing
###############################################################################

sub parse_permissions {
    my ($class, $perms_str) = @_;
    return () unless defined $perms_str && length $perms_str;

    my @perms;
    for my $perm (split /,/, $perms_str) {
        my ($method, $param) = split /:/, $perm, 2;
        push @perms, { method => $method, param => $param };
    }
    return @perms;
}

###############################################################################
# Validation
###############################################################################

sub validate_request {
    my ($class, $event) = @_;
    croak "request MUST be kind 24133" unless $event->kind == 24133;

    my $has_p = grep { $_->[0] eq 'p' } @{$event->tags};
    croak "request SHOULD include a p tag" unless $has_p;

    return 1;
}

sub validate_response {
    my ($class, $event) = @_;
    croak "response MUST be kind 24133" unless $event->kind == 24133;
    return 1;
}

sub validate_connect_response {
    my ($class, $resp, $expected_secret) = @_;

    if (defined $expected_secret) {
        croak "connect response secret does not match"
            unless defined $resp->result && $resp->result eq $expected_secret;
    }

    return 1;
}

###############################################################################
# switch_relays response parsing
###############################################################################

sub parse_switch_relays {
    my ($class, $result) = @_;
    return undef unless defined $result && $result ne 'null';
    return JSON->new->utf8->decode($result);
}

###############################################################################
# NIP-05 metadata parsing
###############################################################################

sub parse_nip05_metadata {
    my ($class, $json) = @_;
    my $data = JSON->new->utf8->decode($json);

    croak "NIP-05 response must contain names._ field"
        unless $data->{names} && defined $data->{names}{'_'};

    my $nip46 = $data->{nip46} // {};

    return Net::Nostr::RemoteSigning::Nip05Metadata->new(
        pubkey           => $data->{names}{'_'},
        relays           => $nip46->{relays} // [],
        nostrconnect_url => $nip46->{nostrconnect_url},
    );
}

###############################################################################
# Discovery event (NIP-89 kind 31990)
###############################################################################

sub parse_discovery_event {
    my ($class, $event) = @_;
    croak "discovery event MUST be kind 31990" unless $event->kind == 31990;

    my $has_k = grep { @$_ >= 2 && $_->[0] eq 'k' && $_->[1] eq '24133' } @{$event->tags};
    croak "discovery event MUST have k tag with value 24133" unless $has_k;

    my @relays;
    my $nostrconnect_url;
    for my $tag (@{$event->tags}) {
        next unless @$tag >= 2;
        if ($tag->[0] eq 'relay') {
            push @relays, $tag->[1];
        } elsif ($tag->[0] eq 'nostrconnect_url') {
            $nostrconnect_url = $tag->[1];
        }
    }

    return Net::Nostr::RemoteSigning::Discovery->new(
        pubkey           => $event->pubkey,
        relays           => \@relays,
        nostrconnect_url => $nostrconnect_url,
    );
}

sub discovery_event {
    my ($class, %args) = @_;

    my @tags = (['k', '24133']);

    if ($args{relays} && @{$args{relays}}) {
        for my $r (@{$args{relays}}) {
            push @tags, ['relay', $r];
        }
    }

    push @tags, ['nostrconnect_url', $args{nostrconnect_url}]
        if defined $args{nostrconnect_url};

    croak "discovery_event requires 'pubkey'" unless defined $args{pubkey};
    croak "pubkey must be 64-char lowercase hex" unless $args{pubkey} =~ $HEX64;

    return Net::Nostr::Event->new(
        kind    => 31990,
        pubkey  => $args{pubkey},
        content => '',
        tags    => \@tags,
    );
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
    $str =~ s/\+/ /g;
    $str =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
    return $str;
}

sub _generate_id {
    my @chars = ('a'..'z', '0'..'9');
    return join '', map { $chars[rand @chars] } 1..16;
}

###############################################################################
# Inner classes
###############################################################################

{
    package Net::Nostr::RemoteSigning::BunkerConnection;
    use Carp qw(croak);
    use Class::Tiny qw(remote_signer_pubkey secret);
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
    package Net::Nostr::RemoteSigning::NostrConnect;
    use Carp qw(croak);
    use Class::Tiny qw(client_pubkey secret perms name url image);
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
    package Net::Nostr::RemoteSigning::Nip05Metadata;
    use Carp qw(croak);
    use Class::Tiny qw(pubkey nostrconnect_url);
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
    package Net::Nostr::RemoteSigning::Discovery;
    use Carp qw(croak);
    use Class::Tiny qw(pubkey nostrconnect_url);
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
    package Net::Nostr::RemoteSigning::Request;
    use Carp qw(croak);
    use Class::Tiny qw(id method);
    sub new {
        my $class = shift;
        my $self = bless { @_ }, $class;
        my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
        $known{params} = ();
        my @unknown = grep { !exists $known{$_} } keys %$self;
        croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
        croak "id is required" unless defined $self->{id};
        croak "method is required" unless defined $self->{method};
        croak "params is required" unless defined $self->{params};
        croak "params must be an arrayref" unless ref($self->{params}) eq 'ARRAY';
        $self->{params} = [@{$self->{params}}];
        return $self;
    }
    sub params {
        my $self = shift;
        croak "params is read-only" if @_;
        return [@{$self->{params}}];
    }
}

{
    package Net::Nostr::RemoteSigning::Response;
    use Carp qw(croak);
    use Class::Tiny qw(id result error);
    sub new {
        my $class = shift;
        my $self = bless { @_ }, $class;
        my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
        my @unknown = grep { !exists $known{$_} } keys %$self;
        croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
        croak "id is required" unless defined $self->{id};
        return $self;
    }

    sub is_error {
        my ($self) = @_;
        return defined $self->error && !(defined $self->result && $self->result eq 'auth_url');
    }

    sub is_auth_challenge {
        my ($self) = @_;
        return defined $self->result && $self->result eq 'auth_url';
    }

    sub auth_url {
        my ($self) = @_;
        return $self->is_auth_challenge ? $self->error : undef;
    }
}

1;

__END__

=head1 NAME

Net::Nostr::RemoteSigning - NIP-46 Nostr Remote Signing

=head1 SYNOPSIS

    use Net::Nostr::RemoteSigning;

    my $remote_signer_pubkey = 'fa984bd7dbb282f07e16e7ae87b26a2a7b9b90b7246a44771f0cf5ae58018f52';
    my $client_pubkey        = 'eff37350d839ce3707332348af4549a96051bd695d3223af4aabce4993531d86';

    # Parse a bunker URI (remote-signer initiated)
    my $conn = Net::Nostr::RemoteSigning->parse_bunker_uri(
        "bunker://${remote_signer_pubkey}?relay=wss%3A%2F%2Frelay.example.com&secret=mysecret"
    );
    say $conn->remote_signer_pubkey;
    say $conn->relays->[0];

    # Parse a nostrconnect URI (client initiated)
    my $nc = Net::Nostr::RemoteSigning->parse_nostrconnect_uri(
        "nostrconnect://${client_pubkey}?relay=wss%3A%2F%2Frelay.example.com&secret=0s8j2djs&name=My+Client"
    );
    say $nc->client_pubkey;
    say $nc->secret;

    # Build a request payload
    my $payload = Net::Nostr::RemoteSigning->request(
        id     => 'req-1',
        method => 'sign_event',
        params => ['{}'],
    );

    # Build a request event (kind 24133)
    my $event = Net::Nostr::RemoteSigning->request_event(
        id                   => 'req-1',
        method               => 'sign_event',
        params               => ['{}'],
        pubkey               => $client_pubkey,
        remote_signer_pubkey => $remote_signer_pubkey,
    );

    # Parse a decrypted response
    my $json = JSON->new->utf8->encode({ id => 'req-1', result => 'pong' });
    my $resp = Net::Nostr::RemoteSigning->parse_response($json);
    if ($resp->is_auth_challenge) {
        # Display $resp->auth_url to user
    } elsif ($resp->is_error) {
        warn $resp->error;
    } else {
        say $resp->result;
    }

    # Parse permissions
    my @perms = Net::Nostr::RemoteSigning->parse_permissions(
        'nip44_encrypt,sign_event:4'
    );

=head1 DESCRIPTION

Implements NIP-46 Nostr Remote Signing, a protocol for 2-way communication
between a remote signer (bunker) and a Nostr client. The remote signer holds
the user's private keys and signs events on behalf of the client, minimizing
key exposure.

Both request and response events use kind 24133. The content field is
encrypted using L<NIP-44|https://github.com/nostr-protocol/nips/blob/master/44.md>.
This module handles the payload structure and event creation; the caller is
responsible for encrypting/decrypting the content.

=head2 Connection Flow

There are two ways to initiate a connection:

=over 4

=item * B<Remote-signer initiated> - The signer provides a C<bunker://> URI.
The client sends a C<connect> request to the signer via the specified relays.

=item * B<Client initiated> - The client provides a C<nostrconnect://> URI.
The signer sends a C<connect> response back to the client.

=back

=head2 Commands

C<connect>, C<sign_event>, C<ping>, C<get_public_key>, C<nip04_encrypt>,
C<nip04_decrypt>, C<nip44_encrypt>, C<nip44_decrypt>, C<switch_relays>.

=head1 CLASS METHODS

=head2 parse_bunker_uri

    my $conn = Net::Nostr::RemoteSigning->parse_bunker_uri($uri_string);

Parses a C<bunker://> connection URI. Returns a L</BunkerConnection> object.
Croaks if the URI is malformed or missing the required C<relay> parameter.
The C<secret> parameter is optional.

=head2 create_bunker_uri

    my $uri = Net::Nostr::RemoteSigning->create_bunker_uri(
        remote_signer_pubkey => $hex_pubkey,       # required
        relay                => $url_or_arrayref,  # required
        secret               => $secret_string,    # optional
    );

Creates a C<bunker://> URI string.

=head2 parse_nostrconnect_uri

    my $nc = Net::Nostr::RemoteSigning->parse_nostrconnect_uri($uri_string);

Parses a C<nostrconnect://> connection URI. Returns a L</NostrConnect> object.
Croaks if the URI is malformed or missing required parameters (C<relay>,
C<secret>).

=head2 create_nostrconnect_uri

    my $uri = Net::Nostr::RemoteSigning->create_nostrconnect_uri(
        client_pubkey => $hex_pubkey,              # required
        relay         => $url_or_arrayref,         # required
        secret        => $secret_string,           # required
        perms         => 'nip44_encrypt,sign_event:4',  # optional
        name          => 'My Client',              # optional
        url           => 'https://app.example.com',     # optional
        image         => 'https://app.example.com/i.png', # optional
    );

Creates a C<nostrconnect://> URI string.

=head2 request

    my $json = Net::Nostr::RemoteSigning->request(
        id     => 'req-1',    # optional, auto-generated if omitted
        method => 'ping',
        params => [],
    );

Builds a JSON-encoded request payload. Croaks if C<method> or C<params> is
missing.

=head2 request_event

    my $event = Net::Nostr::RemoteSigning->request_event(
        id                   => 'req-1',
        method               => 'sign_event',
        params               => [$event_json],
        pubkey               => $client_pubkey,
        remote_signer_pubkey => $remote_signer_pubkey,
    );

Creates a kind 24133 request L<Net::Nostr::Event> with the JSON payload as
unencrypted content and a C<p> tag with the remote signer's pubkey. Croaks
if C<pubkey> is missing or not 64-char lowercase hex.

=head2 response

    my $json = Net::Nostr::RemoteSigning->response(
        id     => 'req-1',
        result => 'pong',
    );

Builds a JSON-encoded response payload. Croaks if C<id> is missing.

=head2 response_event

    my $event = Net::Nostr::RemoteSigning->response_event(
        id            => 'req-1',
        result        => 'pong',
        pubkey        => $remote_signer_pubkey,
        client_pubkey => $client_pubkey,
    );

Creates a kind 24133 response L<Net::Nostr::Event> with a C<p> tag pointing
to the client's pubkey. Croaks if C<pubkey> is missing or not 64-char
lowercase hex.

=head2 parse_request

    my $req = Net::Nostr::RemoteSigning->parse_request($json);

Parses a decrypted JSON request payload. Returns a L</Request> object.
Croaks if C<id>, C<method>, or C<params> is missing, or if C<params> is
not an arrayref.

=head2 parse_response

    my $resp = Net::Nostr::RemoteSigning->parse_response($json);

Parses a decrypted JSON response payload. Returns a L</Response> object.
Croaks if C<id> is missing.

=head2 parse_permissions

    my @perms = Net::Nostr::RemoteSigning->parse_permissions($perms_string);

Parses a comma-separated permission string (e.g. C<'nip44_encrypt,sign_event:4'>).
Returns a list of hashrefs with C<method> and optional C<param> keys.

=head2 validate_request

    Net::Nostr::RemoteSigning->validate_request($event);

Validates that a request event is kind 24133 and has a C<p> tag. Croaks on
failure.

=head2 validate_response

    Net::Nostr::RemoteSigning->validate_response($event);

Validates that a response event is kind 24133. Croaks on failure.

=head2 validate_connect_response

    Net::Nostr::RemoteSigning->validate_connect_response($resp, $expected_secret);

Validates that a connect response contains the expected secret. If no expected
secret is provided, accepts any response (for bunker-initiated connections
where the result is C<"ack">). Croaks if the secret does not match.

=head2 parse_switch_relays

    my $relays = Net::Nostr::RemoteSigning->parse_switch_relays($result_string);

Parses a C<switch_relays> response result. Returns an arrayref of relay URLs,
or C<undef> if the result is null (indicating no relay change needed).

=head2 parse_nip05_metadata

    my $meta = Net::Nostr::RemoteSigning->parse_nip05_metadata($json);

Parses a NIP-05 C<.well-known/nostr.json> response containing NIP-46 metadata.
Returns a L</Nip05Metadata> object. Croaks if the response does not contain
a C<names._> field.

=head2 parse_discovery_event

    my $disc = Net::Nostr::RemoteSigning->parse_discovery_event($event);

Parses a NIP-89 kind 31990 discovery event. Returns a L</Discovery> object.
Croaks if the event is not kind 31990 or lacks a C<k> tag with value C<24133>.

=head2 discovery_event

    my $event = Net::Nostr::RemoteSigning->discovery_event(
        pubkey           => $remote_signer_pubkey,
        relays           => [$relay1, $relay2],      # optional
        nostrconnect_url => 'https://signer.example.com/<nostrconnect>',  # optional
    );

Creates a NIP-89 kind 31990 discovery L<Net::Nostr::Event> with a C<k> tag
of C<24133>. Optionally includes C<relay> and C<nostrconnect_url> tags.
Croaks if C<pubkey> is missing or not 64-char lowercase hex.

=head1 OBJECTS

=head2 BunkerConnection

Returned by L</parse_bunker_uri>. Croaks on unknown arguments.

=over 4

=item C<remote_signer_pubkey> - 32-byte hex public key of the remote signer

=item C<relays> - Arrayref of relay URLs

=item C<secret> - Optional secret for the connection

=back

=head2 NostrConnect

Returned by L</parse_nostrconnect_uri>. Croaks on unknown arguments.

=over 4

=item C<client_pubkey> - 32-byte hex public key of the client

=item C<relays> - Arrayref of relay URLs

=item C<secret> - Secret string for connection validation

=item C<perms> - Optional comma-separated permissions string

=item C<name> - Optional client application name

=item C<url> - Optional canonical URL of the client application

=item C<image> - Optional image URL for the client application

=back

=head2 Nip05Metadata

Returned by L</parse_nip05_metadata>. Croaks on unknown arguments.

=over 4

=item C<pubkey> - 32-byte hex public key from the C<names._> field

=item C<relays> - Arrayref of relay URLs from the C<nip46.relays> field

=item C<nostrconnect_url> - Optional nostrconnect URL template

=back

=head2 Discovery

Returned by L</parse_discovery_event>. Croaks on unknown arguments.

=over 4

=item C<pubkey> - 32-byte hex public key of the remote signer (event author)

=item C<relays> - Arrayref of relay URLs from C<relay> tags

=item C<nostrconnect_url> - Optional nostrconnect URL from C<nostrconnect_url> tag

=back

=head2 Request

Returned by L</parse_request>. Croaks on unknown arguments or missing
required fields (C<id>, C<method>, C<params>). C<params> must be an arrayref.

=over 4

=item C<id> - Request ID string

=item C<method> - Method name (e.g. C<'sign_event'>, C<'ping'>)

=item C<params> - Arrayref of string parameters

=back

=head2 Response

Returned by L</parse_response>. Croaks on unknown arguments or missing
C<id>.

=over 4

=item C<id> - Request ID this response corresponds to

=item C<result> - Result string, or undef on error

=item C<error> - Error string, or undef on success

=item C<is_error> - Returns true if this is an error response

=item C<is_auth_challenge> - Returns true if this is an auth challenge (result is C<"auth_url">)

=item C<auth_url> - Returns the auth URL from the error field if this is an auth challenge

=back

=head1 SEE ALSO

L<NIP-46|https://github.com/nostr-protocol/nips/blob/master/46.md>,
L<Net::Nostr>, L<Net::Nostr::Event>, L<Net::Nostr::Encryption>

=cut
