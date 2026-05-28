#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON ();

use SignalWire::Security::SessionManager;

# =============================================
# Test: Session creation
# =============================================
subtest 'Session creation' => sub {
    my $sm = SignalWire::Security::SessionManager->new();
    ok($sm, 'session manager created');
    is($sm->token_expiry_secs, 900, 'default expiry 900 seconds');
    ok(length($sm->secret_key) > 0, 'secret key auto-generated');

    # create_session generates call_id
    my $cid = $sm->create_session();
    ok(length($cid) > 0, 'auto-generated call_id');

    # create_session uses provided call_id
    my $cid2 = $sm->create_session('my-call-123');
    is($cid2, 'my-call-123', 'provided call_id used');
};

# =============================================
# Test: Token generation and validation
# =============================================
subtest 'Token generate and validate' => sub {
    my $sm = SignalWire::Security::SessionManager->new(
        secret_key => 'test-secret-key-12345',
    );

    my $call_id = 'call-abc-123';
    my $func    = 'get_weather';

    my $token = $sm->generate_token($func, $call_id);
    ok(length($token) > 0, 'token generated');
    ok($token !~ /\s/, 'token has no whitespace');

    # Valid token
    ok($sm->validate_token($call_id, $func, $token), 'valid token validates');

    # create_tool_token alias
    my $token2 = $sm->create_tool_token($func, $call_id);
    ok($sm->validate_token($call_id, $func, $token2), 'create_tool_token alias works');

    # validate_tool_token alias (different param order)
    ok($sm->validate_tool_token($func, $token, $call_id), 'validate_tool_token alias works');
};

# =============================================
# Test: Token validation failures
# =============================================
subtest 'Token validation failures' => sub {
    my $sm = SignalWire::Security::SessionManager->new(
        secret_key => 'test-secret-key-12345',
    );

    my $call_id = 'call-abc-123';
    my $func    = 'get_weather';
    my $token   = $sm->generate_token($func, $call_id);

    # Wrong function
    ok(!$sm->validate_token($call_id, 'wrong_func', $token), 'wrong function fails');

    # Wrong call_id
    ok(!$sm->validate_token('wrong-call', $func, $token), 'wrong call_id fails');

    # Garbage token
    ok(!$sm->validate_token($call_id, $func, 'garbage'), 'garbage token fails');

    # Empty token
    ok(!$sm->validate_token($call_id, $func, ''), 'empty token fails');

    # Empty call_id
    ok(!$sm->validate_token('', $func, $token), 'empty call_id fails');

    # Undef token
    ok(!$sm->validate_token($call_id, $func, undef), 'undef token fails');
};

# =============================================
# Test: Token expiry
# =============================================
subtest 'Token expiry' => sub {
    # Create with very short expiry so it's already expired
    my $sm = SignalWire::Security::SessionManager->new(
        secret_key       => 'test-secret-key-12345',
        token_expiry_secs => 0,  # expires immediately
    );

    my $token = $sm->generate_token('func', 'call-1');
    # Token with 0 expiry should be at time() + 0, which is current time
    # It should fail because expiry < time() after even a tiny delay
    sleep(1);
    ok(!$sm->validate_token('call-1', 'func', $token), 'expired token fails');
};

# =============================================
# Test: Different secret keys
# =============================================
subtest 'Different secret keys' => sub {
    my $sm1 = SignalWire::Security::SessionManager->new(secret_key => 'key-one');
    my $sm2 = SignalWire::Security::SessionManager->new(secret_key => 'key-two');

    my $token = $sm1->generate_token('func', 'call-1');
    ok($sm1->validate_token('call-1', 'func', $token), 'correct key validates');
    ok(!$sm2->validate_token('call-1', 'func', $token), 'different key rejects');
};

# =============================================
# Test: Timing-safe comparison
# =============================================
subtest 'Timing-safe comparison' => sub {
    ok(SignalWire::Security::SessionManager::_timing_safe_compare('abc', 'abc'),
       'same strings match');
    ok(!SignalWire::Security::SessionManager::_timing_safe_compare('abc', 'def'),
       'different strings do not match');
    ok(!SignalWire::Security::SessionManager::_timing_safe_compare('abc', 'ab'),
       'different length strings do not match');
    ok(SignalWire::Security::SessionManager::_timing_safe_compare('', ''),
       'empty strings match');
};

# =============================================
# Test: Legacy methods
# =============================================
subtest 'Legacy methods' => sub {
    my $sm = SignalWire::Security::SessionManager->new();

    # Mirror Python's stateless session manager: every legacy method
    # accepts (call_id) (and key/value for set_session_metadata) and
    # returns success / empty metadata. The contract is that the
    # *signature* is what callers depend on, not internal state.
    ok($sm->activate_session('call-1'), 'activate_session(call_id) returns true');
    ok($sm->end_session('call-1'),      'end_session(call_id) returns true');

    my $md = $sm->get_session_metadata('call-1');
    is_deeply($md, {}, 'get_session_metadata(call_id) returns empty hash');
    is(ref($md), 'HASH', 'get_session_metadata returns a hashref');

    ok($sm->set_session_metadata('call-1', 'key', 'val'),
       'set_session_metadata(call_id, key, value) returns true');

    # Multiple call_ids: stateless => same behavior for any call_id.
    for my $cid ('call-A', 'call-B', '') {
        ok($sm->activate_session($cid),       "activate_session('$cid') ok");
        ok($sm->end_session($cid),            "end_session('$cid') ok");
        is_deeply($sm->get_session_metadata($cid), {},
                  "get_session_metadata('$cid') -> {}");
        ok($sm->set_session_metadata($cid, 'k', 'v'),
           "set_session_metadata('$cid', k, v) ok");
    }
};

# =============================================
# Test: Debug token
# =============================================
subtest 'Debug token' => sub {
    my $sm = SignalWire::Security::SessionManager->new(
        secret_key => 'debug-key',
    );

    # Debug mode off
    my $token = $sm->generate_token('func', 'call-1');
    my $debug = $sm->debug_token($token);
    ok(exists $debug->{error}, 'debug_token returns error when mode off');

    # Debug mode on
    $sm->_debug_mode(1);
    $debug = $sm->debug_token($token);
    ok($debug->{valid_format}, 'valid_format is true');
    is($debug->{components}{function}, 'func', 'debug shows function');
    ok(exists $debug->{status}{is_expired}, 'debug shows expiry status');

    # Invalid token in debug mode
    $debug = $sm->debug_token('garbage');
    # Could be valid_format false or parse error - either is ok
    ok($debug, 'debug_token handles garbage');
};

done_testing;
