package Net::Nostr::HttpAuth;

use strictures 2;

use Carp qw(croak);
use JSON ();
use MIME::Base64 qw(encode_base64 decode_base64);
use Digest::SHA qw(sha256_hex);
use Net::Nostr::Event;
use Exporter 'import';

our @EXPORT_OK = qw(
    create_auth_event
    create_auth_header
    parse_auth_header
    validate_auth_event
);

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

sub create_auth_event {
    my (%args) = @_;
    my $pubkey = $args{pubkey} // croak "pubkey is required";
    my $url    = $args{url}    // croak "url is required";
    my $method = $args{method} // croak "method is required";

    croak "pubkey must be 64-char lowercase hex" unless $pubkey =~ $HEX64;

    my @tags = (
        ['u', $url],
        ['method', $method],
    );

    # SHOULD include payload hash for body-bearing methods
    if (defined $args{payload}) {
        push @tags, ['payload', sha256_hex($args{payload})];
    }

    return Net::Nostr::Event->new(
        pubkey     => $pubkey,
        kind       => 27235,
        content    => '',
        tags       => \@tags,
        created_at => $args{created_at} // time(),
    );
}

sub create_auth_header {
    my (%args) = @_;
    my $key    = $args{key}    // croak "key is required";
    my $url    = $args{url}    // croak "url is required";
    my $method = $args{method} // croak "method is required";

    my $event = create_auth_event(
        pubkey     => $key->pubkey_hex,
        url        => $url,
        method     => $method,
        (defined $args{payload}     ? (payload => $args{payload}) : ()),
        (defined $args{created_at}  ? (created_at => $args{created_at}) : ()),
    );

    $key->sign_event($event);

    my $json = JSON->new->utf8->encode($event->to_hash);
    my $b64  = encode_base64($json, '');
    return "Nostr $b64";
}

sub parse_auth_header {
    my ($header) = @_;
    croak "authorization header is required" unless defined $header && length $header;

    my ($scheme, $b64) = split / /, $header, 2;
    croak "expected Nostr authorization scheme, got $scheme"
        unless defined $scheme && $scheme eq 'Nostr';
    croak "missing base64 data" unless defined $b64 && length $b64;

    my $json = decode_base64($b64);
    croak "invalid base64 data" unless defined $json && length $json;

    my $data = eval { JSON->new->utf8->decode($json) };
    croak "invalid JSON in authorization header: $@" if $@;

    return Net::Nostr::Event->from_wire($data);
}

sub validate_auth_event {
    my ($event, %opts) = @_;
    croak "event is required" unless defined $event;
    my $url    = $opts{url}    // croak "url is required";
    my $method = $opts{method} // croak "method is required";
    my $time_window = $opts{time_window} // 60;

    # 0. Verify event ID and signature (NIP-01 requirement)
    $event->validate;

    # 1. Kind MUST be 27235
    croak "kind must be 27235" unless $event->kind == 27235;

    # 2. created_at MUST be within time window
    my $age = abs(time() - $event->created_at);
    croak "created_at outside time window ($age > $time_window seconds)"
        if $age > $time_window;

    # 3. u tag MUST match exactly
    my $u_value;
    my $method_value;
    my $payload_value;
    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'u' && !defined $u_value) {
            $u_value = $tag->[1];
        } elsif ($tag->[0] eq 'method' && !defined $method_value) {
            $method_value = $tag->[1];
        } elsif ($tag->[0] eq 'payload' && !defined $payload_value) {
            $payload_value = $tag->[1];
        }
    }

    croak "missing u tag" unless defined $u_value;
    croak "u tag does not match request URL"
        unless $u_value eq $url;

    # 4. method tag MUST match
    croak "missing method tag" unless defined $method_value;
    croak "method tag does not match request method"
        unless $method_value eq $method;

    # MAY: check payload hash if server provides the body
    if (defined $payload_value && defined $opts{payload}) {
        my $expected = sha256_hex($opts{payload});
        croak "payload tag does not match request body hash"
            unless $payload_value eq $expected;
    }

    return 1;
}

1;

__END__

=head1 NAME

Net::Nostr::HttpAuth - NIP-98 HTTP auth

