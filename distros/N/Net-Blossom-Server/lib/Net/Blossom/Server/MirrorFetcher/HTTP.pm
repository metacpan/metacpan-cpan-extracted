package Net::Blossom::Server::MirrorFetcher::HTTP;

use strictures 2;

use Net::Blossom::_ConstructorArgs ();
use Net::Blossom::Server::Error;

use Carp qw(croak);
use Class::Tiny qw(_allowed_hosts timeout max_bytes user_agent);
use HTTP::Tiny ();
use Scalar::Util qw(blessed);
use URI ();

my $DEFAULT_TIMEOUT = 5;

sub new {
    my $class = shift;
    my %args = Net::Blossom::_ConstructorArgs::normalize(@_);
    my %known = map { $_ => 1 } qw(allowed_hosts timeout max_bytes user_agent);
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    croak "allowed_hosts is required" unless defined $args{allowed_hosts};
    croak "allowed_hosts must be an array reference" unless ref($args{allowed_hosts}) eq 'ARRAY';
    croak "allowed_hosts must not be empty" unless @{$args{allowed_hosts}};
    my @allowed_hosts;
    for my $host (@{$args{allowed_hosts}}) {
        croak "allowed_hosts must contain host names only"
            unless defined $host && !ref($host) && _valid_allowed_host($host);
        push @allowed_hosts, lc $host;
    }
    $args{_allowed_hosts} = \@allowed_hosts;
    delete $args{allowed_hosts};

    croak "max_bytes is required" unless defined $args{max_bytes};
    croak "max_bytes must be a positive integer"
        unless !ref($args{max_bytes}) && $args{max_bytes} =~ /\A[1-9][0-9]*\z/;

    $args{timeout} = $DEFAULT_TIMEOUT unless defined $args{timeout};
    croak "timeout must be a positive integer"
        unless !ref($args{timeout}) && $args{timeout} =~ /\A[1-9][0-9]*\z/;

    if (defined $args{user_agent}) {
        croak "user_agent must provide request"
            unless blessed($args{user_agent}) && $args{user_agent}->can('request');
    }
    else {
        my %http_args = (
            agent        => 'Net-Blossom-Server',
            timeout      => $args{timeout},
            max_redirect => 0,
            max_size     => $args{max_bytes},
            proxy        => undef,
        );
        $http_args{http_proxy} = undef if HTTP::Tiny->can('http_proxy');
        $http_args{https_proxy} = undef if HTTP::Tiny->can('https_proxy');
        $args{user_agent} = HTTP::Tiny->new(%http_args);
    }

    return bless \%args, $class;
}

sub allowed_hosts {
    my ($self) = @_;
    return [@{$self->_allowed_hosts}];
}

sub fetch_blob {
    my $self = shift;
    my ($url, %opts) = @_;
    my %known = map { $_ => 1 } qw(sink);
    my @unknown = grep { !exists $known{$_} } keys %opts;
    croak "unknown option(s): " . join(', ', sort @unknown) if @unknown;
    croak "sink is required" unless defined $opts{sink};
    croak "sink must provide start and write"
        unless blessed($opts{sink}) && $opts{sink}->can('start') && $opts{sink}->can('write');

    my $uri = _validated_url($url);
    my $host = lc $uri->host;

    my %allowed = map { $_ => 1 } @{$self->_allowed_hosts};
    Net::Blossom::Server::Error->throw(
        status => 403,
        reason => 'Mirror URL host is not allowed',
    ) unless $allowed{$host};

    # The allowlist names hosts only, so an allowed host must not be usable to
    # reach an arbitrary port (e.g. internal services co-located on that host).
    Net::Blossom::Server::Error->throw(
        status => 403,
        reason => 'Mirror URL port is not allowed',
    ) if $uri->port != $uri->default_port;

    my $started = 0;
    my $size = 0;
    my %metadata;
    my $sink_error;
    my $response = eval {
        local @ENV{qw(http_proxy HTTP_PROXY https_proxy HTTPS_PROXY all_proxy ALL_PROXY no_proxy NO_PROXY)};
        delete @ENV{qw(http_proxy HTTP_PROXY https_proxy HTTPS_PROXY all_proxy ALL_PROXY no_proxy NO_PROXY)};

        $self->user_agent->request('GET', $url, {
            data_callback => sub {
                my ($chunk, $response) = @_;
                croak "response chunks must be scalars" if ref($chunk);

                _ensure_successful_response($response);
                if (!$started) {
                    %metadata = _metadata_from_response($response, $self->max_bytes);
                    eval { $opts{sink}->start(%metadata); 1 } or do {
                        $sink_error = $@;
                        die $sink_error;
                    };
                    $started = 1;
                }

                my $new_size = $size + length($chunk);
                _too_large() if $new_size > $self->max_bytes;
                eval { $opts{sink}->write($chunk); 1 } or do {
                    $sink_error = $@;
                    die $sink_error;
                };
                $size = $new_size;
            },
        });
    };
    if ($@) {
        die $sink_error if defined $sink_error;
        die $@ if blessed($@) && $@->isa('Net::Blossom::Server::Error');
        Net::Blossom::Server::Error->throw(
            status => 502,
            reason => 'Origin fetch failed',
        );
    }

    _ensure_successful_response($response);

    if (!$started) {
        %metadata = _metadata_from_response($response, $self->max_bytes);
        $opts{sink}->start(%metadata);
    }
    return \%metadata;
}

