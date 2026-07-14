package Net::Blossom::Client;

use strictures 2;

use Net::Blossom::_ConstructorArgs ();
use Net::Blossom::BlobDescriptor;
use Net::Blossom::Error;
use Net::Blossom::PaymentRequired;
use Net::Blossom::Response;
use Net::Blossom::ServerList;
use Net::Blossom::_Bech32 ();
use Net::Blossom::_CashuPaymentRequest ();
use Net::Blossom::_URL ();

use Carp qw(croak);
use Class::Tiny qw(server auth), {
    ua => sub { HTTP::Tiny->new },
};
use Digest::SHA qw(sha256_hex);
use HTTP::Tiny;
use JSON ();
use Net::Nostr::Zap qw(bolt11_amount);
use Scalar::Util qw(blessed);

my $HEX64 = qr/\A[0-9a-f]{64}\z/;
my $HEX128 = qr/\A[0-9a-f]{128}\z/;
my $JSON = JSON->new->utf8;
my $CANONICAL_JSON = JSON->new->utf8->canonical;
my %RESERVED_PAYMENT_METHOD = map { $_ => 1 } qw(reason sha-256 content-type content-length);

sub BUILDARGS {
    my $class = shift;
    my %args = Net::Blossom::_ConstructorArgs::normalize(@_);
    my %known = map { $_ => 1 } qw(server ua auth);
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return \%args;
}

sub BUILD {
    my ($self) = @_;
    croak "server is required" unless defined $self->server && length $self->server;
    croak "server must be an http(s) base URL" if ref($self->server);
    croak "server must be an http(s) base URL" unless _valid_server_url($self->server);

    (my $server = $self->server) =~ s{/+\z}{};
    $self->server($server);
    $self->ua(HTTP::Tiny->new) unless defined $self->ua;
    return;
}

sub get_blob {
    my $self = shift;
    my ($sha256, %opts) = @_;
    _validate_options(\%opts, qw(extension range payment));
    _validate_sha256($sha256);

    my %headers;
    $headers{Range} = $opts{range} if defined $opts{range};

    return $self->_request(
        method  => 'GET',
        path    => $self->_blob_path($sha256, $opts{extension}),
        headers => \%headers,
        action  => 'get',
        sha256  => $sha256,
        payment => $opts{payment},
        ok      => { map { $_ => 1 } qw(200 206 307 308) },
    );
}

sub head_blob {
    my $self = shift;
    my ($sha256, %opts) = @_;
    _validate_options(\%opts, qw(extension payment));
    _validate_sha256($sha256);

    return $self->_request(
        method => 'HEAD',
        path   => $self->_blob_path($sha256, $opts{extension}),
        action => 'get',
        sha256 => $sha256,
        payment => $opts{payment},
        ok     => { map { $_ => 1 } qw(200 307 308) },
    );
}

sub upload_blob {
    my $self = shift;
    my ($content, %opts) = @_;
    _validate_options(\%opts, qw(type payment));
    croak "content is required" unless defined $content;

    my $sha256 = sha256_hex($content);
    my %headers = (
        'Content-Type'   => $opts{type} || 'application/octet-stream',
        'Content-Length' => length($content),
        'X-SHA-256'      => $sha256,
    );

    my $response = $self->_request(
        method  => 'PUT',
        path    => '/upload',
        headers => \%headers,
        content => $content,
        action  => 'upload',
        sha256  => $sha256,
        payment => $opts{payment},
        ok      => { 200 => 1, 201 => 1 },
    );

    return Net::Blossom::BlobDescriptor->from_hash(_decode_json_hash($response->content));
}

sub head_upload {
    my $self = shift;
    my ($content, %opts) = @_;
    _validate_options(\%opts, qw(type payment));
    croak "content is required" unless defined $content;

    my $sha256 = sha256_hex($content);
    my %headers = (
        'X-SHA-256'        => $sha256,
        'X-Content-Type'   => $opts{type} || 'application/octet-stream',
        'X-Content-Length' => length($content),
    );

    return $self->_request(
        method  => 'HEAD',
        path    => '/upload',
        headers => \%headers,
        action  => 'upload',
        sha256  => $sha256,
        payment => $opts{payment},
        ok      => { 200 => 1 },
    );
}

