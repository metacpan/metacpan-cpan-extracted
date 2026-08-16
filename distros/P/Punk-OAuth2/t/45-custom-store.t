#!perl
use 5.024;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use POTest;
use MemStore;
use Crypt::JWS qw(b64url random_bytes sha256 verify);
use Crypt::JWS::Key ();
use File::Raw::JSON ();
use MIME::Base64 ();

# Prove the documented store contract: an app-supplied in-memory store
# drives the full authorization server exactly like the shipped DBI one.
my $store = MemStore->new;
$store->client_put({
    client_id     => 'webapp',
    secret        => 'topsecret',
    redirect_uris => ['https://app.test/cb'],
    scopes        => 'read write',
});

{
    package CustomIdP;
    use Punk;
    use Punk::Plugin::OAuth2;
    plugin 'OAuth2';
    oauth2_server '/oauth' => {
        issuer       => 'https://idp.test',
        store        => $store,          # a plain object, not a dsn
        authenticate => sub { 'user-9' },
    };
}
my $app = CustomIdP->to_app;

sub jdec { File::Raw::JSON::file_json_decode($_[0]) }
sub form_post {
    my ($path, %f) = @_;
    my $body = join '&', map {
        "$_=" . ($f{$_} =~ s/([^A-Za-z0-9\-._~])/sprintf '%%%02X', ord $1/ger)
    } sort keys %f;
    return POTest::hit($app, POST => $path, body => $body,
        type => 'application/x-www-form-urlencoded');
}

my $v  = b64url(random_bytes(32));
my $ch = b64url(sha256($v));

# full code + PKCE flow against the custom store
my (undef, $h) = POTest::hit($app, GET =>
    "/oauth/authorize?response_type=code&client_id=webapp"
  . "&redirect_uri=https%3A%2F%2Fapp.test%2Fcb&scope=read&state=s"
  . "&code_challenge=$ch&code_challenge_method=S256");
my ($code) = $h->{location} =~ /[?&]code=([^&]+)/;
ok $code, 'custom store: authorize issues a code';

my (undef, undef, $tb) = form_post('/oauth/token',
    grant_type => 'authorization_code', code => $code,
    redirect_uri => 'https://app.test/cb', code_verifier => $v,
    client_id => 'webapp', client_secret => 'topsecret');
my $t = jdec($tb);
ok $t->{access_token}, 'custom store: token issued';
ok $t->{refresh_token}, 'custom store: refresh issued';
is jdec(verify($t->{access_token}, server_key(), algs=>['ES256']))->{sub},
   'user-9', 'custom store: subject flows through';

sub server_key {
    my (undef, undef, $b) = POTest::hit($app, GET => '/oauth/jwks.json');
    Crypt::JWS::Key->from_jwk(jdec($b)->{keys}[0]);
}

# single-use code
{
    my ($s) = form_post('/oauth/token',
        grant_type => 'authorization_code', code => $code,
        redirect_uri => 'https://app.test/cb', code_verifier => $v,
        client_id => 'webapp', client_secret => 'topsecret');
    is $s, 400, 'custom store: code is single-use';
}

# wrong secret rejected (digest convention matches)
{
    my ($s) = form_post('/oauth/token', grant_type => 'refresh_token',
        refresh_token => 'x', client_id => 'webapp',
        client_secret => 'nope');
    is $s, 401, 'custom store: wrong client secret rejected';
}

# refresh rotation + reuse-kills-family
{
    my (undef, undef, $rb) = form_post('/oauth/token',
        grant_type => 'refresh_token', refresh_token => $t->{refresh_token},
        client_id => 'webapp', client_secret => 'topsecret');
    my $r = jdec($rb);
    ok $r->{access_token}, 'custom store: refresh grant works';
    isnt $r->{refresh_token}, $t->{refresh_token}, 'custom store: rotated';
    my ($reuse) = form_post('/oauth/token', grant_type => 'refresh_token',
        refresh_token => $t->{refresh_token},
        client_id => 'webapp', client_secret => 'topsecret');
    is $reuse, 400, 'custom store: reused refresh rejected';
    my ($fam) = form_post('/oauth/token', grant_type => 'refresh_token',
        refresh_token => $r->{refresh_token},
        client_id => 'webapp', client_secret => 'topsecret');
    is $fam, 400, 'custom store: family revoked after reuse';
}

done_testing();
