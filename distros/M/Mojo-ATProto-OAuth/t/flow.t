use Test2::V0;
use feature 'signatures';
no warnings 'experimental::signatures';

# Adapted from the pds-in-a-box extraction: the original test hard-
# depended on PIB::OAuthSessions (a Postgres-backed store) and raw SQL
# against oauth_auth_requests to recover the PAR-generated 'state'
# value. Neither exists in this repo, so $store is now this
# distribution's own Mojo::ATProto::OAuth::SessionStore::Memory (see
# the oauth-store-interface project memory), and the raw-SQL
# last_persisted_state() lookup is replaced by that store's own
# last_state_for_issuer(). Everything else - the mock auth server, the
# monkey-patched Identity/Resolver, the assertions - is unchanged.

# End-to-end orchestration test for Mojo::ATProto::OAuth's
# start_auth_flow(_p)/process_callback(_p) - the full PAR -> redirect ->
# callback -> token exchange -> identity re-verification -> persistence
# round-trip. Identity/Resolver's own resolution logic already has
# dedicated real/live tests (identity.t, identity_async.t, resolver.t) -
# here they're monkey-patched (same technique identity_async.t already
# established: `local *Package::method = sub {...}`) so this test
# exercises OAuth.pm's own orchestration and error-checking, not DNS/PLC
# infrastructure. The PAR/token HTTP calls are real (embedded mock
# app); the session store is the in-memory test double described above.

use Mojo::ATProto::OAuth                       qw//;
use Mojo::ATProto::OAuth::Identity              qw//;
use Mojo::ATProto::OAuth::Resolver              qw//;
use Mojo::ATProto::OAuth::SessionStore::Memory qw//;
use Mojo::URL;
use Mojo::Promise;
use Mojolicious::Lite;
use Mojo::UserAgent;

my $store = Mojo::ATProto::OAuth::SessionStore::Memory->new;

my $auth_meta = {
    issuer                                 => 'https://auth.example.com',
    authorization_endpoint                 => 'https://auth.example.com/authorize',
    token_endpoint                         => '/token',
    revocation_endpoint                    => '/revoke',
    pushed_authorization_request_endpoint => '/par',
};

my $stub_identity = {
    did      => 'did:plc:testuser',
    handle   => 'alice.example.com',
    services => {atproto_pds => {url => 'https://pds.example.com'}},
};

