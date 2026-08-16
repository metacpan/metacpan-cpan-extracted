#!perl
use 5.024;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use POTest;
use POUA;
use MockIdP;

my $idp_app = MockIdP::app();
my $ua = POUA->new(map => { idp_origin() => $idp_app });

my (@logins, $last_tokens);
{
    package FlowApp;
    use Punk;
    use Punk::Plugin::OAuth2;

    session secret => 'flow-test-secret', expires => '1h';

    plugin 'OAuth2';

    oauth2 idp => {
        preset        => 'oidc',
        issuer        => $MockIdP::ISSUER,
        discovery     => 1,
        client_id     => $MockIdP::CLIENT_ID,
        client_secret => $MockIdP::CLIENT_SECRET,
        scope         => 'openid email profile',
        allow_local   => 1,
        ua            => $ua,
        algs          => ['ES256'],
    };

    oauth2_login '/auth' => {
        on_login => sub {
            my ($c, $identity, $tokens) = @_;
            push @logins, $identity;
            $last_tokens = $tokens;
            $c->session->{user} = $identity->{sub};
            return;
        },
        base_url    => POTest::client_origin(),
        redirect_ok => '/welcome',
    };
}
my $app = FlowApp->to_app;

# happy path: initiation -> authorize -> callback -> on_login -> redirect
{
    MockIdP::reset_state();
    my %jar;
    my ($status, $headers) = run_login($app, $idp_app, cookies => \%jar);
    is $status, 302, 'login completes with a redirect';
    is $headers->{location}, '/welcome', 'to redirect_ok';
    is scalar @logins, 1, 'on_login called once';
    my $id = $logins[0];
    is $id->{provider}, 'idp', 'identity provider name';
    is $id->{sub}, 'user-1', 'identity sub';
    is $id->{email}, 'alice@example.com', 'identity email';
    ok $id->{email_verified}, 'email verified';
    ok $last_tokens->access_token, 'tokens delivered';
    ok $last_tokens->refreshable, 'refresh token present';
    is ref $last_tokens->id_claims, 'HASH', 'id_token claims verified';
    is $last_tokens->id_claims->{nonce} && 1, 1, 'nonce claim present';
    ok !$last_tokens->expired, 'not expired';
}

# the initiation records exactly what the authorize URL carries
{
    MockIdP::reset_state();
    my %jar;
    my ($status, $headers) = POTest::hit($app, GET => '/auth/idp',
                                         cookies => \%jar);
    is $status, 302, 'initiation redirects';
    my $url = $headers->{location};
    like $url, qr/\Qcode_challenge_method=S256\E/, 'PKCE S256';
    like $url, qr/[?&]state=[A-Za-z0-9_-]{43}/, '256-bit state';
    like $url, qr/[?&]nonce=[A-Za-z0-9_-]{43}/, 'nonce for OIDC';
    like $url, qr/[?&]redirect_uri=http%3A%2F%2Fapp\.local%2Fauth%2Fidp%2Fcallback/,
        'exact redirect_uri from base_url';
    like $url, qr/[?&]scope=openid%20email%20profile/, 'scope carried';
    ok %jar, 'session cookie set (flow recorded)';
}

# unknown provider is a 404
{
    my ($status) = POTest::hit($app, GET => '/auth/nope');
    is $status, 404, 'unknown provider 404s';
}

# a replayed callback is rejected: the state is deleted on first use
{
    MockIdP::reset_state();
    my %jar;
    my ($s, $h) = POTest::hit($app, GET => '/auth/idp', cookies => \%jar);
    (my $auth = $h->{location}) =~ s/\A\Q@{[idp_origin()]}\E//;
    my (undef, $hi) = POTest::hit($idp_app, GET => $auth);
    (my $cb = $hi->{location}) =~ s/\A\Q@{[POTest::client_origin()]}\E//;

    my ($s1) = POTest::hit($app, GET => $cb, cookies => \%jar);
    is $s1, 302, 'callback works the first time';
    my ($sr, undef, $b) = POTest::hit($app, GET => $cb, cookies => \%jar);
    is $sr, 400, 'replayed callback rejected (state single-use)';
    like $b, qr/Login failed/, 'with the generic failure page';
}

# a callback with a state the session never issued is rejected
{
    MockIdP::reset_state();
    my %jar;
    my ($s) = POTest::hit($app,
        GET => '/auth/idp/callback?code=x&state=never-issued',
        cookies => \%jar);
    is $s, 400, 'unknown state rejected';
}

done_testing();
