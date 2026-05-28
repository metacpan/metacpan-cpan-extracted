#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON qw(encode_json decode_json);
use MIME::Base64 qw(encode_base64);

use_ok('SignalWire::Agent::AgentBase');

# ============================================================
# 1. Auto-generated credentials
# ============================================================
subtest 'auto-generated credentials' => sub {
    local $ENV{SWML_BASIC_AUTH_USER};
    local $ENV{SWML_BASIC_AUTH_PASSWORD};
    delete $ENV{SWML_BASIC_AUTH_USER};
    delete $ENV{SWML_BASIC_AUTH_PASSWORD};
    my $a = SignalWire::Agent::AgentBase->new(name => 'auto');
    ok(length($a->basic_auth_user) > 0, 'user auto-generated');
    ok(length($a->basic_auth_password) > 0, 'password auto-generated');
    # Default user is the agent name when no env var
    is($a->basic_auth_user, 'auto', 'auto user is agent name');
};

# ============================================================
# 2. Explicit credentials
# ============================================================
subtest 'explicit credentials' => sub {
    my $a = SignalWire::Agent::AgentBase->new(
        name               => 'explicit',
        basic_auth_user    => 'myuser',
        basic_auth_password => 'mypass',
    );
    is($a->basic_auth_user, 'myuser', 'explicit user');
    is($a->basic_auth_password, 'mypass', 'explicit password');
};

# ============================================================
# 3. Env var credentials
# ============================================================
subtest 'env var credentials' => sub {
    local $ENV{SWML_BASIC_AUTH_USER} = 'envuser';
    local $ENV{SWML_BASIC_AUTH_PASSWORD} = 'envpass';
    my $a = SignalWire::Agent::AgentBase->new(name => 'env');
    is($a->basic_auth_user, 'envuser', 'user from env');
    is($a->basic_auth_password, 'envpass', 'password from env');
};

# ============================================================
# 4. Timing-safe comparison
# ============================================================
subtest 'timing-safe comparison' => sub {
    ok(SignalWire::Agent::AgentBase::_timing_safe_eq('abc', 'abc'), 'same strings match');
    ok(!SignalWire::Agent::AgentBase::_timing_safe_eq('abc', 'def'), 'different strings fail');
    ok(!SignalWire::Agent::AgentBase::_timing_safe_eq('abc', 'abcd'), 'different lengths fail');
    ok(SignalWire::Agent::AgentBase::_timing_safe_eq('', ''), 'empty strings match');
};

# ============================================================
# 5. Auth check on PSGI app
# ============================================================
subtest 'auth check - no auth header' => sub {
    my $a = SignalWire::Agent::AgentBase->new(
        name               => 'auth_no',
        basic_auth_user    => 'user',
        basic_auth_password => 'pass',
    );
    my $app = $a->psgi_app;
    my $res = $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => '/',
        SCRIPT_NAME    => '',
        SERVER_NAME    => 'localhost',
        SERVER_PORT    => 3000,
        'psgi.input'   => do { open my $fh, '<', \(''); $fh },
    });
    is($res->[0], 401, 'no auth returns 401');
};

subtest 'auth check - correct auth' => sub {
    my $a = SignalWire::Agent::AgentBase->new(
        name               => 'auth_ok',
        basic_auth_user    => 'user',
        basic_auth_password => 'pass',
    );
    my $app = $a->psgi_app;
    my $auth = encode_base64('user:pass', '');
    my $res = $app->({
        REQUEST_METHOD     => 'GET',
        PATH_INFO          => '/',
        SCRIPT_NAME        => '',
        SERVER_NAME        => 'localhost',
        SERVER_PORT        => 3000,
        HTTP_AUTHORIZATION => "Basic $auth",
        'psgi.input'       => do { open my $fh, '<', \(''); $fh },
    });
    is($res->[0], 200, 'correct auth returns 200');
};

subtest 'auth check - wrong password' => sub {
    my $a = SignalWire::Agent::AgentBase->new(
        name               => 'auth_bad',
        basic_auth_user    => 'user',
        basic_auth_password => 'pass',
    );
    my $app = $a->psgi_app;
    my $auth = encode_base64('user:wrong', '');
    my $res = $app->({
        REQUEST_METHOD     => 'GET',
        PATH_INFO          => '/',
        SCRIPT_NAME        => '',
        SERVER_NAME        => 'localhost',
        SERVER_PORT        => 3000,
        HTTP_AUTHORIZATION => "Basic $auth",
        'psgi.input'       => do { open my $fh, '<', \(''); $fh },
    });
    is($res->[0], 401, 'wrong password returns 401');
};

subtest 'auth check - wrong user' => sub {
    my $a = SignalWire::Agent::AgentBase->new(
        name               => 'auth_bad_u',
        basic_auth_user    => 'user',
        basic_auth_password => 'pass',
    );
    my $app = $a->psgi_app;
    my $auth = encode_base64('wrong:pass', '');
    my $res = $app->({
        REQUEST_METHOD     => 'GET',
        PATH_INFO          => '/',
        SCRIPT_NAME        => '',
        SERVER_NAME        => 'localhost',
        SERVER_PORT        => 3000,
        HTTP_AUTHORIZATION => "Basic $auth",
        'psgi.input'       => do { open my $fh, '<', \(''); $fh },
    });
    is($res->[0], 401, 'wrong user returns 401');
};

# ============================================================
# 6. Health/ready endpoints bypass auth
# ============================================================
subtest 'health bypasses auth' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'health');
    my $app = $a->psgi_app;
    my $res = $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => '/health',
        SCRIPT_NAME    => '',
        SERVER_NAME    => 'localhost',
        SERVER_PORT    => 3000,
    });
    is($res->[0], 200, 'health returns 200 without auth');
};

