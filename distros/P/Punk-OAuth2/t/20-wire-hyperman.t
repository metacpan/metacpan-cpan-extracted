#!perl
use 5.024;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;

BEGIN {
    plan skip_all => 'Hyperman required for the wire tests'
        unless eval { require Hyperman; 1 };
    plan skip_all => 'Fetch required for the wire tests'
        unless eval { require Fetch; 1 };
}
use POSpawn;
use POTest;

# The IdP runs under a real prefork Hyperman; the client app runs in
# process and drives a REAL Fetch (standalone loop) at it, so every
# outbound call - discovery, token exchange, JWKS - crosses a real
# socket through the fetch_abi C path. ($c->ua is not used here: it is
# bound to the worker's Hyperman loop, which a PSGI-called test process
# is not running.) A hard alarm guards against any stall.

my $idp = idp_start();
ok $idp->{pid}, 'MockIdP spawned under Hyperman';

# One Fetch for both the provider's calls and the browser role: two
# Fetch instances in a single process share a standalone loop and
# deadlock, and one agent with max_redirects => 0 serves both here (the
# provider's calls are single 200s; the authorize 302 we parse by hand).
my $client_ua = Fetch->new(timeout => 10, max_redirects => 0,
                           tls_verify => 0);

my (@logins, $tokens);
{
    package WireApp;
    use Punk;
    use Punk::Plugin::OAuth2;
    session secret => 'wire-secret';
    plugin 'OAuth2';
    oauth2 idp => {
        preset        => 'oidc',
        issuer        => $idp->{issuer},
        discovery     => 1,
        client_id     => 'test-client',
        client_secret => 'test-secret',
        allow_local   => 1,
        algs          => ['ES256'],
        ua            => $client_ua,   # real Fetch, standalone loop
    };
    oauth2_login '/auth' => {
        on_login => sub {
            my ($c, $identity, $t) = @_;
            push @logins, $identity;
            $tokens = $t;
            return;
        },
        base_url => POTest::client_origin(),
    };
}
my $app = WireApp->to_app;
my $browser = $client_ua;   # same agent (see above)

# No alarm/SIGALRM guard here: Fetch uses SIGALRM for its own request
# timeouts, so installing a handler would disable them and a stalled
# socket would hang forever. Every Fetch above carries timeout => 10,
# which bounds each call on its own.
my $ok = eval {
    # full login: client (in process, real Fetch over the wire) -> IdP
    # (real socket, real Hyperman) -> client
    my %jar;
    my ($s, $h) = POTest::hit($app, GET => '/auth/idp', cookies => \%jar);
    is $s, 302, 'initiation redirects (discovery crossed the wire)';
    like $h->{location}, qr/\A\Q$idp->{issuer}\E\/authorize\?/,
        'to the wire IdP';

    my $res = $browser->get($h->{location})->get;
    is $res->status, 302, 'IdP authorize answers over the wire';
    (my $cb = $res->header('location'))
        =~ s/\A\Q@{[POTest::client_origin()]}\E//;

    my ($s2) = POTest::hit($app, GET => $cb, cookies => \%jar);
    is $s2, 302, 'callback completes (token exchange crossed the wire)';
    is scalar @logins, 1, 'on_login called';
    is $logins[0]{sub}, 'user-1', 'identity verified via wire JWKS';
    ok $tokens->access_token, 'tokens delivered over the wire';

    # a refresh grant, also over the real socket
    my $provider = Punk::Plugin::OAuth2::state_for('WireApp')
        ->{providers}{idp};
    my $fresh = $provider->refresh(undef, $tokens);
    ok $fresh && $fresh->access_token, 'refresh grant over the wire';

    1;
};
diag "wire failure: $@" unless $ok;

my $log = idp_stop($idp);
unlike $log // '', qr/Traceback|panic|Segmentation/,
    'IdP log free of crashes';

done_testing();
