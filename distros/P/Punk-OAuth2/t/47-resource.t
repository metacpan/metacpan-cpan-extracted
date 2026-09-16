#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;

BEGIN {
    plan skip_all => 'DBI and DBD::SQLite required for the DBI-backed store'
        unless eval { require DBI; require DBD::SQLite; 1 };
}
use POTest;
use Crypt::JWS qw(b64url random_bytes sha256 verify);
use Crypt::JWS::Key ();
use File::Raw::JSON ();
use Punk::OAuth2::Server::Store;

# RFC 8707 resource indicators.
#
# What this buys, and why the audience is the whole point: one authorization
# server fronts many resource servers, so a token minted for one of them must
# be refused by the others. Binding `aud` to the requested resource is what
# makes that refusal possible at all - a checker validating audience then does
# the work, and a stolen or misdirected token is worth nothing anywhere but
# where it was asked for.
#
# The registration is the authority, deny by default, exactly as redirect_uris
# already works: a client that registered no resources may request none.

my $A = 'https://a.test/mcp';
my $B = 'https://b.test/mcp';
my $UNREG = 'https://evil.test/mcp';

my $dbfile = "/tmp/pox-res-$$.db";
unlink $dbfile;
my $store = Punk::OAuth2::Server::Store->new(dsn => "dbi:SQLite:dbname=$dbfile");
END { unlink $dbfile if $dbfile }

