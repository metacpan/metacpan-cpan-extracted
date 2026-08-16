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

my @logins;
{
    package MisbehaveApp;
    use Punk;
    use Punk::Plugin::OAuth2;
    session secret => 'misbehave-secret';
    plugin 'OAuth2';
    oauth2 idp => {
        preset => 'oidc', issuer => $MockIdP::ISSUER, discovery => 1,
        client_id => $MockIdP::CLIENT_ID,
        client_secret => $MockIdP::CLIENT_SECRET,
        allow_local => 1, ua => $ua, algs => ['ES256'],
    };
    oauth2_login '/auth' => {
        on_login => sub { push @logins, $_[1]; return },
        base_url => POTest::client_origin(),
    };
}
my $app = MisbehaveApp->to_app;

# Every mode the IdP can misbehave in must end in a 400 - never a login.
my %modes = (
    wrong_state    => 'authorize returns a different state',
    iss_param_wrong => 'authorize returns a wrong iss parameter',
    expired_code   => 'authorization code expired',
    bad_iss        => 'id_token carries the wrong issuer',
    wrong_nonce    => 'id_token echoes the wrong nonce',
    tamper_sig     => 'id_token signature tampered',
    no_id_token    => 'token response missing the id_token',
    non_json_token => 'token endpoint returns non-JSON',
    refuse_token   => 'token endpoint refuses the grant',
);

for my $mode (sort keys %modes) {
    MockIdP::reset_state();
    $MockIdP::MODE{$mode} = 1;
    @logins = ();
    my %jar;
    my ($status, undef, $body) = run_login($app, $idp_app,
                                           cookies => \%jar);
    is $status, 400, "$modes{$mode} -> 400";
    is scalar @logins, 0, "$mode: on_login never called";
}

# the provider sending error= short-circuits before any exchange
{
    MockIdP::reset_state();
    my %jar;
    my ($s, $h) = POTest::hit($app, GET => '/auth/idp', cookies => \%jar);
    my ($state) = $h->{location} =~ /[?&]state=([A-Za-z0-9_-]+)/;
    my ($sr, undef, $b) = POTest::hit($app,
        GET => "/auth/idp/callback?error=access_denied&state=$state",
        cookies => \%jar);
    is $sr, 400, 'provider error param -> 400';
    unlike $b, qr/access_denied/, 'provider detail not echoed to browser';
}

# a callback whose flow belongs to a DIFFERENT provider is rejected
{
    MockIdP::reset_state();
    # (single provider here: simulate by mangling the provider segment)
    my %jar;
    my ($s, $h) = POTest::hit($app, GET => '/auth/idp', cookies => \%jar);
    (my $auth = $h->{location}) =~ s/\A\Q@{[idp_origin()]}\E//;
    my (undef, $hi) = POTest::hit($idp_app, GET => $auth);
    (my $cb = $hi->{location}) =~ s/\A\Q@{[POTest::client_origin()]}\E//;
    $cb =~ s{/auth/idp/}{/auth/nope/};
    my ($sr) = POTest::hit($app, GET => $cb, cookies => \%jar);
    is $sr, 404, 'callback under an unknown provider 404s';
}

done_testing();