# One mock auth server, wired directly into a Mojo::UserAgent (no real
# socket - see t/atproto-oauth/par.t for why it has to be this way in
# this dev environment). Returns ($ua, $get_last_code) - the test needs
# the code /par "issued" to build a realistic fake callback, since
# there's no real browser round-trip handing it back.
sub mock_auth_server ($expected_did) {
    my $issued_code;

    my $app = Mojolicious::Lite->new;
    $app->routes->post(
        '/par' => sub ($c) {
            return $c->render(text => 'missing DPoP header', status => 400) unless $c->req->headers->header('DPoP');
            $issued_code = 'auth-code-' . int(rand(1_000_000));
            return $c->render(json => {request_uri => 'urn:ietf:params:oauth:request_uri:xyz', expires_in => 60}, status => 201);
        }
    );
    $app->routes->post(
        '/token' => sub ($c) {
            return $c->render(text => 'missing DPoP header', status => 400) unless $c->req->headers->header('DPoP');
            my $params = $c->req->body_params->to_hash;
            return $c->render(json => {error => 'invalid_grant'}, status => 400) unless ($params->{code} // '') eq ($issued_code // '');
            return $c->render(
                json => {
                    sub           => $expected_did,
                    scope         => 'atproto',
                    access_token  => 'access-' . int(rand(1_000_000)),
                    refresh_token => 'refresh-' . int(rand(1_000_000)),
                },
                status => 200
            );
        }
    );

    my $ua = Mojo::UserAgent->new;
    $ua->server->app($app);
    return ($ua, sub { return $issued_code });
}

subtest 'full flow, account_did known from the start (handle login)' => sub {
    no warnings 'redefine';
    my $lookup_calls = 0;
    local *Mojo::ATProto::OAuth::Identity::lookup                       = sub ($self, $identifier) { $lookup_calls++; return $stub_identity };
    local *Mojo::ATProto::OAuth::Resolver::resolve_auth_server_url      = sub ($self, $host)        { return 'https://auth.example.com' };
    local *Mojo::ATProto::OAuth::Resolver::resolve_auth_server_metadata = sub ($self, $url)          { return $auth_meta };

    my ($ua, $get_code) = mock_auth_server('did:plc:testuser');
    my $oauth = Mojo::ATProto::OAuth->new(
        client_id    => 'https://pib.example.com/oauth/client-metadata.json',
        callback_url => 'https://pib.example.com/oauth/callback',
        scopes       => ['atproto'],
        ua           => $ua,
        identity     => Mojo::ATProto::OAuth::Identity->new,
        resolver     => Mojo::ATProto::OAuth::Resolver->new,
        store        => $store,
    );

    my $redirect_url = $oauth->start_auth_flow(identifier => 'alice.example.com');
    like($redirect_url, qr{^https://auth\.example\.com}, 'redirect points at the authorization endpoint');
    is(Mojo::URL->new($redirect_url)->query->param('request_uri'), 'urn:ietf:params:oauth:request_uri:xyz');

    my $state = $store->last_state_for_issuer('https://auth.example.com');
    ok($state, 'auth request row persisted');

    my $session = $oauth->process_callback({state => $state, iss => 'https://auth.example.com', code => $get_code->()});

    is($session->{account_did}, 'did:plc:testuser');
    is($session->{handle}, 'alice.example.com', 'handle persisted through start_auth_flow -> session data');
    is($session->{host_url}, 'https://pds.example.com');
    is($session->{session_id}, $state);
    is($lookup_calls, 1, 'process_callback reused the identity already resolved at start_auth_flow time - no redundant lookup');
    ok(length($session->{access_token} // ''), 'access token persisted');
    ok(length($session->{refresh_token} // ''), 'refresh token persisted');

    my $stored = $store->get_session('did:plc:testuser', $state);
    is($stored->{access_token}, $session->{access_token}, 'session actually landed in the store');

    my $err;
    eval { $store->get_auth_request($state) } or $err = $@;
    like($err, qr/no auth request found/, 'auth request row cleaned up after a successful callback');

    $store->delete_session('did:plc:testuser', $state);
};

subtest 'full flow, identity unknown until the callback (bare auth-server-URL entry)' => sub {
    no warnings 'redefine';
    local *Mojo::ATProto::OAuth::Identity::lookup                       = sub ($self, $identifier) { return $stub_identity };
    local *Mojo::ATProto::OAuth::Resolver::resolve_auth_server_url      = sub ($self, $host)        { return 'https://auth.example.com' };
    local *Mojo::ATProto::OAuth::Resolver::resolve_auth_server_metadata = sub ($self, $url)          { return $auth_meta };

    my ($ua, $get_code) = mock_auth_server('did:plc:testuser');
    my $oauth = Mojo::ATProto::OAuth->new(
        client_id    => 'https://pib.example.com/oauth/client-metadata.json',
        callback_url => 'https://pib.example.com/oauth/callback',
        scopes       => ['atproto'],
        ua           => $ua,
        identity     => Mojo::ATProto::OAuth::Identity->new,
        resolver     => Mojo::ATProto::OAuth::Resolver->new,
        store        => $store,
    );

    my $redirect_url = $oauth->start_auth_flow(identifier => 'https://auth.example.com');
    like($redirect_url, qr{^https://auth\.example\.com}, 'still redirects correctly with no prior identity resolution');

    my $state = $store->last_state_for_issuer('https://auth.example.com');
    my $stored_request = $store->get_auth_request($state);
    ok(!length($stored_request->{account_did} // ''), 'account_did stayed unknown at PAR time - only resolved from the token response');

    my $session = $oauth->process_callback({state => $state, iss => 'https://auth.example.com', code => $get_code->()});
    is($session->{account_did}, 'did:plc:testuser', 'DID recovered from the token response sub, then verified via identity + resolver');
    is($session->{handle}, 'alice.example.com', 'handle also resolved at callback time for the bare-URL entry path');
    is($session->{host_url}, 'https://pds.example.com');

    $store->delete_session('did:plc:testuser', $state);
};

subtest 'process_callback dies on an auth-server iss/state mismatch' => sub {
    no warnings 'redefine';
    local *Mojo::ATProto::OAuth::Identity::lookup                       = sub ($self, $identifier) { return $stub_identity };
    local *Mojo::ATProto::OAuth::Resolver::resolve_auth_server_url      = sub ($self, $host)        { return 'https://auth.example.com' };
    local *Mojo::ATProto::OAuth::Resolver::resolve_auth_server_metadata = sub ($self, $url)          { return $auth_meta };

    my ($ua, $get_code) = mock_auth_server('did:plc:testuser');
    my $oauth = Mojo::ATProto::OAuth->new(
        client_id    => 'https://pib.example.com/oauth/client-metadata.json',
        callback_url => 'https://pib.example.com/oauth/callback',
        scopes       => ['atproto'],
        ua           => $ua,
        identity     => Mojo::ATProto::OAuth::Identity->new,
        resolver     => Mojo::ATProto::OAuth::Resolver->new,
        store        => $store,
    );

    $oauth->start_auth_flow(identifier => 'alice.example.com');
    my $state = $store->last_state_for_issuer('https://auth.example.com');

    my $err;
    eval { $oauth->process_callback({state => $state, iss => 'https://impostor.example.com', code => $get_code->()}) } or $err = $@;
    like($err, qr/iss doesn't match/, 'a mismatched iss is rejected rather than proceeding to token exchange');

    $store->delete_auth_request($state);
};

subtest 'async: start_auth_flow_p / process_callback_p, URL-only entry path' => sub {
    no warnings 'redefine';
    local *Mojo::ATProto::OAuth::Identity::lookup_p                       = sub ($self, $identifier) { return Mojo::Promise->resolve($stub_identity) };
    local *Mojo::ATProto::OAuth::Resolver::resolve_auth_server_url_p      = sub ($self, $host)        { return Mojo::Promise->resolve('https://auth.example.com') };
    local *Mojo::ATProto::OAuth::Resolver::resolve_auth_server_metadata_p = sub ($self, $url)          { return Mojo::Promise->resolve($auth_meta) };

    my ($ua, $get_code) = mock_auth_server('did:plc:testuser');
    my $oauth = Mojo::ATProto::OAuth->new(
        client_id    => 'https://pib.example.com/oauth/client-metadata.json',
        callback_url => 'https://pib.example.com/oauth/callback',
        scopes       => ['atproto'],
        ua           => $ua,
        identity     => Mojo::ATProto::OAuth::Identity->new,
        resolver     => Mojo::ATProto::OAuth::Resolver->new,
        store        => $store,
    );

    my $redirect_url;
    $oauth->start_auth_flow_p(identifier => 'https://auth.example.com')->then(sub ($url) { $redirect_url = $url })->wait;
    like($redirect_url, qr{^https://auth\.example\.com});

    my $state = $store->last_state_for_issuer('https://auth.example.com');

    my $session;
    $oauth->process_callback_p({state => $state, iss => 'https://auth.example.com', code => $get_code->()})->then(sub ($s) { $session = $s })->wait;

    is($session->{account_did}, 'did:plc:testuser');
    is($session->{handle}, 'alice.example.com');
    is($session->{host_url}, 'https://pds.example.com');

    my $err;
    eval { $store->get_auth_request($state) } or $err = $@;
    like($err, qr/no auth request found/, 'auth request row cleaned up after a successful async callback');

    $store->delete_session('did:plc:testuser', $state);
};

done_testing;