sub process_media {
    my $self = shift;
    my ($content, %opts) = @_;
    _validate_options(\%opts, qw(type payment));
    croak "content is required" unless defined $content;

    my $sha256 = sha256_hex($content);
    my %headers = (
        'Content-Type'   => $opts{type} || 'application/octet-stream',
        'Content-Length' => length($content),
        'X-SHA-256'      => $sha256,
    );

    my $response = $self->_request(
        method  => 'PUT',
        path    => '/media',
        headers => \%headers,
        content => $content,
        action  => 'media',
        sha256  => $sha256,
        payment => $opts{payment},
        ok      => { 200 => 1, 201 => 1 },
    );

    return Net::Blossom::BlobDescriptor->from_hash(_decode_json_hash($response->content));
}

sub head_media {
    my $self = shift;
    my ($content, %opts) = @_;
    _validate_options(\%opts, qw(type payment));
    croak "content is required" unless defined $content;

    my $sha256 = sha256_hex($content);
    my %headers = (
        'X-SHA-256'        => $sha256,
        'X-Content-Type'   => $opts{type} || 'application/octet-stream',
        'X-Content-Length' => length($content),
    );

    return $self->_request(
        method  => 'HEAD',
        path    => '/media',
        headers => \%headers,
        action  => 'media',
        sha256  => $sha256,
        payment => $opts{payment},
        ok      => { 200 => 1 },
    );
}

sub upload_blob_to_servers {
    my $self = shift;
    my ($content, $servers, %opts) = @_;
    _validate_options(\%opts, qw(type payment));
    my @servers = _server_values($servers);

    return $self->_client_for_server($servers[0])->upload_blob($content, %opts);
}

sub mirror_blob {
    my $self = shift;
    my ($url, %opts) = @_;
    _validate_options(\%opts, qw(payment));
    croak "url is required" unless defined $url && length $url;
    croak "url must be a string" if ref($url);

    my $content = $CANONICAL_JSON->encode({ url => $url });
    my %headers = (
        'Content-Type'   => 'application/json',
        'Content-Length' => length($content),
    );
    my ($sha256) = Net::Blossom::ServerList->extract_blob_reference($url);

    my $response = $self->_request(
        method  => 'PUT',
        path    => '/mirror',
        headers => \%headers,
        content => $content,
        action  => 'upload',
        sha256  => $sha256,
        payment => $opts{payment},
        ok      => { 200 => 1, 201 => 1 },
    );

    return Net::Blossom::BlobDescriptor->from_hash(_decode_json_hash($response->content));
}

sub report_blob {
    my $self = shift;
    my ($event, %opts) = @_;
    _validate_options(\%opts, qw(payment));
    _validate_report_event($event);

    my $content = $CANONICAL_JSON->encode(_report_event_wire_form($event));
    my %headers = (
        'Content-Type'   => 'application/json',
        'Content-Length' => length($content),
    );

    return $self->_request(
        method  => 'PUT',
        path    => '/report',
        headers => \%headers,
        content => $content,
        action  => 'report',
        payment => $opts{payment},
        ok      => { map { $_ => 1 } 200 .. 299 },
    );
}

sub list_blobs {
    my $self = shift;
    my ($pubkey, %opts) = @_;
    _validate_options(\%opts, qw(cursor limit since until payment));
    croak "pubkey must be 64-char lowercase hex" unless defined $pubkey && $pubkey =~ $HEX64;

    my @query;
    for my $field (qw(cursor limit since until)) {
        next unless defined $opts{$field};
        push @query, _uri_escape($field) . '=' . _uri_escape($opts{$field});
    }

    my $path = "/list/$pubkey";
    $path .= '?' . join('&', @query) if @query;

    my $response = $self->_request(
        method => 'GET',
        path   => $path,
        action => 'list',
        payment => $opts{payment},
        ok     => { 200 => 1 },
    );

    my $data = _decode_json($response->content);
    croak "list response must be a JSON array" unless ref($data) eq 'ARRAY';
    return [map { Net::Blossom::BlobDescriptor->from_hash($_) } @$data];
}

