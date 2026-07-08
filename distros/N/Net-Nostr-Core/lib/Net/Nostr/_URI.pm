package Net::Nostr::_URI;

use strictures 2;

use Carp qw(croak);
use Exporter 'import';
use URI ();

our @EXPORT_OK = qw(
    append_query_params
    build_nip05_url
    parse_uri_query
    validate_http_base_url
    validate_relay_url
);

sub validate_http_base_url {
    my ($url, %opts) = @_;
    return _validate_hierarchical_url(
        $url,
        label   => $opts{label} // 'url',
        schemes => { http => 1, https => 1 },
    );
}

sub validate_relay_url {
    my ($url, %opts) = @_;
    return _validate_hierarchical_url(
        $url,
        label   => $opts{label} // 'relay URL',
        schemes => { ws => 1, wss => 1 },
    );
}

sub build_nip05_url {
    my ($base_url, $local) = @_;
    my $uri = URI->new(validate_http_base_url($base_url, label => 'base_url'));
    my $path = $uri->path;
    $path = '' unless defined $path;
    $path =~ s{/+\z}{};
    $uri->path("$path/.well-known/nostr.json");
    $uri->query_form(name => $local);
    return $uri->as_string;
}

sub append_query_params {
    my ($base_url, @params) = @_;
    croak "url is required" unless defined $base_url && !ref($base_url);
    my $uri = URI->new($base_url);
    my @query = $uri->query_form;
    push @query, @params;
    $uri->query_form(@query) if @query;
    return $uri->as_string;
}

sub parse_uri_query {
    my ($input, %opts) = @_;
    my $label  = $opts{label}  // 'URI';
    my $scheme = $opts{scheme} // croak "scheme is required";

    croak "$label is required" unless defined $input && !ref($input) && length $input;
    croak "$label must not contain control or space characters"
        if $input =~ /[[:cntrl:]\s]/;

    my $uri = URI->new($input);
    croak "$label must use $scheme:// protocol"
        unless defined($uri->scheme) && lc($uri->scheme) eq lc($scheme);
    croak "$label must include an authority"
        unless defined($uri->authority) && length($uri->authority);
    croak "$label must not include userinfo"
        if $uri->authority =~ /@/;
    croak "$label must not include a path"
        if defined($uri->path) && length($uri->path);
    croak "$label must not include a fragment"
        if defined $uri->fragment;
    croak "$label must include query parameters"
        unless defined($uri->query) && length($uri->query);

    return ($uri->authority, $uri->query_form);
}

sub _validate_hierarchical_url {
    my ($url, %opts) = @_;
    my $label = $opts{label};

    croak "$label is required"
        unless defined $url && !ref($url) && length $url;
    croak "$label must not contain control or space characters"
        if $url =~ /[[:cntrl:]\s]/;

    my $uri = URI->new($url);
    my $scheme = $uri->scheme;
    croak "$label must use " . _scheme_list($opts{schemes})
        unless defined $scheme && $opts{schemes}{lc $scheme};

    my $authority = $uri->authority;
    croak "$label must include an authority/host"
        unless defined $authority && length $authority;
    croak "$label must not include userinfo"
        if defined($uri->userinfo) || $authority =~ /@/;
    croak "$label must not include a query"
        if defined $uri->query;
    croak "$label must not include a fragment"
        if defined $uri->fragment;

    my $host = $uri->host;
    croak "$label must include an authority/host"
        unless defined $host && length $host;

    _validate_authority_port($label, $authority, $host);

    return $url;
}

sub _validate_authority_port {
    my ($label, $authority, $host) = @_;

    my $port;
    if ($authority =~ /\A\[[^\]]+\](?::([^:]*))?\z/) {
        $port = $1;
    } else {
        croak "$label must bracket IPv6 host"
            if $host =~ /:/;
        if ($authority =~ /:(.*)\z/) {
            $port = $1;
        }
    }

    return unless defined $port;

    croak "$label port must be between 1 and 65535"
        unless $port =~ /\A[0-9]+\z/ && $port >= 1 && $port <= 65535;
}

sub _scheme_list {
    my ($schemes) = @_;
    my @schemes = sort keys %$schemes;
    return join ' or ', @schemes;
}

1;
