#!perl
use 5.024;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use POTest;
use Crypt::JWS qw(b64url random_bytes sha256 verify);
use Crypt::JWS::Key ();
use File::Raw::JSON ();
use MIME::Base64 ();
use Punk::OAuth2::Server::Store;

# A shared store (a plain SQLite file so the same rows are visible to the
# server and to the test's client registration).
my $dbfile = "/tmp/pox-as-$$.db";
unlink $dbfile;
my $store = Punk::OAuth2::Server::Store->new(dsn => "dbi:SQLite:dbname=$dbfile");
END { unlink $dbfile if $dbfile }

$store->client_put({
    client_id     => 'webapp',
    secret        => 'topsecret',
    name          => 'Web App',
    redirect_uris => ['https://app.test/cb'],
    scopes        => 'read write',
});
$store->client_put({
    client_id     => 'service',
    secret        => 'svcsecret',
    grant_types   => 'client_credentials',
    scopes        => 'read',
});
# registered for nothing it can ask for: the grant it names and the scope it
# names both have to be on its own row
$store->client_put({
    client_id     => 'narrow',
    secret        => 'narrowsecret',
    redirect_uris => ['https://narrow.test/cb'],
    grant_types   => 'authorization_code',
    scopes        => 'read',
});
# a public client (no secret) - client_credentials is not for it at all
$store->client_put({
    client_id     => 'browser',
    redirect_uris => ['https://browser.test/cb'],
    grant_types   => 'authorization_code client_credentials',
    scopes        => 'read',
    public        => 1,
});

my $user = 'user-42';
{
    package IdPApp;
    use Punk;
    use Punk::Plugin::OAuth2;
    plugin 'OAuth2';
    oauth2_server '/oauth' => {
        issuer       => 'https://idp.test',
        store        => $store,
        authenticate => sub { $user },
    };
}
my $app = IdPApp->to_app;

sub form_post {
    my ($path, %fields) = @_;
    my $body = join '&', map {
        my $v = $fields{$_} // '';
        "$_=" . ($v =~ s/([^A-Za-z0-9\-._~])/sprintf '%%%02X', ord $1/ger)
    } sort keys %fields;
    return POTest::hit($app, POST => $path, body => $body,
        type => 'application/x-www-form-urlencoded');
}

sub basic { 'Basic ' . MIME::Base64::encode_base64("$_[0]:$_[1]", '') }
sub jdec  { File::Raw::JSON::file_json_decode($_[0]) }

# PKCE
my $verifier  = b64url(random_bytes(32));
my $challenge = b64url(sha256($verifier));