$store->client_put({
    client_id     => 'webapp',
    secret        => 'topsecret',
    redirect_uris => ['https://app.test/cb'],
    scopes        => 'read write',
    resources     => [$A, $B],
});
$store->client_put({
    client_id   => 'service',
    secret      => 'svcsecret',
    grant_types => 'client_credentials',
    scopes      => 'read',
    resources   => [$A],
});
# Registered no resources at all: may ask for none.
$store->client_put({
    client_id     => 'plain',
    secret        => 'plainsecret',
    redirect_uris => ['https://plain.test/cb'],
    scopes        => 'read',
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

sub jdec { File::Raw::JSON::file_json_decode($_[0]) }
sub enc  { my $v = defined $_[0] ? $_[0] : '';
           $v =~ s/([^A-Za-z0-9\-._~])/sprintf '%%%02X', ord $1/ge; $v }

# Built by hand rather than from a hash: `resource` is REPEATABLE, and a hash
# cannot carry the same key twice, which is the whole case under test.
sub raw_post {
    my ($path, $body) = @_;
    return POTest::hit($app, POST => $path, body => $body,
        type => 'application/x-www-form-urlencoded');
}

sub server_key {
    my (undef, undef, $body) = POTest::hit($app, GET => '/oauth/jwks.json');
    return Crypt::JWS::Key->from_jwk(jdec($body)->{keys}[0]);
}

sub claims_of {
    my ($access) = @_;
    my $payload = verify($access, server_key(), algs => ['ES256']);
    return $payload ? jdec($payload) : undef;
}

# Drive authorize and return the code (or the redirect location on an error).
sub authorize {
    my (%o) = @_;
    my $verifier  = b64url(random_bytes(32));
    my $challenge = b64url(sha256($verifier));
    my $q = "/oauth/authorize?response_type=code"
          . "&client_id=" . enc($o{client_id})
          . "&redirect_uri=" . enc($o{redirect_uri})
          . "&scope=read&state=xyz"
          . "&code_challenge=$challenge&code_challenge_method=S256";
    $q .= "&resource=" . enc($_) for @{ $o{resources} || [] };
    my ($s, $h) = POTest::hit($app, GET => $q);
    my ($code) = ($h->{location} || '') =~ /[?&]code=([^&]+)/;
    return { status => $s, location => $h->{location},
             code => $code, verifier => $verifier };
}

sub exchange {
    my (%o) = @_;
    my $body = join '&',
        'grant_type=authorization_code',
        'code=' . enc($o{code}),
        'redirect_uri=' . enc($o{redirect_uri}),
        'code_verifier=' . enc($o{verifier}),
        'client_id=' . enc($o{client_id}),
        'client_secret=' . enc($o{client_secret});
    $body .= '&resource=' . enc($_) for @{ $o{resources} || [] };
    my ($s, undef, $b) = raw_post('/oauth/token', $body);
    return ($s, jdec($b));
}

# ---- the audience is the requested resource --------------------------------

{
    my $a = authorize(client_id => 'webapp',
                      redirect_uri => 'https://app.test/cb',
                      resources => [$A]);
    is $a->{status}, 302, 'authorize accepts a registered resource';
    ok $a->{code}, '...and issues a code';

    my ($s, $t) = exchange(code => $a->{code}, verifier => $a->{verifier},
        redirect_uri => 'https://app.test/cb',
        client_id => 'webapp', client_secret => 'topsecret');
    is $s, 200, 'the code exchanges';
    my $c = claims_of($t->{access_token});
    is $c->{aud}, $A,
       'the access token is audienced for the resource, not the issuer';
    isnt $c->{aud}, 'https://idp.test', '...so it is not spendable everywhere';
}

# Two resources: aud becomes an array, which is what a multi-audience token is.
{
    my $a = authorize(client_id => 'webapp',
                      redirect_uri => 'https://app.test/cb',
                      resources => [$A, $B]);
    my ($s, $t) = exchange(code => $a->{code}, verifier => $a->{verifier},
        redirect_uri => 'https://app.test/cb',
        client_id => 'webapp', client_secret => 'topsecret');
    is $s, 200, 'two resources exchange';
    my $c = claims_of($t->{access_token});
    is ref $c->{aud}, 'ARRAY', 'aud is an array when two were requested';
    is_deeply [sort @{ $c->{aud} }], [sort ($A, $B)], '...holding both';
}

# ---- nothing requested is the old behaviour, unchanged ---------------------

{
    my $a = authorize(client_id => 'webapp',
                      redirect_uri => 'https://app.test/cb');
    my ($s, $t) = exchange(code => $a->{code}, verifier => $a->{verifier},
        redirect_uri => 'https://app.test/cb',
        client_id => 'webapp', client_secret => 'topsecret');
    is $s, 200, 'a request naming no resource still works';
    is claims_of($t->{access_token})->{aud}, 'https://idp.test',
       '...and its audience is the issuer, exactly as before RFC 8707';
}

# ---- deny by default -------------------------------------------------------

{
    my $a = authorize(client_id => 'webapp',
                      redirect_uri => 'https://app.test/cb',
                      resources => [$UNREG]);
    is $a->{status}, 302, 'an unregistered resource redirects';
    like $a->{location}, qr/error=invalid_target/,
       '...with invalid_target, because the registration is the authority';
    ok !$a->{code}, '...and issues no code';

    my $p = authorize(client_id => 'plain',
                      redirect_uri => 'https://plain.test/cb',
                      resources => [$A]);
    like $p->{location}, qr/error=invalid_target/,
       'a client that registered NO resources may request none';
}

# ---- the token request may narrow, never widen -----------------------------

{
    my $a = authorize(client_id => 'webapp',
                      redirect_uri => 'https://app.test/cb',
                      resources => [$A]);
    my ($s, $t) = exchange(code => $a->{code}, verifier => $a->{verifier},
        redirect_uri => 'https://app.test/cb',
        client_id => 'webapp', client_secret => 'topsecret',
        resources => [$B]);
    is $s, 400, 'naming a resource the code was not issued for is refused';
    is $t->{error}, 'invalid_target', '...as invalid_target';
}

{
    my $a = authorize(client_id => 'webapp',
                      redirect_uri => 'https://app.test/cb',
                      resources => [$A, $B]);
    my ($s, $t) = exchange(code => $a->{code}, verifier => $a->{verifier},
        redirect_uri => 'https://app.test/cb',
        client_id => 'webapp', client_secret => 'topsecret',
        resources => [$A]);
    is $s, 200, 'narrowing to one of the code"s resources is allowed';
    is claims_of($t->{access_token})->{aud}, $A,
       '...and the token is audienced for just that one';
}

# ---- a rotation must not widen the audience --------------------------------
#
# Twice, on purpose. Carrying the resource onto the access token but not onto
# the replacement refresh record passes one rotation and silently falls back
# to the issuer on the next.

{
    my $a = authorize(client_id => 'webapp',
                      redirect_uri => 'https://app.test/cb',
                      resources => [$A]);
    my ($s, $t) = exchange(code => $a->{code}, verifier => $a->{verifier},
        redirect_uri => 'https://app.test/cb',
        client_id => 'webapp', client_secret => 'topsecret');
    my $rt = $t->{refresh_token};

    for my $round (1, 2) {
        my ($rs, undef, $rb) = raw_post('/oauth/token',
            'grant_type=refresh_token&refresh_token=' . enc($rt)
          . '&client_id=webapp&client_secret=' . enc('topsecret'));
        is $rs, 200, "rotation $round succeeds";
        my $r = jdec($rb);
        is claims_of($r->{access_token})->{aud}, $A,
           "...and the audience survives rotation $round";
        $rt = $r->{refresh_token};
    }
}

# ---- client_credentials has no code, so the registration decides -----------

{
    my ($s, undef, $b) = raw_post('/oauth/token',
        'grant_type=client_credentials&client_id=service'
      . '&client_secret=' . enc('svcsecret')
      . '&scope=read&resource=' . enc($A));
    is $s, 200, 'client_credentials with a registered resource succeeds';
    is claims_of(jdec($b)->{access_token})->{aud}, $A,
       '...audienced for it';

    my ($s2, undef, $b2) = raw_post('/oauth/token',
        'grant_type=client_credentials&client_id=service'
      . '&client_secret=' . enc('svcsecret')
      . '&scope=read&resource=' . enc($UNREG));
    is $s2, 400, 'and an unregistered one is refused';
    is jdec($b2)->{error}, 'invalid_target', '...as invalid_target';
}

done_testing;