sub delete_blob {
    my $self = shift;
    my ($sha256, %opts) = @_;
    _validate_options(\%opts, qw(payment));
    _validate_sha256($sha256);

    return $self->_request(
        method => 'DELETE',
        path   => "/$sha256",
        action => 'delete',
        sha256 => $sha256,
        payment => $opts{payment},
        ok     => { 200 => 1, 204 => 1 },
    );
}

sub get_blob_from_servers {
    my $self = shift;
    my ($url, $servers, %opts) = @_;
    _validate_options(\%opts, qw(extension range payment));
    my ($sha256, $extension) = Net::Blossom::ServerList->extract_blob_reference($url);
    croak "URL does not contain a sha256 hash" unless defined $sha256;

    my @servers = _server_values($servers);
    my $last_error;

    for my $server (@servers) {
        my %get_opts = %opts;
        $get_opts{extension} = $extension
            if defined $extension && !defined $get_opts{extension};

        my $response = eval {
            $self->_client_for_server($server)->get_blob($sha256, %get_opts);
        };
        return $response unless $@;

        my $error = $@;
        die $error unless ref($error) && eval { $error->isa('Net::Blossom::Error') };
        $last_error = $error;
    }

    die $last_error if defined $last_error;
    croak "server list must contain at least one server";
}

sub _request {
    my $self = shift;
    my %args = @_;
    my $method = $args{method};
    my $url = $self->server . $args{path};
    my %headers = %{ $args{headers} || {} };

    if (defined $args{payment}) {
        croak "payment proof headers are not allowed on HEAD requests"
            if $method eq 'HEAD';
        my %payment_headers = _payment_headers($args{payment});
        @headers{keys %payment_headers} = values %payment_headers;
    }

    if (my $authorization = $self->_authorization_header(%args, url => $url)) {
        $headers{Authorization} = $authorization;
    }

    my %request = (headers => \%headers);
    $request{content} = $args{content} if exists $args{content};

    my $raw = $self->ua->request($method, $url, \%request);
    my $response = Net::Blossom::Response->new(
        method  => $method,
        url     => $url,
        status  => $raw->{status},
        reason  => $raw->{reason},
        headers => $raw->{headers} || {},
        content => $raw->{content},
    );

    my $ok = $args{ok} || {};
    return $response if $ok->{$response->status};

    if ($response->status == 402) {
        die Net::Blossom::PaymentRequired->new(
            method             => $method,
            url                => $url,
            status             => $response->status,
            reason             => $response->reason,
            x_reason           => $response->header('x-reason'),
            headers            => $response->headers,
            body               => $response->content,
            payment_challenges => _payment_challenges($response->headers),
        );
    }

    die Net::Blossom::Error->new(
        method   => $method,
        url      => $url,
        status   => $response->status,
        reason   => $response->reason,
        x_reason => $response->header('x-reason'),
        headers  => $response->headers,
        body     => $response->content,
    );
}

sub _client_for_server {
    my ($self, $server) = @_;
    return ref($self)->new(
        server => $server,
        ua     => $self->ua,
        auth   => $self->auth,
    );
}

