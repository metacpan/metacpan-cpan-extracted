package Net::Nostr::RelayInfo;

use strictures 2;

use Carp qw(croak);
use JSON ();

use Class::Tiny qw(
    name description banner icon pubkey self contact
    software version terms_of_service payments_url
);

my @SCALAR_FIELDS = qw(
    name description banner icon pubkey self contact
    software version terms_of_service payments_url
);
my @STRUCT_FIELDS = qw(supported_nips limitation fees);

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    @known{@STRUCT_FIELDS} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    # Defensive copies of structured fields
    $self->{supported_nips} = [@{$self->{supported_nips}}]
        if ref $self->{supported_nips} eq 'ARRAY';
    $self->{limitation} = {%{$self->{limitation}}}
        if ref $self->{limitation} eq 'HASH';
    $self->{fees} = {%{$self->{fees}}}
        if ref $self->{fees} eq 'HASH';

    return $self;
}

# Read-only accessors for structured fields that return shallow copies.
for my $field (@STRUCT_FIELDS) {
    no strict 'refs';
    *$field = sub {
        my $self = shift;
        croak "$field is read-only" if @_;
        my $val = $self->{$field};
        return undef unless defined $val;
        return ref $val eq 'ARRAY' ? [@$val] : {%$val};
    };
}

sub to_json {
    my ($self) = @_;
    my %doc;
    for my $field (@SCALAR_FIELDS) {
        $doc{$field} = $self->$field if defined $self->$field;
    }
    for my $field (@STRUCT_FIELDS) {
        $doc{$field} = $self->$field if defined $self->$field;
    }
    return JSON->new->utf8->canonical->encode(\%doc);
}

sub from_json {
    my ($class, $json) = @_;
    my $data = JSON->new->utf8->decode($json);
    my %args;
    for my $field (@SCALAR_FIELDS, @STRUCT_FIELDS) {
        $args{$field} = $data->{$field} if exists $data->{$field};
    }
    return $class->new(%args);
}

my @CORS_HEADERS = (
    'Access-Control-Allow-Origin: *',
    'Access-Control-Allow-Headers: Accept',
    'Access-Control-Allow-Methods: GET, OPTIONS',
);

sub to_http_response {
    my ($self) = @_;
    my $body = $self->to_json;
    return join("\r\n",
        'HTTP/1.1 200 OK',
        'Content-Type: application/nostr+json',
        @CORS_HEADERS,
        'Content-Length: ' . length($body),
    ) . "\r\n\r\n" . $body;
}

sub cors_preflight_response {
    return join("\r\n",
        'HTTP/1.1 204 No Content',
        @CORS_HEADERS,
        'Content-Length: 0',
        '',
        '',
    );
}

1;

__END__

=head1 NAME

Net::Nostr::RelayInfo - NIP-11 relay information document

=head1 SYNOPSIS

    use Net::Nostr::RelayInfo;

    # Build a relay information document
    my $info = Net::Nostr::RelayInfo->new(
        name           => 'My Relay',
        description    => 'A relay for everyone',
        pubkey         => $admin_pubkey,
        self           => $relay_pubkey,
        contact        => 'mailto:admin@example.com',
        supported_nips => [1, 9, 11, 42, 44],
        software       => 'https://example.com/relay',
        version        => '1.0.0',
    );

    # Serialize to JSON
    my $json = $info->to_json;

    # Parse a relay info document (e.g. from an HTTP response)
    my $info = Net::Nostr::RelayInfo->from_json($json);
    say $info->name;
    say join(', ', @{$info->supported_nips});

    # Generate an HTTP response with CORS headers
    my $http_response = $info->to_http_response;

    # Set on a relay to enable NIP-11
    use Net::Nostr::Relay;
    my $relay = Net::Nostr::Relay->new(
        relay_info => $info,
    );
    $relay->start('127.0.0.1', 8080);

=head1 DESCRIPTION

Implements L<NIP-11|https://github.com/nostr-protocol/nips/blob/master/11.md>,
the relay information document. This is a JSON document served over HTTP at the
same URI as the relay's WebSocket endpoint. Clients request it with an
C<Accept: application/nostr+json> header.

When a C<relay_info> is set on a L<Net::Nostr::Relay>, the relay will
automatically serve the document in response to HTTP requests with the
correct Accept header, and handle CORS preflight OPTIONS requests.

=head1 CONSTRUCTOR

