#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON ();

use SignalWire::Agents::SWML::Document;
use SignalWire::Agents::SWML::Schema;
use SignalWire::Agents::SWML::Service;
use SignalWire::Agents::Logging;

# =============================================
# Test: Logging
# =============================================
subtest 'Logging' => sub {
    my $logger = SignalWire::Agents::Logging->get_logger('test');
    ok($logger, 'get_logger returns an object');
    is($logger->name, 'test', 'logger name correct');
    ok($logger->can('debug'), 'has debug method');
    ok($logger->can('info'),  'has info method');
    ok($logger->can('warn'),  'has warn method');
    ok($logger->can('error'), 'has error method');

    # Suppression
    $logger->suppressed(1);
    ok(!$logger->_should_log('error'), 'suppressed logger does not log');
    $logger->suppressed(0);
    ok($logger->_should_log('error'), 'unsuppressed logger logs error');

    # Level filtering
    $logger->level('warn');
    ok(!$logger->_should_log('debug'), 'warn level blocks debug');
    ok(!$logger->_should_log('info'),  'warn level blocks info');
    ok($logger->_should_log('warn'),   'warn level passes warn');
    ok($logger->_should_log('error'),  'warn level passes error');

    # Singleton behavior
    my $same = SignalWire::Agents::Logging->get_logger('test');
    is($same, $logger, 'same logger returned for same name');
};

# =============================================
# Test: SWML Document
# =============================================
subtest 'SWML Document' => sub {
    my $doc = SignalWire::Agents::SWML::Document->new();
    is($doc->version, '1.0.0', 'default version');
    is(ref $doc->sections, 'HASH', 'sections is hashref');

    # Add section
    $doc->add_section('main');
    ok($doc->has_section('main'), 'has main section');
    ok(!$doc->has_section('other'), 'does not have other section');

    # Add verbs
    $doc->add_verb('main', 'answer', { max_duration => 3600 });
    $doc->add_verb('main', 'hangup', {});

    my $main = $doc->get_section('main');
    is(scalar @$main, 2, 'main has 2 verbs');
    is_deeply($main->[0], { answer => { max_duration => 3600 } }, 'answer verb correct');
    is_deeply($main->[1], { hangup => {} }, 'hangup verb correct');

    # JSON output
    my $hash = $doc->to_hash;
    is($hash->{version}, '1.0.0', 'to_hash has version');
    ok(exists $hash->{sections}{main}, 'to_hash has main section');

    my $json = $doc->to_json;
    ok($json, 'to_json returns string');
    my $parsed = JSON::decode_json($json);
    is($parsed->{version}, '1.0.0', 'JSON roundtrip version');

    # Clear section
    $doc->clear_section('main');
    is(scalar @{ $doc->get_section('main') }, 0, 'clear_section empties section');

    # add_raw_verb
    $doc->add_raw_verb('main', { sleep => 1000 });
    is_deeply($doc->get_section('main')->[0], { sleep => 1000 }, 'add_raw_verb works');
};

# =============================================
# Test: Schema
# =============================================
subtest 'Schema loading' => sub {
    my $schema = SignalWire::Agents::SWML::Schema->instance();
    ok($schema, 'schema singleton created');
    ok($schema->verb_count >= 38, "schema has >= 38 verbs (got " . $schema->verb_count . ")");

    # Check known verbs
    for my $verb (qw(answer ai hangup connect sleep play record sip_refer send_sms pay tap)) {
        ok($schema->has_verb($verb), "has verb: $verb");
    }

    # Check verb details
    my $answer = $schema->get_verb('answer');
    ok($answer, 'get_verb returns answer');
    is($answer->{verb_name}, 'answer', 'answer verb_name correct');
    is($answer->{schema_name}, 'Answer', 'answer schema_name correct');

    # Unknown verb
    ok(!$schema->has_verb('nonexistent'), 'unknown verb returns false');

    # get_verb_names
    my @names = $schema->get_verb_names;
    ok(scalar @names >= 38, 'get_verb_names has enough verbs');
    ok((grep { $_ eq 'answer' } @names), 'verb names include answer');
};

