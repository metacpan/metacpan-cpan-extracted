package 
    Mojo::ATProto::OAuth::Resolver;
use Mojo::Base -base, -signatures;

use Mojo::UserAgent qw//;
use Mojo::URL qw//;
use Mojo::Log qw//;

# Resource-server (PDS) -> auth-server discovery, plus auth-server
# metadata fetch+validation. 
use constant DEBUG => $ENV{MOJO_OAUTH_DEBUG} || 0;

our $VERSION = '1.01'; # VERSION

has 'ua'     => sub($self) {
    my $ua = Mojo::UserAgent->new(request_timeout => 10);
    no strict;
    $ua->transactor->name('Mojo::ATProto::OAuth/' . $VERSION || 'dev');
    use strict;
    return $ua;
};
has 'log'    => sub { Mojo::Log->new };

# Resolves a resource-server (PDS) URL to its auth-server URL, via the
# protected-resource metadata document. They may be the same server -
# atproto PDSes are commonly their own auth server, but don't have to
# be (e.g. an entryway-fronted PDS).
sub resolve_auth_server_url($self, $host_url) {
    $self->log->debug("Resolver: resolving auth-server URL for $host_url") if DEBUG;
    my $doc_url = $self->_protected_resource_url($host_url);
    my $tx      = $self->ua->get($doc_url);
    my $res     = $tx->result;
    $self->log->debug('Resolver: protected-resource response status=' . ($res->code // 'connection error')) if DEBUG;
    die "fetching protected resource document failed: " . ($res->message // 'connection error') . "\n"
        unless defined($res->code) && $res->code == 200;
    my $auth_server_url = $self->_extract_auth_server_url($res->json);
    $self->log->debug("Resolver: $host_url -> auth-server $auth_server_url") if DEBUG;
    return $auth_server_url;
}

# Non-blocking counterpart 
sub resolve_auth_server_url_p($self, $host_url) {
    $self->log->debug("Resolver: resolving auth-server URL for $host_url (async)") if DEBUG;
    my $doc_url = $self->_protected_resource_url($host_url);
    return $self->ua->get_p($doc_url)->then(sub($tx) { 
        my $res = $tx->result;
        $self->log->debug('Resolver: protected-resource response status=' . ($res->code // 'connection error')) if DEBUG;
        die "fetching protected resource document failed: " . ($res->message // 'connection error') . "\n"
            unless defined($res->code) && $res->code == 200;
        my $auth_server_url = $self->_extract_auth_server_url($res->json);
        $self->log->debug("Resolver: $host_url -> auth-server $auth_server_url") if DEBUG;
        return $auth_server_url;
    });
}

sub _protected_resource_url($self, $host_url) {
    my $u = Mojo::URL->new($host_url);
    die "not a valid public host URL: $host_url\n"
        unless $u->scheme eq 'https' && length($u->host // '') && !$u->port;
    return Mojo::URL->new(sprintf('https://%s/.well-known/oauth-protected-resource', $u->host));
}

sub _extract_auth_server_url($self, $body) {
    my @servers = @{$body->{authorization_servers} // []};
    die "no auth server URL in protected resource document\n" unless @servers;

    my $auth_url = $servers[0];
    my $au       = Mojo::URL->new($auth_url);
    die "not a valid public auth server URL: $auth_url\n"
        unless $au->scheme eq 'https' && length($au->host // '') && !$au->port;

    return $auth_url;
}

# Resolves an auth-server URL to its full metadata document
sub resolve_auth_server_metadata($self, $server_url) {
    $self->log->debug("Resolver: fetching auth-server metadata for $server_url") if DEBUG;
    my $doc_url = $self->_auth_server_metadata_url($server_url);
    my $tx      = $self->ua->get($doc_url);
    my $res     = $tx->result;
    $self->log->debug('Resolver: auth-server metadata response status=' . ($res->code // 'connection error')) if DEBUG;
    die "fetching auth server metadata failed: " . ($res->message // 'connection error') . "\n"
        unless defined($res->code) && $res->code == 200;

    my $meta = $res->json;
    $self->_validate_auth_server_metadata($meta, $server_url);
    $self->log->debug("Resolver: auth-server metadata for $server_url validated ok "
        . "(par_endpoint=" . ($meta->{pushed_authorization_request_endpoint} // '?') . ")") if DEBUG;
    return $meta;
}

sub resolve_auth_server_metadata_p($self, $server_url) {
    $self->log->debug("Resolver: fetching auth-server metadata for $server_url (async)") if DEBUG;
    my $doc_url = $self->_auth_server_metadata_url($server_url);
    return $self->ua->get_p($doc_url)->then(sub($tx) {
        my $res = $tx->result;
        $self->log->debug('Resolver: auth-server metadata response status=' . ($res->code // 'connection error')) if DEBUG;
        die "fetching auth server metadata failed: " . ($res->message // 'connection error') . "\n"
            unless defined($res->code) && $res->code == 200;

        my $meta = $res->json;
        $self->_validate_auth_server_metadata($meta, $server_url);
        $self->log->debug("Resolver: auth-server metadata for $server_url validated ok "
            . "(par_endpoint=" . ($meta->{pushed_authorization_request_endpoint} // '?') . ")") if DEBUG;
        return $meta;
    });
}

sub _auth_server_metadata_url($self, $server_url) {
    my $u = Mojo::URL->new($server_url);
    die "not a valid public host URL: $server_url\n"
        unless $u->scheme eq 'https' && length($u->host // '') && !$u->port;
    return Mojo::URL->new(sprintf('https://%s/.well-known/oauth-authorization-server', $u->host));
}

sub _contains($self, $list, $value) {
    return grep { $_ eq $value } @{$list // []};
}

sub _validate_auth_server_metadata($self, $meta, $server_url) {
    die "invalid auth server metadata: empty issuer\n" unless length($meta->{issuer} // '');

    my $iss = Mojo::URL->new($meta->{issuer});
    die "invalid auth server metadata: issuer URL\n"
        unless $iss->scheme eq 'https'
        && !$iss->port
        && !length($iss->path->to_string)
        && !length($iss->fragment // '')
        && !$iss->query->to_string;

    my $srv = Mojo::URL->new($server_url);
    die "invalid auth server metadata: issuer must match request URL\n"
        unless $iss->scheme eq $srv->scheme && $iss->host eq $srv->host;

    my $ae = Mojo::URL->new($meta->{authorization_endpoint} // '');
    die "invalid auth server metadata: invalid authorization_endpoint\n"
        unless $ae->scheme eq 'https';

    die "invalid auth server metadata: response_types_supported must include 'code'\n"
        unless $self->_contains($meta->{response_types_supported}, 'code');
    die "invalid auth server metadata: grant_types_supported must include 'authorization_code'\n"
        unless $self->_contains($meta->{grant_types_supported}, 'authorization_code');
    die "invalid auth server metadata: grant_types_supported must include 'refresh_token'\n"
        unless $self->_contains($meta->{grant_types_supported}, 'refresh_token');
    die "invalid auth server metadata: code_challenge_methods_supported must include 'S256'\n"
        unless $self->_contains($meta->{code_challenge_methods_supported}, 'S256');
    die "invalid auth server metadata: token_endpoint_auth_methods_supported must include 'none'\n"
        unless $self->_contains($meta->{token_endpoint_auth_methods_supported}, 'none');
    die "invalid auth server metadata: token_endpoint_auth_methods_supported must include 'private_key_jwt'\n"
        unless $self->_contains($meta->{token_endpoint_auth_methods_supported}, 'private_key_jwt');
    die "invalid auth server metadata: token_endpoint_auth_signing_alg_values_supported must include 'ES256'\n"
        unless $self->_contains($meta->{token_endpoint_auth_signing_alg_values_supported}, 'ES256');
    die "invalid auth server metadata: scopes_supported must include 'atproto'\n"
        unless $self->_contains($meta->{scopes_supported}, 'atproto');
    die "invalid auth server metadata: authorization_response_iss_parameter_supported must be true\n"
        unless $meta->{authorization_response_iss_parameter_supported};
    die "invalid auth server metadata: require_pushed_authorization_requests must be true\n"
        unless $meta->{require_pushed_authorization_requests};
    die "invalid auth server metadata: pushed_authorization_request_endpoint is required\n"
        unless length($meta->{pushed_authorization_request_endpoint} // '');
    die "invalid auth server metadata: dpop_signing_alg_values_supported must include 'ES256'\n"
        unless $self->_contains($meta->{dpop_signing_alg_values_supported}, 'ES256');
    die "invalid auth server metadata: require_request_uri_registration must be undefined or true\n"
        if exists($meta->{require_request_uri_registration}) && !$meta->{require_request_uri_registration};
    die "invalid auth server metadata: client_id_metadata_document_supported must be true\n"
        unless $meta->{client_id_metadata_document_supported};

    return 1;
}

1;
