use Test2::V0;
use feature 'signatures';
no warnings 'experimental::signatures';

# Adapted from the pds-in-a-box extraction - same PIB::OAuthSessions/
# Postgres dependency as flow.t originally had; see that file's own
# header note and the oauth-store-interface project memory. $store is
# now this distribution's own
# Mojo::ATProto::OAuth::SessionStore::Memory, and
# last_persisted_state()'s raw SQL is replaced by that store's own
# last_state_for_issuer(). This is the only coverage of the
# scope-upgrade merge mechanics (union of scopes, landing back on the
# original session_id rather than creating a new row).

# Covers Phase 0.5 task 4: refresh_tokens(_p) (indigo's
# ClientSession::RefreshTokens, ported) and start_scope_upgrade(_p) +
# the scope-merge-onto-the-existing-session behaviour in
# process_callback - a PIB-specific requirement with no indigo
# equivalent (see Mojo::ATProto::OAuth's own comments on
# _apply_scope_upgrade_merge(_p)). Same testing approach as flow.t:
# identity/resolver monkey-patched, PAR/token/refresh HTTP calls real
# (embedded mock app), session storage the in-memory test double.

use Mojo::ATProto::OAuth                       qw//;
use Mojo::ATProto::OAuth::Identity              qw//;
use Mojo::ATProto::OAuth::Resolver              qw//;
use Mojo::ATProto::OAuth::SessionStore::Memory qw//;
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

