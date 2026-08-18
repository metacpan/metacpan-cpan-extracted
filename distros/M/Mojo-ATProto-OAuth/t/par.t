use Test2::V0;
use feature 'signatures';
no warnings 'experimental::signatures';

use Mojo::ATProto::OAuth qw//;
use Mojo::ATProto::OAuth::DPoP qw//;
use Mojolicious::Lite;
use Mojo::UserAgent;
use MIME::Base64 qw/decode_base64url/;
use Mojo::JSON    qw/decode_json/;

# Exercises Mojo::ATProto::OAuth::send_auth_request(_p) against a real
# Mojolicious app implementing the DPoP-nonce-retry PAR dance (RFC 9449)
# - a fake auth server rather than mocking the transport layer, matching
# this project's own established pattern of testing against real
# infrastructure where hitting a live ATProto server isn't reachable/
# appropriate (PAR requires a registered client and a real account,
# neither of which apply to unit tests). The mock app is wired directly
# into a Mojo::UserAgent via ->server->app (no real listen socket) -
# blocking requests from a Mojo::UserAgent to a *separately listening*
# same-process Mojo::Server::Daemon reliably hang in this environment
# (confirmed with a minimal repro, independent of reactor backend and
# of the sandbox); routing straight into the embedded app sidesteps that
# without weakening what's being tested - the same request/response
# code path in Mojo::ATProto::OAuth runs either way.

