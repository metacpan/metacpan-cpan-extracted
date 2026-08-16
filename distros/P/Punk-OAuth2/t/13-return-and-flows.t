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

{
    package ReturnApp;
    use Punk;
    use Punk::Plugin::OAuth2;
    session secret => 'return-secret';
    plugin 'OAuth2';
    oauth2 idp => {
        preset => 'oidc', issuer => $MockIdP::ISSUER, discovery => 1,
        client_id => $MockIdP::CLIENT_ID,
        client_secret => $MockIdP::CLIENT_SECRET,
        allow_local => 1, ua => $ua, algs => ['ES256'],
    };
    oauth2_login "/auth" => {
        on_login    => sub { return },
        base_url    => POTest::client_origin(),
        redirect_ok => "/home",
    };

    get "/button" => sub {
        my ($c) = @_;
        return { url => $c->oauth2_authurl("idp",
                                           return_to => "/from-btn") };
    };

    get "/refresh" => sub {
        my ($c) = @_;
        my $t = $c->oauth2_refresh("idp", "rt-seed");
        $ReturnApp::GOT = $t;
        return { ok => $t->access_token ? \1 : \0 };
    };
}
my $app = ReturnApp->to_app;

sub full_login {
    my (%opts) = @_;
    MockIdP::reset_state();
    my %jar;
    return run_login($app, $idp_app, cookies => \%jar, %opts);
}

# ?return= same-origin path is honoured
{
    my ($s, $h) = full_login(start => '/auth/idp?return=%2Fafter%3Fx%3D1');
    is $s, 302, 'login with return completes';
    is $h->{location}, '/after?x=1', 'return path honoured';
}

# absolute and protocol-relative return destinations fall back
for my $evil ('https%3A%2F%2Fevil.example%2F', '%2F%2Fevil.example',
              'javascript%3Aalert(1)') {
    my ($s, $h) = full_login(start => "/auth/idp?return=$evil");
    is $s, 302, 'login still completes';
    is $h->{location}, '/home', "open-redirect '$evil' ignored";
}

# flow cap: a fourth concurrent initiation evicts the oldest
{
    MockIdP::reset_state();
    my %jar;
    my @states;
    for my $n (1 .. 4) {
        my ($s, $h) = POTest::hit($app, GET => '/auth/idp',
                                  cookies => \%jar);
        push @states, ($h->{location} =~ /[?&]state=([A-Za-z0-9_-]+)/);
    }
    # complete the FIRST (evicted) flow: must fail
    my ($sr) = POTest::hit($app,
        GET => "/auth/idp/callback?code=x&state=$states[0]",
        cookies => \%jar);
    is $sr, 400, 'oldest flow evicted at the concurrency cap';
    # the newest still lives: complete it properly through the IdP
    my ($s2, $h2) = POTest::hit($app, GET => '/auth/idp',
                                cookies => \%jar);
    (my $auth = $h2->{location}) =~ s/\A\Q@{[idp_origin()]}\E//;
    my (undef, $hi) = POTest::hit($idp_app, GET => $auth);
    (my $cb = $hi->{location}) =~ s/\A\Q@{[POTest::client_origin()]}\E//;
    my ($s3) = POTest::hit($app, GET => $cb, cookies => \%jar);
    is $s3, 302, 'newest flow still completes';
}

# oauth2_authurl helper records a completable flow (route declared in
# the app block above, before compile)
{
    MockIdP::reset_state();
    my %jar;
    my ($s, $h, $body) = POTest::hit($app, GET => '/button',
                                     cookies => \%jar);
    is $s, 200, 'authurl helper responds';
    my ($url) = $body =~ /"url":"([^"]+)"/;
    $url =~ s/\\\//\//g;
    like $url, qr/code_challenge_method=S256/, 'authurl carries PKCE';
    (my $auth = $url) =~ s/\A\Q@{[idp_origin()]}\E//;
    my (undef, $hi) = POTest::hit($idp_app, GET => $auth);
    (my $cb = $hi->{location}) =~ s/\A\Q@{[POTest::client_origin()]}\E//;
    my ($s2, $h2) = POTest::hit($app, GET => $cb, cookies => \%jar);
    is $s2, 302, 'authurl-started flow completes at the callback';
    is $h2->{location}, '/from-btn', 'with its return_to';
}

# oauth2_refresh helper
{
    MockIdP::reset_state();
    my ($s, undef, $body) = POTest::hit($app, GET => '/refresh',
                                        cookies => {});
    is $s, 200, 'refresh helper responds';
    like $body, qr/"ok":true/, 'refresh succeeded';
    isa_ok $ReturnApp::GOT, 'Punk::OAuth2::Tokens', 'refresh result';
    ok $ReturnApp::GOT->access_token, 'fresh access token';
}

done_testing();