=head2 new

    my $info = Net::Nostr::RelayInfo->new(
        name             => 'My Relay',
        description      => 'A relay for everyone',
        banner           => 'https://example.com/banner.jpg',
        icon             => 'https://example.com/icon.png',
        pubkey           => $admin_pubkey_hex,
        self             => $relay_pubkey_hex,
        contact          => 'mailto:admin@example.com',
        supported_nips   => [1, 9, 11],
        software         => 'https://example.com/relay',
        version          => '1.0.0',
        terms_of_service => 'https://example.com/tos',
        limitation       => { max_subscriptions => 50 },
        payments_url     => 'https://example.com/pay',
        fees             => { admission => [{ amount => 1000, unit => 'msats' }] },
    );

All fields are optional and may be omitted. Croaks on unknown arguments.
The C<name> field SHOULD be less than 30 characters. The C<pubkey> field is
the administrative contact pubkey. The C<self> field is the relay's own
pubkey. C<supported_nips> is an arrayref of integer NIP numbers.

The C<limitation> hashref may contain any of the following keys:

    my $info = Net::Nostr::RelayInfo->new(
        limitation => {
            max_message_length   => 16384,
            max_subscriptions    => 300,
            max_limit            => 5000,
            max_subid_length     => 100,
            max_event_tags       => 100,
            max_content_length   => 8196,
            min_pow_difficulty   => 30,
            auth_required        => \1,
            payment_required     => \1,
            restricted_writes    => \1,
            created_at_lower_limit => 31536000,
            created_at_upper_limit => 3,
            default_limit        => 500,
        },
    );

The C<fees> hashref maps fee types to arrayrefs of fee entries. Each fee
entry has C<amount> and C<unit> keys, and optionally C<period> (for
subscriptions) or C<kinds> (for per-kind publication fees):

    my $info = Net::Nostr::RelayInfo->new(
        payments_url => 'https://my-relay/payments',
        fees => {
            admission    => [{ amount => 1000000, unit => 'msats' }],
            subscription => [{ amount => 5000000, unit => 'msats',
                               period => 2592000 }],
            publication  => [{ kinds => [4], amount => 100,
                               unit => 'msats' }],
        },
    );

=head1 CLASS METHODS

=head2 from_json

    my $info = Net::Nostr::RelayInfo->from_json($json_string);

Parses a JSON relay information document. Unknown fields are ignored per spec.

    use HTTP::Tiny;
    my $resp = HTTP::Tiny->new->get($relay_url, {
        headers => { Accept => 'application/nostr+json' },
    });
    die "Failed to fetch relay info: $resp->{status}"
        unless $resp->{success};
    my $info = Net::Nostr::RelayInfo->from_json($resp->{content});

=head2 cors_preflight_response

    my $http = Net::Nostr::RelayInfo->cors_preflight_response;

Returns an HTTP 204 response string with CORS headers for handling
OPTIONS preflight requests. May be called as a class method or a
function -- the invocant is not used.

=head1 METHODS

=head2 to_json

    my $json = $info->to_json;

Serializes the relay information document to a JSON string. Only fields
that have been set are included.

=head2 to_http_response

    my $http = $info->to_http_response;

Returns a complete HTTP 200 response string with the JSON body,
C<Content-Type: application/nostr+json>, and the required CORS headers
(C<Access-Control-Allow-Origin>, C<Access-Control-Allow-Headers>,
C<Access-Control-Allow-Methods>).

=head1 ACCESSORS

=head2 name

Relay name (SHOULD be less than 30 characters).

=head2 description

Relay description.

=head2 banner

Banner image URL.

=head2 icon

Icon image URL.

=head2 pubkey

Admin contact pubkey (64-char lowercase hex).

=head2 self

Relay's own pubkey (64-char lowercase hex).

=head2 contact

Admin contact URI (e.g. C<mailto:admin@example.com>).

=head2 supported_nips

Arrayref of supported NIP numbers.

=head2 software

URL of the relay software project.

=head2 version

Relay software version string.

=head2 terms_of_service

URL of terms of service.

=head2 limitation

Hashref of relay limitations (see L</new> for supported keys).

=head2 payments_url

URL for relay payment information.

=head2 fees

Hashref of fee schedules (see L</new> for structure).

=head1 SEE ALSO

L<NIP-11|https://github.com/nostr-protocol/nips/blob/master/11.md>,
L<Net::Nostr>, L<Net::Nostr::Relay>

=cut