sub _validated_url {
    my ($url) = @_;
    Net::Blossom::Server::Error->throw(
        status => 400,
        reason => 'Invalid mirror URL',
    ) unless defined $url && !ref($url) && length $url && $url !~ /[\x00-\x20]/;

    my $uri = URI->new($url);
    my $scheme = $uri->scheme;
    my $host = eval { $uri->host };
    my $userinfo = eval { $uri->userinfo };

    Net::Blossom::Server::Error->throw(
        status => 400,
        reason => 'Invalid mirror URL',
    ) unless defined $scheme && $scheme =~ /\Ahttps?\z/i
        && defined $host && length $host
        && (!defined($userinfo) || !length($userinfo))
        && !defined($uri->fragment);

    return $uri;
}

sub _header {
    my ($headers, $name) = @_;
    my $value = $headers->{$name};
    $value = $headers->{lc $name} unless defined $value;
    $value = $value->[0] if ref($value) eq 'ARRAY';
    return $value;
}

sub _ensure_successful_response {
    my ($response) = @_;
    Net::Blossom::Server::Error->throw(
        status => 502,
        reason => 'Origin response was not successful',
    ) unless ref($response) eq 'HASH' && $response->{success};
}

sub _metadata_from_response {
    my ($response, $max_bytes) = @_;
    my $headers = ref($response->{headers}) eq 'HASH' ? $response->{headers} : {};
    my $content_length = _header($headers, 'content-length');
    if (defined $content_length) {
        Net::Blossom::Server::Error->throw(
            status => 502,
            reason => 'Origin Content-Length is invalid',
        ) unless $content_length =~ /\A\d+\z/;
        _too_large() if $content_length > $max_bytes;
    }

    my $type = _header($headers, 'content-type');
    $type = 'application/octet-stream' unless defined $type && length $type;

    my %metadata = (type => $type);
    $metadata{content_length} = $content_length if defined $content_length;
    return %metadata;
}

sub _too_large {
    Net::Blossom::Server::Error->throw(
        status => 413,
        reason => 'Mirrored blob is too large',
    );
}

sub _valid_allowed_host {
    my ($host) = @_;
    return 0 if $host =~ /[\x00-\x20]/;
    return 0 if $host =~ m{[/?#\@:]};
    return length $host;
}

1;

=pod

=head1 NAME

Net::Blossom::Server::MirrorFetcher::HTTP - Allowlist HTTP fetcher for Blossom mirrors

=head1 SYNOPSIS

    use Net::Blossom::Server::MirrorFetcher::HTTP;

    my $fetcher = Net::Blossom::Server::MirrorFetcher::HTTP->new(
        allowed_hosts => ['cdn.example.com'],
        max_bytes     => 50_000_000,
        timeout       => 5,
    );

    my $server = Net::Blossom::Server->new(
        storage        => $storage,
        mirror_fetcher => $fetcher,
    );

=head1 DESCRIPTION

C<Net::Blossom::Server::MirrorFetcher::HTTP> is a small allowlist-only fetcher
for C<PUT /mirror>. It is intentionally conservative: it does not provide public
internet mirroring by default.

The fetcher validates the URL before making a request, requires the URL host to
match one of the configured C<allowed_hosts>, disables redirects in the default
HTTP client, clears common proxy environment variables while fetching, and
enforces a maximum response size while streaming into the supplied sink.

=head1 CONSTRUCTOR

=head2 new

    my $fetcher = Net::Blossom::Server::MirrorFetcher::HTTP->new(%args);

Required arguments:

=over 4

=item * C<allowed_hosts>

Array reference of host names that may be mirrored. Matching is exact and
case-insensitive. Wildcards are not supported. Only default ports for the URL
scheme are allowed.

=item * C<max_bytes>

Positive integer maximum response size in bytes.

=back

Optional arguments:

=over 4

=item * C<timeout>

Positive integer request timeout in seconds. Defaults to C<5>.

=item * C<user_agent>

Object with a C<request> method compatible with C<HTTP::Tiny>. This is mainly
for tests or applications that need to supply their own HTTP transport.

Custom user agents are trusted transport policy. They must not follow redirects
unless each redirected URL is checked against the same allowlist, and they must
not route requests through proxies or other transports that bypass the configured
C<allowed_hosts> policy.

=back

Unknown arguments or invalid values croak.

=head1 ACCESSORS

=head2 allowed_hosts

Returns a copy array reference of allowed host names.

=head2 timeout

Returns the request timeout.

=head2 max_bytes

Returns the maximum response size.

=head2 user_agent

Returns the HTTP transport object.

=head1 METHODS

=head2 fetch_blob

    my $metadata = $fetcher->fetch_blob($url, sink => $sink);

Fetches an allowed C<http> or C<https> URL, calls
C<< $sink->start(%metadata) >>, streams scalar byte chunks through
C<< $sink->write($chunk) >>, and returns a metadata hash reference with C<type>
and optional C<content_length>. Missing C<Content-Type> defaults to
C<application/octet-stream>. A C<body> value is never returned.

The method throws L<Net::Blossom::Server::Error> for expected HTTP-facing
failures: C<400> for malformed URLs, C<403> for non-allowlisted hosts, C<413>
for blobs larger than C<max_bytes>, and C<502> for origin failures or unusable
origin responses.

=cut