sub _authorization_header {
    my $self = shift;
    my %args = @_;
    return undef unless defined $self->auth;
    return $self->auth unless ref $self->auth;
    my %context = (
        method => $args{method},
        url    => $args{url},
        action => $args{action},
        sha256 => $args{sha256},
    );

    return $self->auth->(%context) if ref($self->auth) eq 'CODE';

    if (blessed($self->auth) && $self->auth->can('authorization_header')) {
        # A fixed-action token (e.g. Net::Blossom::AuthToken) carries a single
        # BUD-11 't' verb. Sending it on an endpoint with a different action
        # produces an authorization event every conformant server rejects, and
        # leaks the token's capability onto that request, so refuse the mismatch.
        if ($self->auth->can('action')) {
            my $token_action = $self->auth->action;
            if (defined $token_action
                && defined $context{action}
                && $token_action ne $context{action}) {
                croak "auth token action '$token_action' does not match "
                    . "request action '$context{action}'";
            }
        }
        return $self->auth->authorization_header(%context);
    }

    croak "auth must be a string, code reference, or object with authorization_header";
}

sub _server_values {
    my ($servers) = @_;
    croak "servers are required" unless defined $servers;

    return @{$servers->servers}
        if ref($servers) && eval { $servers->isa('Net::Blossom::ServerList') };

    croak "servers must be a Net::Blossom::ServerList or array reference"
        unless ref($servers) eq 'ARRAY';

    return @{Net::Blossom::ServerList->new(servers => $servers)->servers};
}

sub _payment_headers {
    my ($payment) = @_;
    croak "payment must be a hash reference" unless ref($payment) eq 'HASH';

    my %headers;
    for my $method (sort keys %$payment) {
        my $normalized = _normalize_payment_method($method);
        my $proof = $payment->{$method};
        croak "payment proof for $normalized is required"
            unless defined $proof && length $proof;
        croak "payment proof for $normalized must be a scalar" if ref($proof);
        $headers{_payment_header_name($normalized)} = $proof;
    }

    croak "payment requires at least one proof" unless %headers;
    return %headers;
}

sub _validate_options {
    my ($opts, @known) = @_;
    my %known = map { $_ => 1 } @known;
    my @unknown = grep { !exists $known{$_} } keys %$opts;
    croak "unknown option(s): " . join(', ', sort @unknown) if @unknown;
}

sub _payment_challenges {
    my ($headers) = @_;
    my %challenges;

    for my $header (sort keys %{$headers || {}}) {
        next unless $header =~ /\AX-/i;
        my $method = _payment_challenge_method($header);
        next unless defined $method;
        my $payload = $headers->{$header};
        next if ref($payload);
        next unless defined $payload && length $payload;
        next unless _valid_payment_challenge($method, $payload);
        $challenges{$method} = $payload;
    }

    return \%challenges;
}

sub _valid_payment_challenge {
    my ($method, $payload) = @_;
    return Net::Blossom::_CashuPaymentRequest::valid($payload) if $method eq 'cashu';
    return _valid_lightning_challenge($payload) if $method eq 'lightning';
    return 1;
}

sub _valid_lightning_challenge {
    my ($payload) = @_;
    my ($hrp) = Net::Blossom::_Bech32::decode($payload, 1);
    return 0 unless defined $hrp && $hrp =~ /\Aln(?:bc|tb|bcrt|sb)(?:\d+[munp]?)?\z/;
    return eval { bolt11_amount(lc $payload); 1 } ? 1 : 0;
}

sub _payment_challenge_method {
    my ($method) = @_;
    return undef unless defined $method && length $method;
    $method =~ s/\AX-//i;
    return undef unless $method =~ /\A[A-Za-z0-9][A-Za-z0-9-]*\z/;

    my $normalized = lc $method;
    return undef if $RESERVED_PAYMENT_METHOD{$normalized};
    return $normalized;
}

sub _normalize_payment_method {
    my ($method) = @_;
    croak "payment method is required" unless defined $method && length $method;
    $method =~ s/\AX-//i;
    croak "payment method must be an X- header token"
        unless $method =~ /\A[A-Za-z0-9][A-Za-z0-9-]*\z/;

    my $normalized = lc $method;
    croak "payment method $normalized is reserved"
        if $RESERVED_PAYMENT_METHOD{$normalized};
    return $normalized;
}

sub _payment_header_name {
    my ($method) = @_;
    return 'X-' . join '-', map { ucfirst lc $_ } split /-/, $method;
}

