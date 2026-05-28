#!/usr/bin/env perl
# Tests for AgentBase signing_key integration.
#
# Verifies the AgentBase wiring described in porting-sdk/webhooks.md
# section "AgentBase integration":
#
#   - signing_key option (constructor + accessor + env fallback).
#   - When set, POST /, POST $route/swaig, POST $route/post_prompt are
#     auto-gated by the signature middleware.
#   - Unsigned requests on those routes return 403.
#   - When signing_key is unset, the agent emits a startup warning.

use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request ();
use Digest::SHA qw(hmac_sha1_hex);

use SignalWire::Agent::AgentBase;

# ---------------------------------------------------------------------------
# 1. Accessor + constructor: signing_key option round-trips.
# ---------------------------------------------------------------------------
subtest 'signing_key constructor and accessor' => sub {
    {
        local $ENV{SIGNALWIRE_SIGNING_KEY};
        delete $ENV{SIGNALWIRE_SIGNING_KEY};
        my $a = SignalWire::Agent::AgentBase->new(
            name        => 'a1',
            signing_key => 'PSK-explicit',
        );
        is($a->signing_key, 'PSK-explicit',
           'explicit constructor value retained');
    }
};

subtest 'signing_key falls back to SIGNALWIRE_SIGNING_KEY env' => sub {
    local $ENV{SIGNALWIRE_SIGNING_KEY} = 'PSK-from-env';
    my $a = SignalWire::Agent::AgentBase->new(name => 'a2');
    is($a->signing_key, 'PSK-from-env',
       'env var picked up when no explicit key');
};

subtest 'unset signing_key + no env -> undef' => sub {
    local $ENV{SIGNALWIRE_SIGNING_KEY};
    delete $ENV{SIGNALWIRE_SIGNING_KEY};
    my $a = SignalWire::Agent::AgentBase->new(name => 'a3');
    ok(!defined $a->signing_key || $a->signing_key eq '',
       'no key configured when neither option nor env is set');
};

# ---------------------------------------------------------------------------
# 2. When signing_key set, unsigned POST / -> 403.
# ---------------------------------------------------------------------------
subtest 'auto-mounted middleware rejects unsigned POST /' => sub {
    local $ENV{SIGNALWIRE_SIGNING_KEY};
    delete $ENV{SIGNALWIRE_SIGNING_KEY};
    my $a = SignalWire::Agent::AgentBase->new(
        name           => 'gated',
        signing_key    => 'PSKtest1234567890abcdef',
        proxy_url_base => 'https://example.ngrok.io',
    );
    # Set basic-auth credentials so we know that's not the cause of failure.
    $a->basic_auth_user('u');
    $a->basic_auth_password('p');

    my $app = $a->psgi_app;
    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new('POST' => '/');
        $req->header('Content-Type'   => 'application/json');
        $req->content('{}');
        $req->header('Content-Length' => 2);
        # Provide basic auth so we know 401 isn't the failure mode.
        require MIME::Base64;
        $req->header('Authorization' =>
            'Basic ' . MIME::Base64::encode_base64('u:p', ''));
        my $res = $cb->($req);
        is($res->code, 403, 'unsigned POST / -> 403');
    };
};

# ---------------------------------------------------------------------------
# 3. When signing_key set, properly signed POST / passes the gate.
#    (Lands at SWML handler which will then evaluate basic auth, render
#    a SWML doc, etc.; we just assert it's NOT 403.)
# ---------------------------------------------------------------------------
subtest 'auto-mounted middleware accepts signed POST /' => sub {
    local $ENV{SIGNALWIRE_SIGNING_KEY};
    delete $ENV{SIGNALWIRE_SIGNING_KEY};

    my $key = 'PSKtest1234567890abcdef';
    my $a = SignalWire::Agent::AgentBase->new(
        name           => 'gated2',
        signing_key    => $key,
        proxy_url_base => 'https://example.ngrok.io',
    );
    $a->basic_auth_user('u');
    $a->basic_auth_password('p');

    my $body = '{"call":{"call_id":"abc"}}';
    # The middleware reconstructs the URL from SWML_PROXY_URL_BASE-style
    # logic: we passed proxy_url_base so the agent already exposes it,
    # but the middleware reconstructs from SWML_PROXY_URL_BASE env or
    # X-Forwarded headers — set the env so the URL matches.
    local $ENV{SWML_PROXY_URL_BASE} = 'https://example.ngrok.io';
    my $sig = hmac_sha1_hex('https://example.ngrok.io/' . $body, $key);

    my $app = $a->psgi_app;
    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new('POST' => '/');
        $req->header('Content-Type'           => 'application/json');
        $req->header('X-SignalWire-Signature' => $sig);
        require MIME::Base64;
        $req->header('Authorization' =>
            'Basic ' . MIME::Base64::encode_base64('u:p', ''));
        $req->content($body);
        $req->header('Content-Length' => length($body));
        my $res = $cb->($req);
        isnt($res->code, 403,
             'signed POST / passes the signature gate (not 403)');
    };
};

# ---------------------------------------------------------------------------
# 4. POST /swaig with bad signature -> 403, app's SWAIG handler not reached.
# ---------------------------------------------------------------------------
subtest 'unsigned POST /swaig -> 403' => sub {
    local $ENV{SIGNALWIRE_SIGNING_KEY};
    delete $ENV{SIGNALWIRE_SIGNING_KEY};

    my $a = SignalWire::Agent::AgentBase->new(
        name           => 'gated3',
        signing_key    => 'somekey',
        proxy_url_base => 'https://example.ngrok.io',
    );
    $a->basic_auth_user('u');
    $a->basic_auth_password('p');

    my $app = $a->psgi_app;
    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new('POST' => '/swaig');
        $req->header('Content-Type' => 'application/json');
        $req->content('{"function":"x"}');
        $req->header('Content-Length' => 16);
        require MIME::Base64;
        $req->header('Authorization' =>
            'Basic ' . MIME::Base64::encode_base64('u:p', ''));
        my $res = $cb->($req);
        is($res->code, 403, 'unsigned POST /swaig -> 403');
    };
};

# ---------------------------------------------------------------------------
# 5. Without signing_key, GET /health still works (no validation).
# ---------------------------------------------------------------------------
subtest 'no signing_key -> agent serves normally (warning only)' => sub {
    local $ENV{SIGNALWIRE_SIGNING_KEY};
    delete $ENV{SIGNALWIRE_SIGNING_KEY};

    my $a = SignalWire::Agent::AgentBase->new(name => 'open');

    # Capture the carp from psgi_app.
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $app = $a->psgi_app;
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(HTTP::Request->new('GET' => '/health'));
        is($res->code, 200, '/health returns 200 even without signing_key');
    };

    ok(
        (grep { /signature validation is disabled/ } @warnings),
        'startup warning emitted when signing_key is unset',
    );
};

# ---------------------------------------------------------------------------
# 6. With signing_key, GET /health is NOT gated (only POST is).
# ---------------------------------------------------------------------------
subtest 'GET /health still works when signing_key is set' => sub {
    local $ENV{SIGNALWIRE_SIGNING_KEY};
    delete $ENV{SIGNALWIRE_SIGNING_KEY};

    my $a = SignalWire::Agent::AgentBase->new(
        name        => 'health',
        signing_key => 'somekey',
    );

    my $app = $a->psgi_app;
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(HTTP::Request->new('GET' => '/health'));
        is($res->code, 200, 'GET /health bypasses signature gate');
    };
};

done_testing;