# Builds a mock PAR endpoint. First call (no/wrong nonce) always 400s
# with a fresh DPoP-Nonce; second call with that nonce in the DPoP proof
# succeeds. Returns a Mojo::UserAgent wired to it.
sub mock_par_ua ($expect_confidential = 0) {
    my $nonce_seq = 0;
    my $good_nonce;

    my $app = Mojolicious::Lite->new;
    $app->routes->post(
        '/par' => sub ($c) {
            my $dpop = $c->req->headers->header('DPoP');
            return $c->render(text => 'missing DPoP header', status => 400) unless $dpop;

            my ($h, $p, $s) = split(/\./, $dpop);
            my $claims = decode_json(decode_base64url($p));

            my $params = $c->req->body_params->to_hash;
            if ($expect_confidential) {
                return $c->render(json => {error => 'invalid_client'}, status => 400)
                    unless length($params->{client_assertion} // '');
            }

            if (!$good_nonce || ($claims->{nonce} // '') ne $good_nonce) {
                $nonce_seq++;
                $good_nonce = "nonce-$nonce_seq";
                $c->res->headers->header('DPoP-Nonce' => $good_nonce);
                return $c->render(json => {error => 'use_dpop_nonce'}, status => 400);
            }

            $c->res->headers->header('DPoP-Nonce' => $good_nonce);
            return $c->render(json => {request_uri => 'urn:ietf:params:oauth:request_uri:req-123', expires_in => 60}, status => 201);
        }
    );

    my $ua = Mojo::UserAgent->new;
    $ua->server->app($app);
    return $ua;
}

subtest 'send_auth_request retries once on use_dpop_nonce and succeeds' => sub {
    my $oauth = Mojo::ATProto::OAuth->new(
        client_id    => 'https://pib.example.com/oauth/client-metadata.json',
        callback_url => 'https://pib.example.com/oauth/callback',
        scopes       => ['atproto'],
        ua           => mock_par_ua(),
    );
    my $auth_meta = {
        issuer                                 => 'https://auth.example.com',
        token_endpoint                         => 'https://auth.example.com/token',
        revocation_endpoint                    => 'https://auth.example.com/revoke',
        pushed_authorization_request_endpoint => '/par',
    };

    my $info = $oauth->send_auth_request($auth_meta, login_hint => 'alice.example.com');

    is($info->{request_uri}, 'urn:ietf:params:oauth:request_uri:req-123');
    is($info->{auth_server_url}, 'https://auth.example.com');
    is($info->{auth_server_token_endpoint}, 'https://auth.example.com/token');
    is($info->{scopes}, ['atproto']);
    ok(length($info->{state}), 'state generated');
    ok(length($info->{pkce_verifier}), 'pkce verifier generated');
    ok(length($info->{dpop_authserver_nonce}), 'final DPoP nonce captured');
    like($info->{dpop_private_key_pem}, qr/BEGIN (EC )?PRIVATE KEY/, 'DPoP private key persisted as PEM');
};

subtest 'send_auth_request_p (async) behaves the same as the sync path' => sub {
    my $oauth = Mojo::ATProto::OAuth->new(
        client_id    => 'https://pib.example.com/oauth/client-metadata.json',
        callback_url => 'https://pib.example.com/oauth/callback',
        scopes       => ['atproto'],
        ua           => mock_par_ua(),
    );
    my $auth_meta = {
        issuer                                 => 'https://auth.example.com',
        token_endpoint                         => 'https://auth.example.com/token',
        pushed_authorization_request_endpoint => '/par',
    };

    my $info;
    $oauth->send_auth_request_p($auth_meta)->then(sub ($i) { $info = $i })->wait;

    is($info->{request_uri}, 'urn:ietf:params:oauth:request_uri:req-123');
    ok(length($info->{dpop_authserver_nonce}), 'final DPoP nonce captured');
};

subtest 'confidential client includes a client_assertion in the PAR body' => sub {
    my $key   = Mojo::ATProto::OAuth::DPoP->generate_keypair;
    my $oauth = Mojo::ATProto::OAuth->new(
        client_id    => 'https://pib.example.com/oauth/client-metadata.json',
        callback_url => 'https://pib.example.com/oauth/callback',
        scopes       => ['atproto'],
        private_key  => $key,
        key_id       => 'key-1',
        ua           => mock_par_ua(1),
    );
    ok($oauth->is_confidential, 'client reports itself confidential once a key is set');

    my $auth_meta = {
        issuer                                 => 'https://auth.example.com',
        token_endpoint                         => 'https://auth.example.com/token',
        pushed_authorization_request_endpoint => '/par',
    };
    my $info = $oauth->send_auth_request($auth_meta);
    is($info->{request_uri}, 'urn:ietf:params:oauth:request_uri:req-123');
};

subtest 'a non-nonce error is not retried and dies with the server-supplied reason' => sub {
    my $app = Mojolicious::Lite->new;
    $app->routes->post('/par' => sub ($c) { $c->render(json => {error => 'invalid_scope'}, status => 400) });
    my $ua = Mojo::UserAgent->new;
    $ua->server->app($app);

    my $oauth = Mojo::ATProto::OAuth->new(
        client_id    => 'https://pib.example.com/oauth/client-metadata.json',
        callback_url => 'https://pib.example.com/oauth/callback',
        scopes       => ['atproto'],
        ua           => $ua,
    );
    my $auth_meta = {
        issuer                                 => 'https://auth.example.com',
        token_endpoint                         => 'https://auth.example.com/token',
        pushed_authorization_request_endpoint => '/par',
    };

    my $err;
    eval { $oauth->send_auth_request($auth_meta) } or $err = $@;
    like($err, qr/invalid_scope/, 'error reason surfaced without a pointless nonce retry');
};

subtest 'new_localhost mimics indigo\'s loopback client for local-dev testing' => sub {
    my $oauth = Mojo::ATProto::OAuth->new_localhost(
        callback_url => 'http://127.0.0.1:3000/oauth/callback',
        scopes       => ['atproto', 'transition:generic'],
        ua           => mock_par_ua(),
    );

    is($oauth->client_id, 'http://localhost?redirect_uri=http%3A%2F%2F127.0.0.1%3A3000%2Foauth%2Fcallback&scope=atproto+transition%3Ageneric',
        'client_id is the fixed localhost sentinel with redirect_uri/scope query-encoded, matching indigo\'s NewLocalhostConfig');
    ok($oauth->loopback, 'flagged as a loopback client');
    ok(!$oauth->is_confidential, 'loopback clients are always public');

    my $err;
    eval { $oauth->client_metadata } or $err = $@;
    like($err, qr/loopback clients don't serve/, 'client_metadata refuses to build a document for a loopback client_id');

    my $auth_meta = {
        issuer                                 => 'https://auth.example.com',
        token_endpoint                         => 'https://auth.example.com/token',
        pushed_authorization_request_endpoint => '/par',
    };
    my $info = $oauth->send_auth_request($auth_meta);
    is($info->{request_uri}, 'urn:ietf:params:oauth:request_uri:req-123', 'PAR still completes normally with a loopback client_id');
};

done_testing;