# A mock auth server serving /par (echoes the requested scope back into
# the code it issues) and a single /token endpoint that, like a real
# auth server, handles both grant types: authorization_code (grants
# exactly the scope that was requested at PAR time for that code) and
# refresh_token (issues a fresh access/refresh pair for any non-empty
# refresh_token). Returns ($ua, $get_last_code) - the test needs the
# code /par "issued" to build a realistic fake callback, since there's
# no real browser round-trip handing it back.
sub mock_auth_server ($expected_did) {
    my %scope_for_code;
    my $last_code;

    my $app = Mojolicious::Lite->new;
    $app->routes->post(
        '/par' => sub ($c) {
            return $c->render(text => 'missing DPoP header', status => 400) unless $c->req->headers->header('DPoP');
            my $params = $c->req->body_params->to_hash;
            $last_code = 'auth-code-' . int(rand(1_000_000));
            $scope_for_code{$last_code} = $params->{scope};
            return $c->render(json => {request_uri => "urn:ietf:params:oauth:request_uri:$last_code", expires_in => 60}, status => 201);
        }
    );
    $app->routes->post(
        '/token' => sub ($c) {
            return $c->render(text => 'missing DPoP header', status => 400) unless $c->req->headers->header('DPoP');
            my $params = $c->req->body_params->to_hash;

            if (($params->{grant_type} // '') eq 'refresh_token') {
                return $c->render(json => {error => 'invalid_grant'}, status => 400) unless length($params->{refresh_token} // '');
                return $c->render(
                    json => {
                        access_token  => 'access-refreshed-' . int(rand(1_000_000)),
                        refresh_token => 'refresh-refreshed-' . int(rand(1_000_000)),
                    },
                    status => 200
                );
            }

            my $code = $params->{code} // '';
            return $c->render(json => {error => 'invalid_grant'}, status => 400) unless exists($scope_for_code{$code});
            return $c->render(
                json => {
                    sub           => $expected_did,
                    scope         => $scope_for_code{$code},
                    access_token  => "access-$code",
                    refresh_token => "refresh-$code",
                },
                status => 200
            );
        }
    );

    my $ua = Mojo::UserAgent->new;
    $ua->server->app($app);
    return ($ua, sub { return $last_code });
}

sub make_oauth ($ua) {
    return Mojo::ATProto::OAuth->new(
        client_id    => 'https://pib.example.com/oauth/client-metadata.json',
        callback_url => 'https://pib.example.com/oauth/callback',
        scopes       => ['atproto'],
        ua           => $ua,
        identity     => Mojo::ATProto::OAuth::Identity->new,
        resolver     => Mojo::ATProto::OAuth::Resolver->new,
        store        => $store,
    );
}

subtest 'refresh_tokens mints new tokens and persists them, reusing the same DPoP key' => sub {
    no warnings 'redefine';
    local *Mojo::ATProto::OAuth::Identity::lookup                       = sub ($self, $identifier) { return $stub_identity };
    local *Mojo::ATProto::OAuth::Resolver::resolve_auth_server_url      = sub ($self, $host)        { return 'https://auth.example.com' };
    local *Mojo::ATProto::OAuth::Resolver::resolve_auth_server_metadata = sub ($self, $url)          { return $auth_meta };

    my ($ua, $get_code) = mock_auth_server('did:plc:testuser');
    my $oauth = make_oauth($ua);

    $oauth->start_auth_flow(identifier => 'alice.example.com');
    my $state   = $store->last_state_for_issuer('https://auth.example.com');
    my $session = $oauth->process_callback({state => $state, iss => 'https://auth.example.com', code => $get_code->()});

    my $old_access  = $session->{access_token};
    my $old_refresh = $session->{refresh_token};
    my $old_key_pem = $session->{dpop_private_key_pem};

    my $refreshed = $oauth->refresh_tokens({%$session});

    isnt($refreshed->{access_token}, $old_access, 'access token changed');
    isnt($refreshed->{refresh_token}, $old_refresh, 'refresh token changed');
    is($refreshed->{dpop_private_key_pem}, $old_key_pem, 'the DPoP key itself is never rotated on refresh');

    my $stored = $store->get_session('did:plc:testuser', $state);
    is($stored->{access_token}, $refreshed->{access_token}, 'refreshed tokens actually persisted');

    $store->delete_session('did:plc:testuser', $state);
};

subtest 'refresh_tokens_p (async)' => sub {
    no warnings 'redefine';
    local *Mojo::ATProto::OAuth::Identity::lookup                       = sub ($self, $identifier) { return $stub_identity };
    local *Mojo::ATProto::OAuth::Resolver::resolve_auth_server_url      = sub ($self, $host)        { return 'https://auth.example.com' };
    local *Mojo::ATProto::OAuth::Resolver::resolve_auth_server_metadata = sub ($self, $url)          { return $auth_meta };

    my ($ua, $get_code) = mock_auth_server('did:plc:testuser');
    my $oauth = make_oauth($ua);

    $oauth->start_auth_flow(identifier => 'alice.example.com');
    my $state   = $store->last_state_for_issuer('https://auth.example.com');
    my $session = $oauth->process_callback({state => $state, iss => 'https://auth.example.com', code => $get_code->()});
    my $old_access = $session->{access_token};

    my $refreshed;
    $oauth->refresh_tokens_p({%$session})->then(sub ($s) { $refreshed = $s })->wait;

    isnt($refreshed->{access_token}, $old_access);

    $store->delete_session('did:plc:testuser', $state);
};

subtest 'start_scope_upgrade + process_callback: merges onto the existing session, does not replace it' => sub {
    no warnings 'redefine';
    local *Mojo::ATProto::OAuth::Identity::lookup                       = sub ($self, $identifier) { return $stub_identity };
    local *Mojo::ATProto::OAuth::Resolver::resolve_auth_server_url      = sub ($self, $host)        { return 'https://auth.example.com' };
    local *Mojo::ATProto::OAuth::Resolver::resolve_auth_server_metadata = sub ($self, $url)          { return $auth_meta };

    my ($ua, $get_code) = mock_auth_server('did:plc:testuser');
    my $oauth = make_oauth($ua);

    $oauth->start_auth_flow(identifier => 'alice.example.com');
    my $login_state = $store->last_state_for_issuer('https://auth.example.com');
    my $session      = $oauth->process_callback({state => $login_state, iss => 'https://auth.example.com', code => $get_code->()});
    is($session->{scopes}, ['atproto'], 'original session has only the originally-granted scope');
    my $original_access_token = $session->{access_token};

    my $redirect_url = $oauth->start_scope_upgrade($session, ['transition:generic']);
    like($redirect_url, qr{^https://auth\.example\.com});

    my $upgrade_state = $store->last_state_for_issuer('https://auth.example.com');
    isnt($upgrade_state, $login_state, 'the upgrade uses its own fresh state/PAR request');

    my $upgrade_request = $store->get_auth_request($upgrade_state);
    is($upgrade_request->{upgrade_session_id}, $login_state, 'the auth request carries the original session_id through the round trip');
    is([sort @{$upgrade_request->{scopes}}], ['atproto', 'transition:generic'], 'PAR requested the union of scopes, not just the new one');

    my $upgraded = $oauth->process_callback({state => $upgrade_state, iss => 'https://auth.example.com', code => $get_code->()});
    is($upgraded->{session_id}, $login_state, 'lands back on the original session_id, not a new one');
    is([sort @{$upgraded->{scopes}}], ['atproto', 'transition:generic'], 'scopes merged, not replaced');
    isnt($upgraded->{access_token}, $original_access_token, 'a genuinely new token pair from the upgraded authorization');

    my $stored = $store->get_session('did:plc:testuser', $login_state);
    is($stored->{access_token}, $upgraded->{access_token}, 'the original session row itself was updated in place');

    my $err;
    eval { $store->get_session('did:plc:testuser', $upgrade_state) } or $err = $@;
    like($err, qr/no session found/, 'no separate session row was created under the upgrade PAR\'s own state');

    my $err2;
    eval { $store->get_auth_request($upgrade_state) } or $err2 = $@;
    like($err2, qr/no auth request found/, 'the upgrade auth-request row was cleaned up too');

    $store->delete_session('did:plc:testuser', $login_state);
};

subtest 'start_scope_upgrade_p / process_callback_p (async) merge the same way' => sub {
    no warnings 'redefine';
    local *Mojo::ATProto::OAuth::Identity::lookup_p                       = sub ($self, $identifier) { return Mojo::Promise->resolve($stub_identity) };
    local *Mojo::ATProto::OAuth::Resolver::resolve_auth_server_url_p      = sub ($self, $host)        { return Mojo::Promise->resolve('https://auth.example.com') };
    local *Mojo::ATProto::OAuth::Resolver::resolve_auth_server_metadata_p = sub ($self, $url)          { return Mojo::Promise->resolve($auth_meta) };
    local *Mojo::ATProto::OAuth::Identity::lookup                         = sub ($self, $identifier) { return $stub_identity };
    local *Mojo::ATProto::OAuth::Resolver::resolve_auth_server_url        = sub ($self, $host)        { return 'https://auth.example.com' };
    local *Mojo::ATProto::OAuth::Resolver::resolve_auth_server_metadata   = sub ($self, $url)          { return $auth_meta };

    my ($ua, $get_code) = mock_auth_server('did:plc:testuser');
    my $oauth = make_oauth($ua);

    $oauth->start_auth_flow(identifier => 'alice.example.com');
    my $login_state = $store->last_state_for_issuer('https://auth.example.com');
    my $session      = $oauth->process_callback({state => $login_state, iss => 'https://auth.example.com', code => $get_code->()});

    my $redirect_url;
    $oauth->start_scope_upgrade_p($session, ['transition:generic'])->then(sub ($url) { $redirect_url = $url })->wait;
    like($redirect_url, qr{^https://auth\.example\.com});

    my $upgrade_state = $store->last_state_for_issuer('https://auth.example.com');

    my $upgraded;
    $oauth->process_callback_p({state => $upgrade_state, iss => 'https://auth.example.com', code => $get_code->()})->then(sub ($s) { $upgraded = $s })->wait;

    is($upgraded->{session_id}, $login_state);
    is([sort @{$upgraded->{scopes}}], ['atproto', 'transition:generic']);

    $store->delete_session('did:plc:testuser', $login_state);
};

done_testing;