sub _blob_path {
    my ($self, $sha256, $extension) = @_;
    return "/$sha256" unless defined $extension && length $extension;
    croak "extension must contain only letters and digits"
        unless $extension =~ /\A[A-Za-z0-9]+\z/;
    return "/$sha256.$extension";
}

sub _validate_sha256 {
    my ($sha256) = @_;
    croak "sha256 must be 64-char lowercase hex"
        unless defined $sha256 && $sha256 =~ $HEX64;
}

sub _report_event_wire_form {
    my ($event) = @_;

    # The event is already signed, so it must go on the wire with the JSON
    # types NIP-01/NIP-56 define regardless of how the caller typed the fields
    # in memory: kind and created_at are numbers, tag values are strings.
    # Re-encoding a numeric field as a string (or vice versa) changes the
    # serialization the signature was computed over and breaks verification.
    my %wire = %$event;
    $wire{kind}       = 0 + $wire{kind};
    $wire{created_at} = 0 + $wire{created_at};
    $wire{content}    = "$wire{content}" if defined $wire{content};
    $wire{tags}       = [map { [map { "$_" } @$_] } @{$wire{tags}}];

    return \%wire;
}

sub _validate_report_event {
    my ($event) = @_;
    croak "report event must be a hash reference" unless ref($event) eq 'HASH';

    _validate_report_hex_field($event, 'id', $HEX64, '64-char lowercase hex');
    _validate_report_hex_field($event, 'pubkey', $HEX64, '64-char lowercase hex');
    _validate_report_hex_field($event, 'sig', $HEX128, '128-char lowercase hex');

    croak "report event created_at must be a non-negative integer"
        unless defined $event->{created_at} && !ref($event->{created_at})
            && $event->{created_at} =~ /\A\d+\z/;
    croak "report event kind must be 1984"
        unless defined $event->{kind} && !ref($event->{kind})
            && $event->{kind} =~ /\A1984\z/;
    croak "report event content must be a scalar"
        unless defined $event->{content} && !ref($event->{content});
    croak "report event tags must be an array reference"
        unless ref($event->{tags}) eq 'ARRAY';

    my $has_x;
    for my $tag (@{$event->{tags}}) {
        croak "report event tags must be array references" unless ref($tag) eq 'ARRAY';
        croak "report event tag values must be defined" if grep { !defined $_ } @$tag;
        croak "report event tag values must be scalars" if grep { ref($_) } @$tag;

        next unless @$tag && $tag->[0] eq 'x';
        croak "report x tags must contain a sha256 hash" unless @$tag >= 2;
        croak "report x tag hash must be 64-char lowercase hex"
            unless $tag->[1] =~ $HEX64;
        $has_x = 1;
    }

    croak "report event must contain at least one x tag" unless $has_x;
}

sub _validate_report_hex_field {
    my ($event, $field, $regex, $description) = @_;
    croak "report event $field must be $description"
        unless defined $event->{$field} && !ref($event->{$field})
            && $event->{$field} =~ $regex;
}

sub _decode_json_hash {
    my ($content) = @_;
    my $data = _decode_json($content);
    croak "response body must be a JSON object" unless ref($data) eq 'HASH';
    return $data;
}

sub _decode_json {
    my ($content) = @_;
    my $data = eval { $JSON->decode($content) };
    croak "invalid JSON response: $@" if $@;
    return $data;
}

sub _uri_escape {
    my ($value) = @_;
    $value = "$value";
    $value =~ s/([^A-Za-z0-9_.~-])/sprintf("%%%02X", ord($1))/ge;
    return $value;
}

sub _valid_server_url {
    my ($server) = @_;
    return Net::Blossom::_URL::http_base_url($server);
}

1;

=pod

=head1 NAME

Net::Blossom::Client - HTTP client for Blossom servers

