package Net::IPData;

use strict;
use warnings;
use 5.010001;

our $VERSION = '1.1.0';

use HTTP::Tiny;
use JSON::PP qw(encode_json);
use Carp qw(croak);
use Scalar::Util qw(blessed);

# API base URLs
use constant {
    BASE_URL    => 'https://api.ipdata.co',
    EU_BASE_URL => 'https://eu-api.ipdata.co',
    MAX_BULK    => 100,
};

# Single-field lookups (/{ip}/{field}) answer with a bare JSON value: a
# string, a number, true, false or null. JSON::PP before 4.0 rejects such a
# top-level scalar unless allow_nonref is set, hence one configured decoder
# instead of decode_json.
my $JSON = JSON::PP->new->utf8->allow_nonref;

# Valid top-level fields for filtering
my %VALID_FIELDS = map { $_ => 1 } qw(
    ip is_eu is_satellite is_anycast city region region_code region_type
    country_name country_code continent_name continent_code
    latitude longitude postal calling_code flag
    emoji_flag emoji_unicode asn company carrier
    languages currency time_zone threat count status message
);

# Valid single-field path lookups (fields accessible via /{ip}/{field})
my %PATH_FIELDS = map { $_ => 1 } qw(
    ip is_eu is_satellite is_anycast city region region_code region_type
    country_name country_code continent_name continent_code
    latitude longitude postal calling_code flag
    emoji_flag emoji_unicode asn carrier languages
    currency time_zone threat
);

