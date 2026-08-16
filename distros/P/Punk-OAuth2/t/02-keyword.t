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
my %idp = (
    preset => 'oidc', issuer => $MockIdP::ISSUER, discovery => 1,
    client_id => $MockIdP::CLIENT_ID,
    client_secret => $MockIdP::CLIENT_SECRET,
    allow_local => 1, ua => $ua, algs => ['ES256'],
);

# plugin-first ordering: keyword after registration builds immediately
{
    package PluginFirst;
    use Punk;
    use Punk::Plugin::OAuth2;
    session secret => 's1';
    plugin 'OAuth2';
    oauth2 idp => { %idp };
    oauth2_login '/auth' => {
        on_login => sub { return },
        base_url => POTest::client_origin(),
    };
}
{
    my ($s, $h) = POTest::hit(PluginFirst->to_app, GET => '/auth/idp',
                              cookies => {});
    is $s, 302, 'plugin-first ordering serves';
}

# keyword-first ordering
{
    package KwFirst;
    use Punk;
    use Punk::Plugin::OAuth2;
    session secret => 's2';
    oauth2 idp => { %idp };
    oauth2_login '/auth' => {
        on_login => sub { return },
        base_url => POTest::client_origin(),
    };
    plugin 'OAuth2';
}
{
    my ($s) = POTest::hit(KwFirst->to_app, GET => '/auth/idp',
                          cookies => {});
    is $s, 302, 'keyword-first ordering serves';
}

# tripwire: keyword without registration croaks at to_app
{
    package Forgot;
    use Punk;
    use Punk::Plugin::OAuth2;
    session secret => 's3';
    oauth2 idp => { %idp };
}
{
    my $app = eval { Forgot->to_app };
    like $@, qr/never registered/, 'unregistered keyword croaks at to_app';
}

# registered but no providers croaks at to_app
{
    package Empty;
    use Punk;
    use Punk::Plugin::OAuth2;
    plugin 'OAuth2';
}
{
    my $app = eval { Empty->to_app };
    like $@, qr/no oauth2 providers/, 'no providers croaks at to_app';
}

# on_login as a Controller#method target
{
    package CtrlApp::Controller::Auth;
    sub landed { my ($c, $identity) = @_;
                 $CtrlApp::hits++; return }

    package CtrlApp;
    use Punk;
    use Punk::Plugin::OAuth2;
    session secret => 's4';
    plugin 'OAuth2';
    oauth2 idp => { %idp };
    oauth2_login '/auth' => {
        on_login => 'Auth#landed',
        base_url => POTest::client_origin(),
    };
}
{
    MockIdP::reset_state();
    my ($s) = run_login(CtrlApp->to_app, $idp_app, cookies => {});
    is $s, 302, 'Controller#method on_login completes';
    is $CtrlApp::hits, 1, 'and was called';
}

# a typo'd on_login target croaks at boot
{
    package BadTarget;
    use Punk;
    use Punk::Plugin::OAuth2;
    session secret => 's5';
    plugin 'OAuth2';
    oauth2 idp => { %idp };
    my $err = do { local $@; eval {
        oauth2_login '/auth' => {
            on_login => 'Auth#nosuch',
            base_url => POTest::client_origin(),
        };
    }; $@ };
    ::like($err, qr/on_login/, 'bad on_login target croaks at boot');
}

# no session keyword croaks at mount
{
    package NoSession;
    use Punk;
    use Punk::Plugin::OAuth2;
    plugin 'OAuth2';
    oauth2 idp => { %idp };
    my $err = do { local $@; eval {
        oauth2_login '/auth' => {
            on_login => sub { return },
            base_url => POTest::client_origin(),
        };
    }; $@ };
    ::like($err, qr/session/, 'missing session keyword croaks');
}

# provider config errors croak at declaration (registered app)
{
    package BadProvider;
    use Punk;
    use Punk::Plugin::OAuth2;
    session secret => 's6';
    plugin 'OAuth2';
    my $err = do { local $@; eval { oauth2 broken => {} }; $@ };
    ::like($err, qr/client_id/, 'missing client_id croaks');
    $err = do { local $@; eval {
        oauth2 nodisco => { client_id => 'x', client_secret => 'y' };
    }; $@ };
    ::like($err, qr/authorization_endpoint/, 'missing endpoints croak');
    $err = do { local $@; eval {
        oauth2 ssrf => { client_id => 'x', client_secret => 'y',
                         issuer => 'http://internal.example',
                         discovery => 1 };
    }; $@ };
    ::like($err, qr/unsafe issuer/, 'non-https issuer croaks (SSRF guard)');
    oauth2 ok => { %idp };   # leave one so the tripwire stays quiet
}
{ ok(BadProvider->to_app, 'BadProvider app still boots'); }

done_testing();
