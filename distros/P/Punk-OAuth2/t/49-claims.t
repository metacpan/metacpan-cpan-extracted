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

# Private claims, through the `claims` hook.
#
# Why a hook and not a token-request parameter: a resource server usually has
# to know something the standard claims cannot say - which of the user's own
# credentials this token acts as, which project it is for - and that decision
# belongs to the moment the USER approves, not to the moment the CLIENT asks.
# So the hook runs at /authorize, what it returns is bound to the code, and
# the token request cannot influence it at all.
#
# The assertion that matters most here is the negative one: a private claim
# must never overwrite a registered claim. A hook able to set `aud` or `exp`
# would be a way around the audience and expiry checks rather than an addition
# to them.

my $dbfile = "/tmp/pox-claims-$$.db";
unlink $dbfile;
my $store = Punk::OAuth2::Server::Store->new(dsn => "dbi:SQLite:dbname=$dbfile");
END { unlink $dbfile if $dbfile }

$store->client_put({
    client_id     => 'webapp',
    secret        => 'topsecret',
    redirect_uris => ['https://app.test/cb'],
    scopes        => 'read mcp',
});

my $user = 'user-42';
my $hook_calls = 0;
my @hook_args;

{
    package IdPApp;
    use Punk;
    use Punk::Plugin::OAuth2;
    plugin 'OAuth2';
    oauth2_server '/oauth' => {
        issuer       => 'https://idp.test',
        store        => $store,
        authenticate => sub { $user },
        claims       => sub {
            my ($c, $client, $uid, $scopes) = @_;
            $hook_calls++;
            @hook_args = ($client->{client_id}, $uid, [@$scopes]);
            return {
                apip_key   => 7,
                apip_proxy => 42,
                # Every one of these is a registered claim and must be
                # ignored: a hook must not be able to move them.
                aud        => 'https://elsewhere.test',
                exp        => time + 86_400 * 365,
                sub        => 'somebody-else',
                iss        => 'https://evil.test',
            };
        },
    };
}
my $app = IdPApp->to_app;

sub jdec { File::Raw::JSON::file_json_decode($_[0]) }
sub enc  { my $v = defined $_[0] ? $_[0] : '';
           $v =~ s/([^A-Za-z0-9\-._~])/sprintf '%%%02X', ord $1/ge; $v }

sub server_key {
    my (undef, undef, $body) = POTest::hit($app, GET => '/oauth/jwks.json');
    return Crypt::JWS::Key->from_jwk(jdec($body)->{keys}[0]);
}
sub claims_of {
    my ($at) = @_;
    my $payload = verify($at, server_key(), algs => ['ES256']);
    return $payload ? jdec($payload) : undef;
}

sub get_token {
    my $verifier  = b64url(random_bytes(32));
    my $challenge = b64url(sha256($verifier));
    my (undef, $h) = POTest::hit($app, GET =>
        "/oauth/authorize?response_type=code&client_id=webapp"
      . "&redirect_uri=" . enc('https://app.test/cb')
      . "&scope=" . enc('read mcp') . "&state=xyz"
      . "&code_challenge=$challenge&code_challenge_method=S256");
    my ($code) = ($h->{location} || '') =~ /[?&]code=([^&]+)/;
    return unless $code;
    my $body = join '&',
        'grant_type=authorization_code', "code=" . enc($code),
        'redirect_uri=' . enc('https://app.test/cb'),
        'code_verifier=' . enc($verifier),
        'client_id=webapp', 'client_secret=' . enc('topsecret');
    my (undef, undef, $b) = POTest::hit($app, POST => '/oauth/token',
        body => $body, type => 'application/x-www-form-urlencoded');
    return jdec($b);
}

# ---- the hook runs where it should, and its claims are minted --------------

my $t = get_token();
ok $t && $t->{access_token}, 'a token was issued';
is $hook_calls, 1, 'the claims hook ran once, at authorize';
is $hook_args[0], 'webapp', '...with the client';
is $hook_args[1], $user, '...the user';
is_deeply [sort @{ $hook_args[2] || [] }], ['mcp', 'read'], '...and the scopes';

my $c = claims_of($t->{access_token});
ok $c, 'the access token verifies';
is $c->{apip_key}, 7, 'a private claim reaches the token';
is $c->{apip_proxy}, 42, '...and so does the second';

# ---- and cannot overwrite a registered claim -------------------------------

is $c->{iss}, 'https://idp.test', 'the hook cannot move the issuer';
is $c->{sub}, $user, 'nor the subject';
is $c->{aud}, 'https://idp.test',
   'nor the audience, which would be a way past every audience check';
cmp_ok $c->{exp}, '<', time + 3600,
   'nor the expiry, which would make a token outlive its grant';

# ---- they survive rotation, twice ------------------------------------------
#
# Twice for the reason the resource is: carrying them onto the access token
# but not onto the replacement refresh record passes one rotation and loses
# them on the next.

{
    my $rt = $t->{refresh_token};
    ok $rt, 'a refresh token was issued';
    for my $round (1, 2) {
        my (undef, undef, $b) = POTest::hit($app, POST => '/oauth/token',
            body => 'grant_type=refresh_token&refresh_token=' . enc($rt)
                  . '&client_id=webapp&client_secret=' . enc('topsecret'),
            type => 'application/x-www-form-urlencoded');
        my $r = jdec($b);
        ok $r->{access_token}, "rotation $round issued a token";
        my $rc = claims_of($r->{access_token});
        is $rc->{apip_key}, 7, "...keeping the private claim through rotation $round";
        is $rc->{apip_proxy}, 42, "...and the second through rotation $round";
        $rt = $r->{refresh_token};
    }
    is $hook_calls, 1, 'and the hook was never called again: a refresh is the '
                     . 'client talking, and cannot change what was approved';
}

# ---- no hook, no extra claims ----------------------------------------------

{
    my $plain = "/tmp/pox-claims-none-$$.db";
    unlink $plain;
    my $st2 = Punk::OAuth2::Server::Store->new(dsn => "dbi:SQLite:dbname=$plain");
    $st2->client_put({ client_id => 'webapp', secret => 'topsecret',
                       redirect_uris => ['https://app.test/cb'],
                       scopes => 'read' });
    {
        package PlainApp;
        use Punk;
        use Punk::Plugin::OAuth2;
        plugin 'OAuth2';
        oauth2_server '/oauth' => {
            issuer => 'https://idp.test', store => $st2,
            authenticate => sub { 'user-42' },
        };
    }
    my $papp = PlainApp->to_app;
    my $verifier  = b64url(random_bytes(32));
    my $challenge = b64url(sha256($verifier));
    my (undef, $h) = POTest::hit($papp, GET =>
        "/oauth/authorize?response_type=code&client_id=webapp"
      . "&redirect_uri=" . enc('https://app.test/cb')
      . "&scope=read&state=x"
      . "&code_challenge=$challenge&code_challenge_method=S256");
    my ($code) = ($h->{location} || '') =~ /[?&]code=([^&]+)/;
    ok $code, 'a server with no claims hook still issues codes';
    my (undef, undef, $b) = POTest::hit($papp, POST => '/oauth/token',
        body => 'grant_type=authorization_code&code=' . enc($code)
              . '&redirect_uri=' . enc('https://app.test/cb')
              . '&code_verifier=' . enc($verifier)
              . '&client_id=webapp&client_secret=' . enc('topsecret'),
        type => 'application/x-www-form-urlencoded');
    ok jdec($b)->{access_token}, '...and tokens';
    unlink $plain;
}

done_testing;
