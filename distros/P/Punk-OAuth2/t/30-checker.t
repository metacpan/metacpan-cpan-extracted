#!perl
use 5.024;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use POTest;
use Punk::OAuth2::Checker;
use Crypt::JWS qw(sign);
use Crypt::JWS::Key ();
use File::Raw::JSON ();

my $KEY = Crypt::JWS::Key->generate('ES256');
my $KID = $KEY->thumbprint;
my $ISS = 'https://idp.test';
my $AUD = 'https://api.test';

sub token {
    my (%claims) = @_;
    my $now = time;
    return sign($KEY, File::Raw::JSON::file_json_encode({
        iss => $ISS, aud => $AUD, sub => 'user-1',
        exp => $now + 300, iat => $now, scope => 'read write', %claims,
    }), alg => 'ES256', kid => $KID);
}

my $jwt = Punk::OAuth2::Checker->jwt(
    issuer => $ISS, audience => $AUD, key => $KEY, algs => ['ES256']);

# a guarded app exercising guard + _check + stash end to end
{
    package RSApp;
    use Punk;
    my $j = $jwt;
    my $g = Punk::OAuth2::Checker->guard($j, scopes => ['read']);
    my $api = under '/api' => $g;
    $api->get('/me' => sub {
        my ($c) = @_;
        return $c->json({ sub => $c->stash->{auth}{oauth}{sub} });
    });
    # a route that calls the checker directly (the OpenAPI-map shape)
    get '/raw' => sub {
        my ($c) = @_;
        my $cred = ($c->req->header('Authorization') // '') =~ s/^Bearer //r;
        my $claims = $j->($cred, $c, 'op', ['read']);
        return $c->json({ ok => $claims ? \1 : \0,
                          err => $c->stash->{'punk.oauth2.error'} });
    };
}
my $app = RSApp->to_app;

sub call {
    my ($path, $auth) = @_;
    return POTest::hit($app, GET => $path,
        ($auth ? (headers => { Authorization => "Bearer $auth" }) : ()));
}

# guard: happy path
{
    my ($s, undef, $body) = call('/api/me', token());
    is $s, 200, 'valid token passes the guard';
    is File::Raw::JSON::file_json_decode($body)->{sub}, 'user-1',
        'claims stashed under auth.oauth';
}

# guard: no credential -> 401
{
    my ($s, $h) = call('/api/me');
    is $s, 401, 'no token is 401';
    like $h->{'www-authenticate'}, qr/^Bearer realm="api"/,
        'WWW-Authenticate challenge';
}

# guard: invalid token -> 401 invalid_token
{
    my ($s, $h) = call('/api/me', 'not.a.jwt');
    is $s, 401, 'garbage token is 401';
    like $h->{'www-authenticate'}, qr/error="invalid_token"/,
        'invalid_token error';
}

# guard: valid signature, missing scope -> 403 insufficient_scope
{
    my ($s, $h) = call('/api/me', token(scope => 'write'));
    is $s, 403, 'missing scope is 403';
    like $h->{'www-authenticate'}, qr/error="insufficient_scope"/,
        'insufficient_scope error';
    like $h->{'www-authenticate'}, qr/scope="read"/, 'names the scope';
}

# claim matrix via the raw checker
{
    my $ok = sub {
        my ($s, undef, $b) = call('/raw', $_[0]);
        return File::Raw::JSON::file_json_decode($b)->{ok} ? 1 : 0;
    };
    ok $ok->(token()), 'valid token accepted';
    ok !$ok->(token(iss => 'https://evil')), 'wrong issuer rejected';
    ok !$ok->(token(aud => 'https://other')), 'wrong audience rejected';
    ok !$ok->(token(exp => time - 120)), 'expired token rejected (beyond leeway)';
    ok !$ok->(token(nbf => time + 3600)), 'not-yet-valid rejected';
    ok $ok->(token(aud => [$AUD, 'https://x'])), 'audience array containing it';
    ok $ok->(token(scope => 'read admin')), 'scope string superset';
    ok $ok->(token(scope => undef, scp => ['read', 'x'])),
        'scp array accepted';
    ok !$ok->(token(scope => 'write')), 'scope not covered rejected';
}

# leeway: a token 30s expired passes with 60s leeway, fails with 0
{
    my $lax = Punk::OAuth2::Checker->jwt(
        issuer => $ISS, audience => $AUD, key => $KEY,
        algs => ['ES256'], leeway => 60);
    my $strict = Punk::OAuth2::Checker->jwt(
        issuer => $ISS, audience => $AUD, key => $KEY,
        algs => ['ES256'], leeway => 0);
    my $t = token(exp => time - 30);
    my $fake = FakeCtx->new;
    ok $lax->($t, $fake, undef, undef), 'within leeway accepted';
    ok !$strict->($t, $fake, undef, undef), 'outside leeway rejected';
}

# alg allowlist: an ES256 token is rejected by an RS256-only checker
{
    my $rsonly = Punk::OAuth2::Checker->jwt(
        issuer => $ISS, audience => $AUD, key => $KEY, algs => ['RS256']);
    my $fake = FakeCtx->new;
    ok !$rsonly->(token(), $fake, undef, undef),
        'alg outside allowlist rejected';
}

done_testing();

# a minimal context for direct checker calls (stash only)
package FakeCtx;
sub new { bless { stash => {} }, shift }
sub stash { $_[0]{stash} }