=head1 SYNOPSIS

    use Net::Blossom::Client;

    my $client = Net::Blossom::Client->new(
        server => 'https://cdn.example.com',
        auth   => sub {
            my %ctx = @_;
            return build_authorization_header(%ctx);
        },
    );

    my $response = $client->get_blob($sha256);
    my $blob     = $client->upload_blob($bytes, type => 'image/png');
    my $blobs    = $client->list_blobs($pubkey, limit => 20);

=head1 DESCRIPTION

C<Net::Blossom::Client> sends HTTP requests to one Blossom server. It implements
client support for the currently supported Blossom BUDs in this distribution,
including blob get/head/upload/delete, mirror requests, media processing,
upload/media preflights, blob reports, payment challenge handling, server-list
fallback helpers, and list pagination.

Methods croak for invalid local arguments and unknown options. Non-success HTTP
responses die with C<Net::Blossom::Error>. C<402 Payment Required> responses die
with C<Net::Blossom::PaymentRequired>.

=head1 CONSTRUCTOR

=head2 new

    my $client = Net::Blossom::Client->new(%args);

Required arguments:

=over 4

=item * C<server>

The Blossom server HTTP or HTTPS base URL. Query strings, fragments, and userinfo
are rejected. A path prefix is allowed. Trailing slashes are removed.

=back

Optional arguments:

=over 4

=item * C<ua>

HTTP user agent object. Defaults to C<HTTP::Tiny-E<gt>new>. The object must
provide C<request($method, $url, \%opts)> and return a hash reference with
C<status>, C<reason>, C<headers>, and C<content>.

=item * C<auth>

Authorization provider. It may be a static C<Authorization> header string, a
code reference, or an object with C<authorization_header(%context)>.

Code references and objects receive C<method>, C<url>, C<action>, and C<sha256>.
They must return the header value or C<undef> to omit authorization.

When the provider object exposes an C<action> accessor (as
C<Net::Blossom::AuthToken> does), its action must match the request's action.
A single fixed-action token cannot be reused across endpoints: a mismatch
croaks rather than send a token whose BUD-11 C<t> verb the server would reject.

=back

Unknown arguments or a missing C<server> croak.

=head1 ACCESSORS

=head2 server

Returns the normalized server base URL.

=head2 ua

Returns the user agent object.

=head2 auth

Returns the configured authorization provider.

=head1 METHODS

=head2 get_blob

    my $response = $client->get_blob($sha256, %opts);

Sends C<GET /<sha256>> and returns a C<Net::Blossom::Response>. Success statuses
are C<200>, C<206>, C<307>, and C<308>.

Options:

=over 4

=item * C<extension>

Appends C<.$extension> to the request path. The extension must contain only
letters and digits.

=item * C<range>

Sends a C<Range> header.

=item * C<payment>

Hash reference of payment proof headers. See L</PAYMENT PROOFS>.

=back

=head2 head_blob

    my $response = $client->head_blob($sha256, %opts);

Sends C<HEAD /<sha256>> and returns a C<Net::Blossom::Response>. Success
statuses are C<200>, C<307>, and C<308>. Accepts the C<extension> option.
C<payment> is rejected because proof headers are not allowed on C<HEAD>
requests.

=head2 upload_blob

    my $descriptor = $client->upload_blob($content, %opts);

Sends C<PUT /upload> with the exact byte string in C<$content>. Returns a
C<Net::Blossom::BlobDescriptor> parsed from the JSON response. Success statuses
are C<200> and C<201>.

Options:

=over 4

=item * C<type>

Media type for C<Content-Type>. Defaults to C<application/octet-stream>.

=item * C<payment>

Hash reference of payment proof headers. See L</PAYMENT PROOFS>.

=back

=head2 head_upload

    my $response = $client->head_upload($content, %opts);

Sends C<HEAD /upload> preflight headers for the given content and returns a
C<Net::Blossom::Response>. Success status is C<200>. C<payment> is not allowed
on C<HEAD> requests.

The C<type> option sets C<X-Content-Type> and defaults to
C<application/octet-stream>.

=head2 process_media

    my $descriptor = $client->process_media($content, %opts);