=head1 SYNOPSIS

    use Net::Nostr::HttpAuth qw(
        create_auth_event create_auth_header
        parse_auth_header validate_auth_event
    );

    # Client: create an Authorization header for a GET request
    my $header = create_auth_header(
        key    => $key,
        url    => 'https://api.example.com/data',
        method => 'GET',
    );
    # "Nostr eyJpZCI6Ii..."

    # Client: POST with payload hash
    my $body = '{"name":"test"}';
    my $header = create_auth_header(
        key     => $key,
        url     => 'https://api.example.com/upload',
        method  => 'POST',
        payload => $body,
    );

    # Server: parse and validate
    my $event = parse_auth_header($header);
    validate_auth_event($event,
        url    => 'https://api.example.com/data',
        method => 'GET',
    );

=head1 DESCRIPTION

Implements NIP-98 HTTP auth. Uses kind 27235 ephemeral nostr events
to authorize HTTP requests. The client signs an event containing the
request URL and method, base64-encodes it, and sends it in the
C<Authorization> HTTP header with the C<Nostr> scheme. The server
decodes the event and validates the kind, timestamp, URL, and method.

When the request has a body (POST, PUT, PATCH), the client SHOULD
include a C<payload> tag containing the SHA-256 hex hash of the body.
The server MAY check this tag to verify the body is authorized.

=head1 FUNCTIONS

All functions are exportable. None are exported by default.

=head2 create_auth_event

    my $event = create_auth_event(
        pubkey     => $hex_pubkey,
        url        => $absolute_url,
        method     => $http_method,
        payload    => $body,        # optional
        created_at => time(),       # optional, defaults to now
    );

Creates a kind 27235 L<Net::Nostr::Event> with C<u> and C<method>
tags. If C<payload> is provided, adds a C<payload> tag with the
SHA-256 hex hash of the body. The event content is always empty.
Croaks if C<pubkey>, C<url>, or C<method> is missing. Croaks if
C<pubkey> is not 64-character lowercase hex.

The returned event is unsigned. Use L<Net::Nostr::Key/sign_event>
to sign it before encoding.

    my $event = create_auth_event(
        pubkey => 'aa' x 32,
        url    => 'https://api.example.com/data',
        method => 'GET',
    );

=head2 create_auth_header

    my $header = create_auth_header(
        key        => $nostr_key,
        url        => $absolute_url,
        method     => $http_method,
        payload    => $body,           # optional
        created_at => time(),          # optional, defaults to now
    );

Creates, signs, and base64-encodes a kind 27235 event, returning
a complete C<Authorization> header value in the format
C<Nostr E<lt>base64E<gt>>. The C<key> must be a L<Net::Nostr::Key>
object with a private key for signing. Croaks if C<key>, C<url>,
or C<method> is missing.

    my $header = create_auth_header(
        key    => $key,
        url    => 'https://api.example.com/data',
        method => 'GET',
    );
    # "Nostr eyJpZCI6Ii..."

=head2 parse_auth_header

    my $event = parse_auth_header($header_value);

Parses an C<Authorization> header value. Validates the C<Nostr>
scheme, decodes the base64 payload, and parses the JSON into a
L<Net::Nostr::Event> using L<Net::Nostr::Event/from_wire>.
Croaks if the header is missing, uses the wrong scheme, or
contains invalid base64 or JSON.

    my $event = parse_auth_header('Nostr eyJpZCI6Ii...');

=head2 validate_auth_event

    validate_auth_event($event,
        url         => $absolute_url,
        method      => $http_method,
        payload     => $body,         # optional
        time_window => 60,            # optional, seconds, default 60
    );

Performs the server-side validation checks specified by NIP-98:

=over 4

=item 0. The event ID and Schnorr signature are cryptographically
verified via L<Net::Nostr::Event/validate>. This ensures the event
was actually signed by the claimed pubkey and has not been tampered
with.

=item 1. The C<kind> MUST be C<27235>.

=item 2. The C<created_at> timestamp MUST be within C<time_window>
seconds of the current time (default 60 seconds).

=item 3. The C<u> tag MUST exactly match the request URL (including
query parameters).

=item 4. The C<method> tag MUST match the HTTP method used.

=back

If C<payload> is provided and the event has a C<payload> tag, the
tag value is checked against the SHA-256 hex hash of the body. If
the server does not provide C<payload>, the tag is not checked.

Returns 1 on success. Croaks with a descriptive message on failure.
Servers SHOULD respond with HTTP 401 when validation fails.

    eval { validate_auth_event($event, url => $url, method => 'GET') };
    if ($@) {
        # respond with 401 Unauthorized
    }

=head1 SEE ALSO

L<NIP-98|https://github.com/nostr-protocol/nips/blob/master/98.md>,
L<Net::Nostr>, L<Net::Nostr::Event>, L<Net::Nostr::Key>

=cut