# --- /authorize -> code -----------------------------------------------------
my $code;
{
    my ($s, $h) = POTest::hit($app, GET =>
        "/oauth/authorize?response_type=code&client_id=webapp"
      . "&redirect_uri=https%3A%2F%2Fapp.test%2Fcb&scope=read"
      . "&state=xyz&code_challenge=$challenge&code_challenge_method=S256");
    is $s, 302, 'authorize redirects with a code';
    like $h->{location}, qr{^https://app\.test/cb\?}, 'to the redirect_uri';
    like $h->{location}, qr/[?&]state=xyz/, 'state echoed';
    like $h->{location}, qr/[?&]iss=https/, 'iss parameter present';
    ($code) = $h->{location} =~ /[?&]code=([^&]+)/;
    ok $code, 'got an authorization code';
}

# authorize refuses an unregistered redirect_uri without redirecting
{
    my ($s, $h) = POTest::hit($app, GET =>
        "/oauth/authorize?response_type=code&client_id=webapp"
      . "&redirect_uri=https%3A%2F%2Fevil%2Fcb&state=x"
      . "&code_challenge=$challenge&code_challenge_method=S256");
    is $s, 400, 'redirect_uri mismatch is a 400 page';
    ok !$h->{location}, 'and does NOT redirect';
}

# authorize rejects a non-S256 challenge (via redirect error)
{
    my ($s, $h) = POTest::hit($app, GET =>
        "/oauth/authorize?response_type=code&client_id=webapp"
      . "&redirect_uri=https%3A%2F%2Fapp.test%2Fcb&state=x"
      . "&code_challenge=$challenge&code_challenge_method=plain");
    is $s, 302, 'plain method redirects';
    like $h->{location}, qr/error=invalid_request/, 'with invalid_request';
}

# --- /token authorization_code ----------------------------------------------
my ($access, $refresh);
{
    my ($s, undef, $body) = form_post('/oauth/token',
        grant_type   => 'authorization_code',
        code         => $code,
        redirect_uri => 'https://app.test/cb',
        code_verifier=> $verifier,
        client_id    => 'webapp',
        client_secret=> 'topsecret',
    );
    is $s, 200, 'token exchange succeeds';
    my $t = jdec($body);
    ok $t->{access_token}, 'access token issued';
    ok $t->{refresh_token}, 'refresh token issued';
    is $t->{token_type}, 'Bearer', 'Bearer type';
    ($access, $refresh) = @{$t}{qw(access_token refresh_token)};

    # the access token is a verifiable ES256 JWT with the right claims
    my $payload = verify($access, server_key(), algs => ['ES256']);
    ok $payload, 'access token verifies with the server key';
    my $claims = jdec($payload);
    is $claims->{iss}, 'https://idp.test', 'iss claim';
    is $claims->{sub}, 'user-42', 'sub is the user';
    is $claims->{client_id}, 'webapp', 'client_id claim';
    is $claims->{scope}, 'read', 'scope claim';
}

sub server_key {
    # the public JWK is served at /jwks.json; import it
    my (undef, undef, $body) = POTest::hit($app, GET => '/oauth/jwks.json');
    my $jwk = File::Raw::JSON::file_json_decode($body)->{keys}[0];
    return Crypt::JWS::Key->from_jwk($jwk);
}

# code is single-use: replay fails
{
    my ($s, undef, $body) = form_post('/oauth/token',
        grant_type => 'authorization_code', code => $code,
        redirect_uri => 'https://app.test/cb', code_verifier => $verifier,
        client_id => 'webapp', client_secret => 'topsecret');
    is $s, 400, 'code replay rejected';
    is jdec($body)->{error}, 'invalid_grant', 'invalid_grant';
}

# wrong client secret -> invalid_client
{
    my ($s, undef, $body) = form_post('/oauth/token',
        grant_type => 'client_credentials',
        client_id => 'service', client_secret => 'wrong');
    is $s, 401, 'wrong secret is 401';
    is jdec($body)->{error}, 'invalid_client', 'invalid_client';
}

# --- refresh rotation + reuse family revoke ---------------------------------
{
    my ($s, undef, $body) = form_post('/oauth/token',
        grant_type => 'refresh_token', refresh_token => $refresh,
        client_id => 'webapp', client_secret => 'topsecret');
    is $s, 200, 'refresh grant succeeds';
    my $t = jdec($body);
    ok $t->{access_token}, 'new access token';
    isnt $t->{refresh_token}, $refresh, 'refresh token rotated';
    my $rotated = $t->{refresh_token};

    # reusing the OLD refresh token triggers family revocation
    my ($s2, undef, $b2) = form_post('/oauth/token',
        grant_type => 'refresh_token', refresh_token => $refresh,
        client_id => 'webapp', client_secret => 'topsecret');
    is $s2, 400, 'reused (rotated) refresh token rejected';

    # and the rotated one is now revoked too (family kill)
    my ($s3) = form_post('/oauth/token',
        grant_type => 'refresh_token', refresh_token => $rotated,
        client_id => 'webapp', client_secret => 'topsecret');
    is $s3, 400, 'the whole family is revoked after reuse';
}

# --- client_credentials -----------------------------------------------------
{
    my ($s, undef, $body) = form_post('/oauth/token',
        grant_type => 'client_credentials', scope => 'read',
        client_id => 'service', client_secret => 'svcsecret');
    is $s, 200, 'client_credentials succeeds';
    my $t = jdec($body);
    ok $t->{access_token}, 'access token';
    ok !$t->{refresh_token}, 'no refresh token for client_credentials';
    my $claims = jdec(verify($t->{access_token}, server_key(), algs=>['ES256']));
    is $claims->{sub}, 'service', 'sub is the client for client_credentials';
}

# --- the registration is what a client may ask for --------------------------
#
# The token endpoint dispatches on a grant_type out of the request body and
# /authorize took its scope out of the query string, so before these checks a
# client could name any grant and any scope it liked and have the server sign
# the result into an at+jwt the resource server then honoured. Reported by
# CPANSec alongside CVE-2026-75628.
{
    # a grant the client is not registered for
    my ($s, undef, $body) = form_post('/oauth/token',
        grant_type => 'client_credentials', scope => 'read',
        client_id => 'narrow', client_secret => 'narrowsecret');
    is $s, 400, 'an unregistered grant_type is refused';
    is jdec($body)->{error}, 'unauthorized_client', 'unauthorized_client';

    # the grant it IS registered for still works
    my ($s2, $h2) = POTest::hit($app, GET =>
        "/oauth/authorize?response_type=code&client_id=narrow"
      . "&redirect_uri=https%3A%2F%2Fnarrow.test%2Fcb&scope=read"
      . "&state=n&code_challenge=$challenge&code_challenge_method=S256");
    is $s2, 302, 'the registered grant still authorizes';
    like $h2->{location}, qr/[?&]code=/, 'with a code';

    # a scope outside the registration, at /authorize
    my (undef, $h3) = POTest::hit($app, GET =>
        "/oauth/authorize?response_type=code&client_id=narrow"
      . "&redirect_uri=https%3A%2F%2Fnarrow.test%2Fcb&scope=read+admin"
      . "&state=n&code_challenge=$challenge&code_challenge_method=S256");
    like $h3->{location}, qr/[?&]error=invalid_scope/,
        'an unregistered scope is invalid_scope';
    unlike $h3->{location}, qr/[?&]code=/, 'and mints no code';

    # a scope outside the registration, at /token
    my ($s4, undef, $b4) = form_post('/oauth/token',
        grant_type => 'client_credentials', scope => 'read admin',
        client_id => 'service', client_secret => 'svcsecret');
    is $s4, 400, 'client_credentials cannot invent a scope either';
    is jdec($b4)->{error}, 'invalid_scope', 'invalid_scope';

    # asking for nothing is always allowed
    my ($s5) = form_post('/oauth/token',
        grant_type => 'client_credentials',
        client_id => 'service', client_secret => 'svcsecret');
    is $s5, 200, 'an empty scope is still fine';

    # a public client authenticates on a client_id anyone can read, so
    # client_credentials must not be available to it (RFC 6749 4.4)
    my ($s6, undef, $b6) = form_post('/oauth/token',
        grant_type => 'client_credentials', scope => 'read',
        client_id => 'browser');
    is $s6, 401, 'a public client cannot use client_credentials';
    is jdec($b6)->{error}, 'invalid_client', 'invalid_client';
}

# --- introspect + revoke ----------------------------------------------------
{
    # mint a fresh token pair to introspect/revoke
    my $v = b64url(random_bytes(32));
    my $ch = b64url(sha256($v));
    my (undef, $h) = POTest::hit($app, GET =>
        "/oauth/authorize?response_type=code&client_id=webapp"
      . "&redirect_uri=https%3A%2F%2Fapp.test%2Fcb&scope=read&state=s"
      . "&code_challenge=$ch&code_challenge_method=S256");
    my ($cd) = $h->{location} =~ /[?&]code=([^&]+)/;
    my (undef, undef, $tb) = form_post('/oauth/token',
        grant_type => 'authorization_code', code => $cd,
        redirect_uri => 'https://app.test/cb', code_verifier => $v,
        client_id => 'webapp', client_secret => 'topsecret');
    my $t = jdec($tb);

    my (undef, undef, $ib) = form_post('/oauth/introspect',
        token => $t->{access_token},
        client_id => 'webapp', client_secret => 'topsecret');
    my $intro = jdec($ib);
    ok $intro->{active}, 'introspect: active access token';
    is $intro->{client_id}, 'webapp', 'introspect client_id';

    my (undef, undef, $ib2) = form_post('/oauth/introspect',
        token => 'garbage.token',
        client_id => 'webapp', client_secret => 'topsecret');
    ok !jdec($ib2)->{active}, 'introspect: garbage inactive (no oracle)';

    my ($rs) = form_post('/oauth/revoke', token => $t->{refresh_token},
        client_id => 'webapp', client_secret => 'topsecret');
    is $rs, 200, 'revoke always 200';
    my ($rr) = form_post('/oauth/token',
        grant_type => 'refresh_token', refresh_token => $t->{refresh_token},
        client_id => 'webapp', client_secret => 'topsecret');
    is $rr, 400, 'revoked refresh token rejected';
}

# --- metadata ---------------------------------------------------------------
{
    my (undef, undef, $body) =
        POTest::hit($app, GET => '/.well-known/oauth-authorization-server');
    my $m = jdec($body);
    is $m->{issuer}, 'https://idp.test', 'metadata issuer equals configured';
    like $m->{authorization_endpoint}, qr{/oauth/authorize$}, 'authorize ep';
    like $m->{token_endpoint}, qr{/oauth/token$}, 'token ep';
    is_deeply $m->{code_challenge_methods_supported}, ['S256'], 'S256 only';
    ok grep({ $_ eq 'authorization_code' }
            @{ $m->{grant_types_supported} }), 'code grant advertised';
    ok !grep({ /implicit|password/ } @{ $m->{grant_types_supported} }),
        'no implicit/password grants';
}

done_testing();