sub new {
    my ($class, %args) = @_;

    my $api_key = $args{api_key}
        or croak 'Required parameter "api_key" is missing';

    my $base_url = $args{base_url};
    if ($args{eu} && !$base_url) {
        $base_url = EU_BASE_URL;
    }
    $base_url //= BASE_URL;
    $base_url =~ s{/+$}{};  # strip trailing slashes

    my $timeout            = $args{timeout} // 30;
    my $keep_alive         = $args{keep_alive} // 1;
    my $keep_alive_timeout = $args{keep_alive_timeout};
    my $verify_ssl         = ($args{verify_ssl} // 1) ? 1 : 0;

    # One user agent per Net::IPData object: it owns the kept-alive HTTPS
    # connection, so building it once here (and never per request) is what
    # amortises the TCP+TLS handshake across lookups.
    my $ua = $args{ua};
    if (defined $ua) {
        croak 'Parameter "ua" must be an object with "get" and "post" methods'
            unless blessed($ua) && $ua->can('get') && $ua->can('post');
    }
    else {
        $ua = HTTP::Tiny->new(
            agent           => "ipdata-perl/$VERSION",
            timeout         => $timeout,
            keep_alive      => $keep_alive,
            # Always passed explicitly: HTTP::Tiny before 0.083 verifies the
            # server certificate only when asked to, and from 0.083 on its
            # default can be switched off by an environment variable.
            verify_SSL      => $verify_ssl,
            # Forwarded only when the caller asked for one, so HTTP::Tiny's
            # own default (no idle limit) applies otherwise; HTTP::Tiny
            # before 0.092 has no such setting and ignores the key.
            (defined $keep_alive_timeout
                ? (keep_alive_timeout => $keep_alive_timeout)
                : ()),
            # Content-Type belongs to the one request with a body, the bulk
            # POST, which adds it itself (see _post_options).
            default_headers => { Accept => 'application/json' },
        );
        # HTTP::Tiny 0.092 and later document keep_alive_timeout as a
        # constructor attribute, but their constructor (checked up to 0.096)
        # never copies the argument into the object, so set the attribute
        # directly where it exists.
        if (defined $keep_alive_timeout && eval { HTTP::Tiny->VERSION('0.092') }) {
            $ua->{keep_alive_timeout} = $keep_alive_timeout;
        }
    }

    return bless {
        api_key            => $api_key,
        base_url           => $base_url,
        ua                 => $ua,
        timeout            => $timeout,
        keep_alive         => $keep_alive,
        keep_alive_timeout => $keep_alive_timeout,
        verify_ssl         => $verify_ssl,
    }, $class;
}

# --- Public Methods ---

sub lookup {
    my ($self, $ip, %opts) = @_;

    my $path = defined $ip && length $ip ? "/$ip" : '';
    my @params;

    if (my $fields = $opts{fields}) {
        my @field_list = ref $fields eq 'ARRAY' ? @$fields : split(/\s*,\s*/, $fields);
        _validate_fields(\@field_list);
        push @params, 'fields=' . join(',', @field_list);
    }

    my $url = $self->_build_url($path, @params);
    return $self->_get($url);
}

sub lookup_mine {
    my ($self, %opts) = @_;
    return $self->lookup(undef, %opts);
}

sub lookup_field {
    my ($self, $ip, $field) = @_;

    croak 'Required parameter "ip" is missing'    unless defined $ip && length $ip;
    croak 'Required parameter "field" is missing'  unless defined $field && length $field;
    croak "Invalid field: $field" unless $PATH_FIELDS{$field};

    my $url = $self->_build_url("/$ip/$field");
    return $self->_get($url);
}

sub bulk {
    my ($self, $ips, %opts) = @_;

    croak 'Required parameter "ips" must be an array reference'
        unless ref $ips eq 'ARRAY';
    croak 'Bulk lookup supports a maximum of ' . MAX_BULK . ' IP addresses'
        if @$ips > MAX_BULK;
    croak 'Bulk lookup requires at least one IP address'
        if @$ips == 0;

    my @params;
    if (my $fields = $opts{fields}) {
        my @field_list = ref $fields eq 'ARRAY' ? @$fields : split(/\s*,\s*/, $fields);
        _validate_fields(\@field_list);
        push @params, 'fields=' . join(',', @field_list);
    }

    my $url = $self->_build_url('/bulk', @params);
    return $self->_post($url, $ips);
}

sub asn {
    my ($self, $ip) = @_;
    return $self->lookup_field($ip, 'asn');
}

sub threat {
    my ($self, $ip) = @_;
    return $self->lookup_field($ip, 'threat');
}

sub carrier {
    my ($self, $ip) = @_;
    return $self->lookup_field($ip, 'carrier');
}

sub currency {
    my ($self, $ip) = @_;
    return $self->lookup_field($ip, 'currency');
}

sub time_zone {
    my ($self, $ip) = @_;
    return $self->lookup_field($ip, 'time_zone');
}

sub languages {
    my ($self, $ip) = @_;
    return $self->lookup_field($ip, 'languages');
}

sub country_name {
    my ($self, $ip) = @_;
    return $self->lookup_field($ip, 'country_name');
}

sub country_code {
    my ($self, $ip) = @_;
    return $self->lookup_field($ip, 'country_code');
}

sub is_eu {
    my ($self, $ip) = @_;
    return $self->lookup_field($ip, 'is_eu');
}

sub is_satellite {
    my ($self, $ip) = @_;
    return $self->lookup_field($ip, 'is_satellite');
}

sub is_anycast {
    my ($self, $ip) = @_;
    return $self->lookup_field($ip, 'is_anycast');
}

# --- Accessors ---

sub api_key            { return $_[0]->{api_key} }
sub base_url           { return $_[0]->{base_url} }
sub timeout            { return $_[0]->{timeout} }
sub keep_alive         { return $_[0]->{keep_alive} }
sub keep_alive_timeout { return $_[0]->{keep_alive_timeout} }
sub verify_ssl         { return $_[0]->{verify_ssl} }
sub ua                 { return $_[0]->{ua} }

# --- Private Methods ---

sub _build_url {
    my ($self, $path, @params) = @_;

    unshift @params, 'api-key=' . $self->{api_key};
    my $query = join('&', @params);

    return $self->{base_url} . ($path // '') . '?' . $query;
}

sub _get {
    my ($self, $url) = @_;

    my $response = $self->{ua}->get($url);
    return $self->_handle_response($response);
}

sub _post {
    my ($self, $url, $data) = @_;

    my $body     = encode_json($data);
    my $response = $self->{ua}->post($url, _post_options($body));

    # A kept-alive connection can be closed by the server while idle.
    # HTTP::Tiny retries idempotent methods on such a socket itself but never
    # a POST, so retry exactly once when the failure was at the socket level
    # (status 599) rather than an HTTP status. HTTP::Tiny has already dropped
    # the dead connection by then, so the retry opens a fresh one.
    if (_is_stale_connection_error($response)) {
        $response = $self->{ua}->post($url, _post_options($body));
    }

    return $self->_handle_response($response);
}

# Options for the bulk POST: the JSON body and its Content-Type, which only
# a request with a body sends. A fresh hashref per attempt, as HTTP::Tiny
# adds bookkeeping keys to the one it is given.
sub _post_options {
    my ($body) = @_;
    return { content => $body, headers => { 'Content-Type' => 'application/json' } };
}

# True for the status-599 pseudo-responses HTTP::Tiny returns when a reused
# socket turned out to be dead; never true for a real HTTP status.
sub _is_stale_connection_error {
    my ($response) = @_;

    return 0 unless ($response->{status} // 0) == 599;
    my $content = $response->{content} // '';
    return $content =~ /Socket closed|Unexpected end of stream|Connection reset/ ? 1 : 0;
}

sub _handle_response {
    my ($self, $response) = @_;

    my $status  = $response->{status};
    my $content = $response->{content} // '';

    # Network-level failures from HTTP::Tiny (status 599)
    if ($status == 599) {
        croak "Network error: $content";
    }

    # Decode the JSON, including the bare scalar a single-field lookup returns
    my $data;
    eval { $data = $JSON->decode($content); };
    if ($@) {
        # Not JSON at all (for example an HTML error page): return or report
        # the trimmed text
        $content =~ s/^\s+|\s+$//g;    # trim whitespace
        $content =~ s/^"|"$//g;        # strip surrounding quotes

        if ($status >= 200 && $status < 300) {
            return $content;
        }
        croak "HTTP $status: $content";
    }

    # API error responses include a "message" field
    if ($status >= 400) {
        my $message = $data->{message} // "HTTP $status error";
        croak "API error ($status): $message";
    }

    return $data;
}

sub _validate_fields {
    my ($fields) = @_;
    for my $f (@$fields) {
        croak "Invalid field: $f" unless $VALID_FIELDS{$f};
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Net::IPData - Perl client for the ipdata.co IP geolocation and threat intelligence API

=head1 SYNOPSIS

    use Net::IPData;

    my $ipdata = Net::IPData->new(api_key => 'YOUR_API_KEY');

    # Look up a specific IP address
    my $result = $ipdata->lookup('8.8.8.8');
    printf "IP: %s, Country: %s, City: %s\n",
        $result->{ip}, $result->{country_name}, $result->{city};

    # Flags the API includes only when true (a missing key reads as false)
    print "satellite ISP\n"    if $result->{is_satellite};
    print "anycast address\n"  if $result->{is_anycast};

    # Look up your own IP address
    my $me = $ipdata->lookup_mine();

    # Request only specific fields
    my $partial = $ipdata->lookup('8.8.8.8', fields => [qw(ip country_name asn)]);

    # Bulk lookup (up to 100 IPs)
    my $results = $ipdata->bulk(['8.8.8.8', '1.1.1.1']);

    # Get a single field directly
    my $asn = $ipdata->asn('8.8.8.8');
    my $threat = $ipdata->threat('8.8.8.8');
    my $country = $ipdata->country_name('8.8.8.8');

    # Use the EU endpoint for GDPR compliance
    my $eu = Net::IPData->new(api_key => 'YOUR_API_KEY', eu => 1);

=head1 DESCRIPTION

Net::IPData provides a Perl interface to the ipdata.co API, which offers
IP geolocation, ASN, company, carrier, threat intelligence, currency,
timezone, and language data for any IPv4 or IPv6 address.

This module uses only Perl core modules (L<HTTP::Tiny>, L<JSON::PP>) and
has no non-core dependencies.

=head1 CONSTRUCTOR

=head2 new

    my $ipdata = Net::IPData->new(
        api_key            => 'YOUR_API_KEY',   # required
        eu                 => 0,                # use EU endpoint (default: 0)
        base_url           => '...',            # custom base URL (overrides eu)
        timeout            => 30,               # HTTP timeout in seconds (default: 30)
        keep_alive         => 1,                # reuse the HTTPS connection (default: 1)
        keep_alive_timeout => 60,               # idle timeout in seconds (default: none)
        verify_ssl         => 1,                # verify the server certificate (default: 1)
        ua                 => $user_agent,      # your own HTTP::Tiny-compatible object
    );

=over 4

=item keep_alive

Whether the underlying L<HTTP::Tiny> keeps its connection to the API open
between requests (default 1). Set it to 0 to open a fresh connection for
every request. Not applied when C<ua> is supplied.

=item keep_alive_timeout

Idle timeout in seconds for the kept-alive connection: once it has gone
unused for longer than this, the next request opens a fresh connection
instead of reusing it. Honoured by L<HTTP::Tiny> 0.092 and later, whose own
default (no limit) applies when you leave it unset; older HTTP::Tiny has no
such setting and ignores it, in which case the value is merely stored (see
L</ACCESSORS>). api.ipdata.co keeps idle connections open for roughly two
minutes, so 60 is a sensible value. Not applied when C<ua> is supplied.

=item verify_ssl

Whether the API server's TLS certificate is verified (chain and host name),
default 1. The value is passed to L<HTTP::Tiny> as C<verify_SSL>, so
certificates are checked with every HTTP::Tiny version, not only with 0.083
and later (which verify by default), and independently of HTTP::Tiny's
C<PERL_HTTP_TINY_SSL_INSECURE_BY_DEFAULT> environment variable.
Verification needs a CA bundle: HTTP::Tiny uses L<Mozilla::CA> when it is
installed and otherwise the operating system's bundle (see "SSL SUPPORT" in
L<HTTP::Tiny>); without one every request fails with a C<Network error>.
Set it to 0 only when you must talk to a server whose certificate cannot be
verified, for example a local test endpoint given as C<base_url>: the
connection is still encrypted but the server's identity is not checked. Not
applied when C<ua> is supplied.

=item ua

An object to use instead of a new L<HTTP::Tiny>: anything with
HTTP::Tiny-compatible C<get($url)> and C<post($url, \%options)> methods that
return a hashref with C<status>, C<content>, C<headers> and C<success>. Use
it to share one pre-configured HTTP::Tiny (proxy, C<SSL_options> such as a
private CA file) or to inject a mock in tests. C<timeout>, C<keep_alive>,
C<keep_alive_timeout> and C<verify_ssl> are not applied to a supplied
object; configure it yourself.

=back

=head1 CONNECTION REUSE

A C<Net::IPData> object keeps one persistent HTTPS connection (HTTP/1.1
keep-alive) for as long as it lives. Create one client per process (or one
per API key or endpoint), keep it, and reuse it for every lookup: each new
client pays a fresh TLS handshake. HTTP/2 is not available with
L<HTTP::Tiny>, so the saving is the TLS handshake, not multiplexing.

The reuse is HTTP::Tiny's own (C<< keep_alive => 1 >>): the connection is
reused while the server keeps it open, a connection the server has already
closed is detected and replaced transparently, and a GET on a socket that
died silently is retried once by HTTP::Tiny itself. The non-idempotent
C<POST /bulk> request gets the same single retry from this module, but only
when the failure happened at the socket level before any response arrived
(HTTP::Tiny status 599 with a I<Socket closed>, I<Unexpected end of stream>
or I<Connection reset> error). A request that received an HTTP status is
never retried. With HTTP::Tiny 0.092 or later, C<< keep_alive_timeout => 60 >>
additionally stops reusing a connection that has been idle for a minute,
before the server (which keeps idle connections for roughly two minutes) can
drop it silently.

A C<Net::IPData> object is not shared between threads: use one object per
thread. It is fork-safe: HTTP::Tiny 0.049 and later records the process and
thread that opened the connection and never reuses a socket inherited from
another process or thread, so a forked child opens its own connection on
its first request.

There is nothing to close explicitly. The connection is shut down when the
object is destroyed, so letting it go out of scope (or C<undef $ipdata>) at
shutdown is all the cleanup needed. Pass C<< keep_alive => 0 >> to open a
new connection per request, or your own C<ua> to control the transport
completely.

=head1 REQUEST HEADERS

Every request carries C<Accept: application/json> and the user agent
C<ipdata-perl/VERSION>, VERSION being the module version. The bulk POST,
the only request with a body, also sends C<Content-Type: application/json>;
GET requests send no Content-Type. A supplied C<ua> uses its own default
headers and user agent, but still receives the bulk Content-Type, which the
module passes with each POST.

=head1 METHODS

=head2 lookup($ip, %opts)

Look up an IP address. If C<$ip> is omitted or undef, looks up the
caller's IP address.

Options:

=over 4

=item fields => \@fields | $comma_separated_string

Request only the specified fields. Reduces response size.

=back

Returns a hashref of the API response.

=head2 lookup_mine(%opts)

Look up the IP address of the machine making the request. Accepts the
same options as C<lookup>.

=head2 lookup_field($ip, $field)

Retrieve a single field for an IP address via the path-based API
(e.g., C</8.8.8.8/country_name>). Returns the field value directly,
which may be a string, number, boolean, hashref, or arrayref depending
on the field.

=head2 bulk(\@ips, %opts)

Look up multiple IP addresses in a single request (maximum 100). Sends
a POST request to the C</bulk> endpoint. Accepts the same C<fields>
option as C<lookup>. If the kept-alive connection turns out to be dead
before any response arrived, the request is retried once (see
L</CONNECTION REUSE>).

Returns an arrayref of result hashrefs.

=head2 Convenience Methods

The following methods call C<lookup_field> for common fields:

=over 4

=item asn($ip) - ASN information (hashref)

=item threat($ip) - Threat intelligence (hashref)

=item carrier($ip) - Mobile carrier info (hashref)

=item currency($ip) - Currency data (hashref)

=item time_zone($ip) - Timezone data (hashref)

=item languages($ip) - Language list (arrayref)

=item country_name($ip) - Country name (string)

=item country_code($ip) - Country code (string)

=item is_eu($ip) - EU membership (boolean)

=item is_satellite($ip) - Satellite internet provider flag (boolean)

=item is_anycast($ip) - Anycast address flag (boolean)

=back

=head1 ACCESSORS

=over 4

=item api_key - The API key

=item base_url - The base URL being used

=item timeout - The HTTP timeout value

=item keep_alive - Whether the HTTPS connection is kept alive between requests (default 1)

=item keep_alive_timeout - The idle timeout given to the constructor, or undef

=item verify_ssl - Whether the server certificate is verified (default 1)

=item ua - The user agent object (an L<HTTP::Tiny> unless one was injected)

=back

=head1 ERROR HANDLING

All methods will C<croak> on errors. Catch them with C<eval> or
L<Try::Tiny>:

    use Try::Tiny;

    try {
        my $result = $ipdata->lookup('invalid');
    } catch {
        warn "API error: $_";
    };

Error messages include the HTTP status code and the API's error message
when available.

=head1 API RESPONSE STRUCTURE

A full lookup returns a hashref with the following keys:

    ip, is_eu, is_satellite, is_anycast,
    city, region, region_code, region_type,
    country_name, country_code, continent_name, continent_code,
    latitude, longitude, postal, calling_code, flag,
    emoji_flag, emoji_unicode,
    asn      => { asn, name, domain, route, type },
    company  => { name, domain, network, type },
    carrier  => { name, mcc, mnc },
    languages => [{ name, native, code }],
    currency => { name, code, symbol, native, plural },
    time_zone => { name, abbr, offset, is_dst, current_time },
    threat   => { is_tor, is_vpn, is_icloud_relay, is_proxy, is_datacenter,
                  is_anonymous, is_known_attacker, is_known_abuser,
                  is_threat, is_bogon,
                  blocklists => [{ name, site, type,
                                   first_seen, last_seen, days_seen }],
                  scores => { vpn_score, proxy_score,
                              threat_score, trust_score } },
    count    => N  (for bulk lookups)

The JSON is passed through unchanged, so keys the API adds later simply
appear in the hashref. Five fields deserve a note:

=over 4

=item is_satellite

True when the address belongs to a satellite internet provider. The API
includes this key only when it is true and omits it otherwise, so test it
with a plain boolean check (C<< if ($result->{is_satellite}) >>), never
with C<exists>; a missing key reads as false.

=item is_anycast

True when the address is an anycast address. Present only when true, like
C<is_satellite>.

=item first_seen, last_seen (per C<< threat->{blocklists} >> entry)

The first and the most recent calendar date (UTC, C<YYYY-MM-DD>) on which
that blocklist listed the address. The module leaves them as strings.

=item days_seen (per C<< threat->{blocklists} >> entry)

The number of days that blocklist has listed the address (integer).

=back

Some feeds, for example ipdata's own vpn feed, omit all three blocklist
fields, so check for them with C<exists> before use. Bulk results carry the
same shape per item.

=head1 REQUIREMENTS

Perl 5.10.1 or later. Only core modules are required:

=over 4

=item * L<HTTP::Tiny> 0.049 or later (core since Perl 5.14; 0.049 ships
with Perl 5.22 and later, older Perls install it from CPAN)

=item * L<JSON::PP> (core since Perl 5.14)

=item * L<Carp> (core)

=item * L<Scalar::Util> (core)

=back

HTTPS itself needs L<IO::Socket::SSL> 1.56 and L<Net::SSLeay> 1.49 or later,
plus a CA bundle (L<Mozilla::CA> or the operating system's) for the
certificate verification that is on by default (see L</verify_ssl>). They
are recommended rather than required prerequisites so that the module can be
installed where they are not available.

=head1 SEE ALSO

L<https://docs.ipdata.co/> - ipdata API documentation

L<https://ipdata.co/> - ipdata website

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Net::IPData contributors

=cut
