#!perl
use 5.024;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use POTest;
use POUA;
use Crypt::JWS qw(b64url random_bytes sha256);
use File::Raw::JSON ();
use Punk::OAuth2::Server::Store;
use Punk::OAuth2::Checker;

# The whole loop against our OWN authorization server: the phase-4 server
# issues a token, and the phase-3 checker validates it statelessly from
# the server's published JWKS. No MockIdP - the server is the IdP.

my $dbfile = "/tmp/pox-cap-$$.db";
unlink $dbfile;
my $store = Punk::OAuth2::Server::Store->new(dsn => "dbi:SQLite:dbname=$dbfile");
END { unlink $dbfile if $dbfile }

$store->client_put({
    client_id     => 'api-client',
    secret        => 's3cr3t',
    redirect_uris => ['https://client/cb'],
    # every grant this test exercises has to be registered: the token
    # endpoint dispatches on what the client asks for, and a grant that is
    # not on the client's own row is refused
    grant_types   => 'authorization_code refresh_token client_credentials',
    scopes        => 'read',
});

{
    package IdP;
    use Punk;
    use Punk::Plugin::OAuth2;
    plugin 'OAuth2';
    oauth2_server '/oauth' => {
        issuer       => 'https://idp.local',
        store        => $store,
        authenticate => sub { 'alice' },
    };
}
my $idp = IdP->to_app;

sub form_post {
    my ($path, %f) = @_;
    my $body = join '&', map {
        "$_=" . ($f{$_} =~ s/([^A-Za-z0-9\-._~])/sprintf '%%%02X', ord $1/ger)
    } sort keys %f;
    return POTest::hit($idp, POST => $path, body => $body,
        type => 'application/x-www-form-urlencoded');
}
sub jdec { File::Raw::JSON::file_json_decode($_[0]) }

# get an access token through the full code+PKCE flow
my $verifier  = b64url(random_bytes(32));
my $challenge = b64url(sha256($verifier));
my (undef, $h) = POTest::hit($idp, GET =>
    "/oauth/authorize?response_type=code&client_id=api-client"
  . "&redirect_uri=https%3A%2F%2Fclient%2Fcb&scope=read&state=z"
  . "&code_challenge=$challenge&code_challenge_method=S256");
my ($code) = $h->{location} =~ /[?&]code=([^&]+)/;
my (undef, undef, $tb) = form_post('/oauth/token',
    grant_type => 'authorization_code', code => $code,
    redirect_uri => 'https://client/cb', code_verifier => $verifier,
    client_id => 'api-client', client_secret => 's3cr3t');
my $access = jdec($tb)->{access_token};
ok $access, 'got an access token from our own server';

# the phase-3 checker validates it against the server's JWKS (over the
# POUA seam pointed at the IdP app)
my $ua = POUA->new(map => { 'https://idp.local' => $idp });
my $checker = Punk::OAuth2::Checker->jwt(
    issuer   => 'https://idp.local',
    audience => 'https://idp.local',
    jwks_url => 'https://idp.local/oauth/jwks.json',
    algs     => ['ES256'],
    ua       => $ua,
    allow_local => 1,
);

# a resource server guarded by that checker
{
    package RS;
    use Punk;
    my $g = Punk::OAuth2::Checker->guard($checker, scopes => ['read']);
    my $api = under '/api' => $g;
    $api->get('/data' => sub {
        my ($c) = @_;
        return $c->json({ who => $c->stash->{auth}{oauth}{sub},
                          client => $c->stash->{auth}{oauth}{client_id} });
    });
}
my $rs = RS->to_app;

# the token our server issued is accepted by our checker, statelessly
{
    my ($s, undef, $body) = POTest::hit($rs, GET => '/api/data',
        headers => { Authorization => "Bearer $access" });
    is $s, 200, 'the checker accepts our server-issued token';
    my $d = jdec($body);
    is $d->{who}, 'alice', 'subject flows through end to end';
    is $d->{client}, 'api-client', 'client_id claim visible to the RS';
}

# a token for a different scope is refused by the read-scoped guard:
# mint a client_credentials token (sub=client, scope empty)
{
    my (undef, undef, $cb) = form_post('/oauth/token',
        grant_type => 'client_credentials',
        client_id => 'api-client', client_secret => 's3cr3t');
    my $noscope = jdec($cb)->{access_token};
    my ($s, $hh) = POTest::hit($rs, GET => '/api/data',
        headers => { Authorization => "Bearer $noscope" });
    is $s, 403, 'a token lacking the scope is 403';
    like $hh->{'www-authenticate'}, qr/insufficient_scope/,
        'insufficient_scope challenge';
}

# a garbage token is 401
{
    my ($s) = POTest::hit($rs, GET => '/api/data',
        headers => { Authorization => 'Bearer nope.nope.nope' });
    is $s, 401, 'a forged token is 401';
}

done_testing();