subtest 'ready bypasses auth' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'ready');
    my $app = $a->psgi_app;
    my $res = $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => '/ready',
        SCRIPT_NAME    => '',
        SERVER_NAME    => 'localhost',
        SERVER_PORT    => 3000,
    });
    is($res->[0], 200, 'ready returns 200 without auth');
};

# ============================================================
# 7. Security headers
# ============================================================
subtest 'security headers present' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'sec');
    my $app = $a->psgi_app;
    my $res = $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => '/health',
        SCRIPT_NAME    => '',
        SERVER_NAME    => 'localhost',
        SERVER_PORT    => 3000,
    });
    my %headers = @{$res->[1]};
    is($headers{'X-Content-Type-Options'}, 'nosniff', 'nosniff');
    is($headers{'X-Frame-Options'}, 'DENY', 'deny frame');
    is($headers{'Cache-Control'}, 'no-store', 'no-store');
};

# ============================================================
# 8a. get_basic_auth_credentials(include_source)
#     Python parity: AuthMixin.get_basic_auth_credentials(include_source=False)
# ============================================================
subtest 'get_basic_auth_credentials() returns (user, pass)' => sub {
    my $a = SignalWire::Agent::AgentBase->new(
        name                 => 'creds',
        basic_auth_user      => 'alice',
        basic_auth_password  => 'wonderland',
    );
    my @creds = $a->get_basic_auth_credentials();
    is(scalar @creds, 2, 'two-element list returned');
    is($creds[0], 'alice', 'user');
    is($creds[1], 'wonderland', 'password');
};

subtest 'get_basic_auth_credentials(0) returns (user, pass)' => sub {
    my $a = SignalWire::Agent::AgentBase->new(
        name                 => 'creds_explicit_false',
        basic_auth_user      => 'alice',
        basic_auth_password  => 'wonderland',
    );
    my @creds = $a->get_basic_auth_credentials(0);
    is(scalar @creds, 2, 'two-element list when include_source=0');
};

subtest 'get_basic_auth_credentials(1) returns (user, pass, source) "provided"' => sub {
    local $ENV{SWML_BASIC_AUTH_USER};
    local $ENV{SWML_BASIC_AUTH_PASSWORD};
    delete $ENV{SWML_BASIC_AUTH_USER};
    delete $ENV{SWML_BASIC_AUTH_PASSWORD};
    my $a = SignalWire::Agent::AgentBase->new(
        name                 => 'src_provided',
        basic_auth_user      => 'manual_user',
        basic_auth_password  => 'short',
    );
    my @creds = $a->get_basic_auth_credentials(1);
    is(scalar @creds, 3, 'three-element list when include_source=1');
    is($creds[0], 'manual_user', 'user');
    is($creds[1], 'short',       'password');
    is($creds[2], 'provided',    'source is "provided" for explicitly-passed creds');
};

subtest 'get_basic_auth_credentials(1) returns "environment" when env-derived' => sub {
    local $ENV{SWML_BASIC_AUTH_USER}     = 'env_alice';
    local $ENV{SWML_BASIC_AUTH_PASSWORD} = 'env_secret';
    my $a = SignalWire::Agent::AgentBase->new(name => 'src_env');
    my @creds = $a->get_basic_auth_credentials(1);
    is($creds[0], 'env_alice',  'user from env');
    is($creds[1], 'env_secret', 'password from env');
    is($creds[2], 'environment','source is "environment"');
};

subtest 'get_basic_auth_credentials(1) returns "generated" when auto-minted' => sub {
    local $ENV{SWML_BASIC_AUTH_USER};
    local $ENV{SWML_BASIC_AUTH_PASSWORD};
    delete $ENV{SWML_BASIC_AUTH_USER};
    delete $ENV{SWML_BASIC_AUTH_PASSWORD};
    my $a = SignalWire::Agent::AgentBase->new(
        name                 => 'src_generated',
        basic_auth_user      => 'user_abcd',                    # starts with "user_"
        basic_auth_password  => 'a' x 24,                       # >20 chars
    );
    my @creds = $a->get_basic_auth_credentials(1);
    is($creds[2], 'generated', 'source is "generated"');
};

# ============================================================
# 8. Malformed auth header
# ============================================================
subtest 'malformed auth header' => sub {
    my $a = SignalWire::Agent::AgentBase->new(
        name               => 'malformed',
        basic_auth_user    => 'u',
        basic_auth_password => 'p',
    );
    my $app = $a->psgi_app;

    # Not base64
    my $res = $app->({
        REQUEST_METHOD     => 'GET',
        PATH_INFO          => '/',
        SCRIPT_NAME        => '',
        SERVER_NAME        => 'localhost',
        SERVER_PORT        => 3000,
        HTTP_AUTHORIZATION => 'Basic garbage!!!',
        'psgi.input'       => do { open my $fh, '<', \(''); $fh },
    });
    is($res->[0], 401, 'malformed base64 returns 401');

    # Not Basic scheme
    $res = $app->({
        REQUEST_METHOD     => 'GET',
        PATH_INFO          => '/',
        SCRIPT_NAME        => '',
        SERVER_NAME        => 'localhost',
        SERVER_PORT        => 3000,
        HTTP_AUTHORIZATION => 'Bearer token123',
        'psgi.input'       => do { open my $fh, '<', \(''); $fh },
    });
    is($res->[0], 401, 'non-Basic scheme returns 401');
};

done_testing;