Sends C<PUT /media> and returns a C<Net::Blossom::BlobDescriptor>. Success
statuses are C<200> and C<201>. Options match C<upload_blob>.

=head2 head_media

    my $response = $client->head_media($content, %opts);

Sends C<HEAD /media> preflight headers and returns a
C<Net::Blossom::Response>. Success status is C<200>. C<payment> is not allowed
on C<HEAD> requests.

The C<type> option sets C<X-Content-Type> and defaults to
C<application/octet-stream>.

=head2 upload_blob_to_servers

    my $descriptor = $client->upload_blob_to_servers($content, $servers, %opts);

Uploads to the first server in C<$servers>. C<$servers> may be a
C<Net::Blossom::ServerList> or an array reference of server base URLs. Options
are passed to C<upload_blob>.

=head2 mirror_blob

    my $descriptor = $client->mirror_blob($url, %opts);

Sends C<PUT /mirror> with a canonical JSON body containing C<url>. Returns a
C<Net::Blossom::BlobDescriptor>. Success statuses are C<200> and C<201>.

If the source URL contains a SHA-256 hash, that hash is passed to the auth
provider as request context.

=head2 report_blob

    my $response = $client->report_blob($event, %opts);

Sends C<PUT /report> with a NIP-56 report event hash reference. Returns a
C<Net::Blossom::Response>. Any C<2xx> status is treated as success.

The report event is validated locally. It must be kind C<1984>, include
lowercase hex C<id>, C<pubkey>, and C<sig> fields, include scalar C<content>,
include a non-negative integer C<created_at>, and contain at least one C<x> tag
with a lowercase SHA-256 hash.

=head2 list_blobs

    my $descriptors = $client->list_blobs($pubkey, %opts);

Sends C<GET /list/<pubkey>> and returns an array reference of
C<Net::Blossom::BlobDescriptor> objects. C<$pubkey> must be lowercase
64-character hex.

Options C<cursor>, C<limit>, C<since>, and C<until> are sent as query
parameters when defined.

=head2 delete_blob

    my $response = $client->delete_blob($sha256, %opts);

Sends C<DELETE /<sha256>> and returns a C<Net::Blossom::Response>. Success
statuses are C<200> and C<204>. Accepts the C<payment> option.

=head2 get_blob_from_servers

    my $response = $client->get_blob_from_servers($url, $servers, %opts);

Extracts the last SHA-256 hash from C<$url> and tries C<get_blob> against each
server in order until one succeeds. C<$servers> may be a
C<Net::Blossom::ServerList> or an array reference of server base URLs.

If all servers return Blossom HTTP errors, the last C<Net::Blossom::Error> is
re-thrown. Non-Blossom exceptions are re-thrown immediately.

=head1 PAYMENT PROOFS

C<GET>, C<PUT>, and C<DELETE> methods accept C<payment =E<gt> \%proofs>. Keys
are payment method names such as C<cashu> or C<lightning>, optionally with an
C<X-> prefix. Values are scalar proof strings. The client sends them as
C<X-Cashu>, C<X-Lightning>, or the matching C<X-*> header.

Reserved payment method names C<reason>, C<sha-256>, C<content-type>, and
C<content-length> are rejected.

=head1 ERRORS

Invalid local arguments and unknown method options croak. Failed HTTP responses
die with C<Net::Blossom::Error>. Payment challenges die with
C<Net::Blossom::PaymentRequired>.

Malformed JSON success bodies also croak.

=head1 SEE ALSO

L<Net::Blossom::AuthToken>, L<Net::Blossom::BlobDescriptor>,
L<Net::Blossom::Error>, L<Net::Blossom::PaymentRequired>,
L<Net::Blossom::Response>, L<Net::Blossom::ServerList>

=head1 INTERNAL METHODS

=head2 BUILDARGS

Normalizes constructor arguments for Class::Tiny.

=head2 BUILD

Validates the constructed object for Class::Tiny.

=cut
