package Net::Nostr::RelayAdmin;

use strictures 2;

use Carp qw(croak);
use JSON ();
use Net::Nostr::HttpAuth qw(create_auth_header);
use Exporter 'import';

our @EXPORT_OK = qw(
    encode_request
    decode_response
    request_with_auth
);

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

my %PUBKEY_METHODS = map { $_ => 1 } qw(
    banpubkey unbanpubkey allowpubkey unallowpubkey
);

my %EVENT_ID_METHODS = map { $_ => 1 } qw(
    allowevent banevent
);

my %KIND_METHODS = map { $_ => 1 } qw(
    allowkind disallowkind
);

my %STRING_METHODS = map { $_ => 1 } qw(
    changerelayname changerelaydescription changerelayicon
);

my %IP_METHODS = map { $_ => 1 } qw(
    blockip unblockip
);

sub encode_request {
    my (%args) = @_;
    my $method = $args{method};
    croak "method is required" unless defined $method && length $method;

    my $params = $args{params} // [];
    croak "params must be an array reference" unless ref $params eq 'ARRAY';

    _validate_params($method, $params);

    return JSON->new->utf8->encode({
        method => $method,
        params => $params,
    });
}

sub decode_response {
    my ($json) = @_;
    croak "response is required" unless defined $json && length $json;

    my $data = eval { JSON->new->utf8->decode($json) };
    croak "invalid JSON in response: $@" if $@;

    if (defined $data->{error} && length $data->{error}) {
        croak $data->{error};
    }

    return $data->{result};
}

sub request_with_auth {
    my (%args) = @_;
    my $key       = $args{key}       // croak "key is required";
    my $relay_url = $args{relay_url} // croak "relay_url is required";

    my $body = encode_request(
        method => $args{method},
        (exists $args{params} ? (params => $args{params}) : ()),
    );

    my $auth = create_auth_header(
        key     => $key,
        url     => $relay_url,
        method  => 'POST',
        payload => $body,
    );

    return (
        body          => $body,
        authorization => $auth,
        content_type  => 'application/nostr+json+rpc',
    );
}

sub _validate_params {
    my ($method, $params) = @_;

    if ($PUBKEY_METHODS{$method}) {
        croak "$method requires a 64-char hex pubkey as first param"
            unless @$params >= 1;
        croak "pubkey must be 64-char lowercase hex"
            unless $params->[0] =~ $HEX64;
    }
    elsif ($EVENT_ID_METHODS{$method}) {
        croak "$method requires a 64-char hex event id as first param"
            unless @$params >= 1;
        croak "event id must be 64-char lowercase hex"
            unless $params->[0] =~ $HEX64;
    }
    elsif ($KIND_METHODS{$method}) {
        croak "$method requires a kind number as first param"
            unless @$params >= 1;
        croak "kind must be a non-negative integer"
            unless defined $params->[0]
                && $params->[0] =~ /\A[0-9]+\z/
                && $params->[0] == int($params->[0]);
    }
    elsif ($STRING_METHODS{$method}) {
        croak "$method requires a string param"
            unless @$params >= 1 && defined $params->[0];
    }
    elsif ($IP_METHODS{$method}) {
        croak "$method requires an IP address as first param"
            unless @$params >= 1 && defined $params->[0] && length $params->[0];
    }
}

1;

__END__

=head1 NAME

Net::Nostr::RelayAdmin - NIP-86 relay management API

=head1 SYNOPSIS

    use Net::Nostr::RelayAdmin qw(
        encode_request decode_response request_with_auth
    );

    # Encode a management request
    my $body = encode_request(
        method => 'banpubkey',
        params => ['aa' x 32, 'spammer'],
    );

    # Decode a response
    my $result = decode_response('{"result":true}');
    # or handle errors
    eval { decode_response('{"error":"not authorized"}') };
    warn $@ if $@;

    # Build a full authenticated request
    my %req = request_with_auth(
        method    => 'supportedmethods',
        params    => [],
        key       => $key,
        relay_url => 'wss://relay.example.com',
    );
    # %req contains: body, authorization, content_type

=head1 DESCRIPTION

Implements the client side of the NIP-86 relay management API. NIP-86
defines a JSON-RPC-like request-response protocol over HTTP for relay
administration. Requests are sent to the relay's WebSocket URI with
C<Content-Type: application/nostr+json+rpc> and authorized using
NIP-98 HTTP auth with a required C<payload> tag.

The following management methods are defined by NIP-86:

=over 4

=item C<supportedmethods> - list supported methods

=item C<banpubkey>, C<unbanpubkey>, C<listbannedpubkeys> - pubkey banning

=item C<allowpubkey>, C<unallowpubkey>, C<listallowedpubkeys> - pubkey allowlisting

=item C<listeventsneedingmoderation>, C<allowevent>, C<banevent>, C<listbannedevents> - event moderation

=item C<changerelayname>, C<changerelaydescription>, C<changerelayicon> - relay metadata

=item C<allowkind>, C<disallowkind>, C<listallowedkinds> - kind filtering

=item C<blockip>, C<unblockip>, C<listblockedips> - IP blocking

=back

Unknown method names are passed through without parameter validation,
allowing forward compatibility with relay-specific extensions.

=head1 FUNCTIONS

All functions are exportable. None are exported by default.

=head2 encode_request

    my $body = encode_request(
        method => $method_name,
        params => \@params,       # optional, defaults to []
    );

Encodes a relay management request as a JSON string with C<method>
and C<params> fields. Croaks if C<method> is missing or empty.
Croaks if C<params> is provided but not an array reference.

For known NIP-86 methods, validates that params contain the correct
types: 64-char lowercase hex for pubkey/event-id methods, non-negative
integers for kind methods, non-empty strings for relay metadata
methods, and non-empty strings for IP methods.

    my $body = encode_request(
        method => 'banpubkey',
        params => ['aa' x 32, 'spammer'],
    );

=head2 decode_response

    my $result = decode_response($json);

Parses a JSON response string and returns the C<result> field. If
the response contains a non-empty C<error> field, croaks with the
error message. Croaks if the input is missing, empty, or not valid
JSON.

    my $result = decode_response('{"result":true}');

    eval { decode_response('{"error":"not authorized"}') };
    if ($@) {
        # handle error
    }

=head2 request_with_auth

    my %req = request_with_auth(
        method    => $method_name,
        params    => \@params,       # optional, defaults to []
        key       => $nostr_key,
        relay_url => $relay_url,
    );

Builds a complete authenticated relay management request. Returns
a hash with three keys:

=over 4

=item C<body> - the JSON request body

=item C<authorization> - a NIP-98 C<Authorization> header value
(C<Nostr E<lt>base64E<gt>>)

=item C<content_type> - C<application/nostr+json+rpc>

=back

The NIP-98 auth event uses C<POST> as the HTTP method, the
C<relay_url> as the C<u> tag, and includes a C<payload> tag with
the SHA-256 hash of the request body, as required by NIP-86.

Croaks if C<key> or C<relay_url> is missing. The C<key> must be a
L<Net::Nostr::Key> object with a private key for signing.

    my %req = request_with_auth(
        method    => 'supportedmethods',
        params    => [],
        key       => $key,
        relay_url => 'wss://relay.example.com',
    );

=head1 SEE ALSO

L<NIP-86|https://github.com/nostr-protocol/nips/blob/master/86.md>,
L<Net::Nostr>, L<Net::Nostr::HttpAuth>

=cut