# =============================================
# Test: Service
# =============================================
subtest 'Service basic' => sub {
    my $svc = SignalWire::Agents::SWML::Service->new(
        basic_auth_user     => 'testuser',
        basic_auth_password => 'testpass',
    );
    ok($svc, 'service created');
    is($svc->basic_auth_user, 'testuser', 'auth user set');
    is($svc->basic_auth_password, 'testpass', 'auth password set');

    # Auto-generated credentials
    my $svc2 = SignalWire::Agents::SWML::Service->new();
    ok(length($svc2->basic_auth_user) > 0, 'auto-generated user');
    ok(length($svc2->basic_auth_password) > 0, 'auto-generated password');
};

subtest 'Service AUTOLOAD verb methods' => sub {
    my $svc = SignalWire::Agents::SWML::Service->new();

    # Make sure document starts with main section
    $svc->document->add_section('main');

    # Call auto-vivified verb
    $svc->answer('main', { max_duration => 3600 });
    my $main = $svc->document->get_section('main');
    ok($main, 'main section exists');
    is(scalar @$main, 1, 'one verb added');
    is_deeply($main->[0], { answer => { max_duration => 3600 } }, 'answer verb added via AUTOLOAD');

    # Sleep takes integer
    $svc->sleep('main', 2000);
    is_deeply($main->[1], { sleep => 2000 }, 'sleep verb takes integer');

    # Hangup
    $svc->hangup('main', {});
    is_deeply($main->[2], { hangup => {} }, 'hangup verb works');

    # Unknown method should die
    eval { $svc->totally_nonexistent_method() };
    ok($@, 'unknown method dies');
    like($@, qr/Can't locate method/, 'error message mentions missing method');
};

subtest 'Service PSGI app' => sub {
    my $svc = SignalWire::Agents::SWML::Service->new(
        basic_auth_user     => 'user',
        basic_auth_password => 'pass',
        route               => '/agent',
    );
    my $app = $svc->to_psgi_app;
    ok(ref $app eq 'CODE', 'to_psgi_app returns coderef');

    # Health endpoint (no auth)
    my $resp = $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => '/health',
    });
    is($resp->[0], 200, 'health returns 200');
    my $body = JSON::decode_json($resp->[2][0]);
    is($body->{status}, 'ok', 'health body is ok');

    # Ready endpoint (no auth)
    $resp = $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => '/ready',
    });
    is($resp->[0], 200, 'ready returns 200');

    # Protected route without auth
    $resp = $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => '/agent',
    });
    is($resp->[0], 401, 'protected route returns 401 without auth');

    # Protected route with correct auth
    my $encoded = MIME::Base64::encode_base64('user:pass', '');
    $resp = $app->({
        REQUEST_METHOD     => 'GET',
        PATH_INFO          => '/agent',
        HTTP_AUTHORIZATION => "Basic $encoded",
    });
    is($resp->[0], 200, 'protected route returns 200 with auth');

    # Check security headers
    my %headers = @{ $resp->[1] };
    is($headers{'X-Content-Type-Options'}, 'nosniff', 'security header: nosniff');
    is($headers{'X-Frame-Options'}, 'DENY', 'security header: X-Frame-Options');

    # 404 for unknown routes
    $resp = $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => '/nonexistent',
    });
    is($resp->[0], 404, 'unknown route returns 404');

    # Bad auth
    my $bad_encoded = MIME::Base64::encode_base64('user:wrong', '');
    $resp = $app->({
        REQUEST_METHOD     => 'GET',
        PATH_INFO          => '/agent',
        HTTP_AUTHORIZATION => "Basic $bad_encoded",
    });
    is($resp->[0], 401, 'bad auth returns 401');
};

subtest 'Service timing-safe comparison' => sub {
    # This tests that the comparison works correctly (not that it's constant-time,
    # which would require timing analysis)
    ok(SignalWire::Agents::SWML::Service::_timing_safe_compare('abc', 'abc'), 'same strings match');
    ok(!SignalWire::Agents::SWML::Service::_timing_safe_compare('abc', 'def'), 'different strings do not match');
    ok(!SignalWire::Agents::SWML::Service::_timing_safe_compare('abc', 'ab'), 'different lengths do not match');
    ok(SignalWire::Agents::SWML::Service::_timing_safe_compare('', ''), 'empty strings match');
};

done_testing;
