#!/usr/bin/env perl
# Tests for the phone-number binding surface:
#   - PhoneCallHandler enum (all 11 wire values)
#   - Typed helpers on phone_numbers namespace
#   - Regression guards against the post-mortem anti-patterns
#   - Deprecation warnings on assign_phone_route,
#     swml_webhooks->create, cxml_webhooks->create
use strict;
use warnings;
use Test::More;

use SignalWire::REST::RestClient;
use SignalWire::REST::PhoneCallHandler;
use SignalWire::REST::Namespaces::PhoneNumbers;
use SignalWire::REST::Namespaces::Fabric;

# ---------------------------------------------------------------------------
# Mock HTTP client: records every call, returns a canned response.
# Compatible with the ->get/->post/->put/->patch/->delete_request shape used
# by the Namespaces classes (via _http).
# ---------------------------------------------------------------------------
package MockHttp;
sub new {
    my ($class, %opts) = @_;
    return bless {
        calls    => [],
        response => $opts{response} // {},
    }, $class;
}
sub _record {
    my ($self, $method, $path, %opts) = @_;
    push @{ $self->{calls} }, {
        method => $method,
        path   => $path,
        body   => $opts{body},
        params => $opts{params},
    };
    return $self->{response};
}
sub get    { my $s = shift; my $p = shift; $s->_record('GET',    $p, @_) }
sub post   { my $s = shift; my $p = shift; $s->_record('POST',   $p, @_) }
sub put    { my $s = shift; my $p = shift; $s->_record('PUT',    $p, @_) }
sub patch  { my $s = shift; my $p = shift; $s->_record('PATCH',  $p, @_) }
sub delete_request { my $s = shift; my $p = shift; $s->_record('DELETE', $p, @_) }
sub calls  { $_[0]->{calls} }
sub reset_calls { $_[0]->{calls} = [] }

package main;

sub make_pn {
    my $http = MockHttp->new;
    my $pn   = SignalWire::REST::Namespaces::PhoneNumbers->new(
        _http      => $http,
        _base_path => '/api/relay/rest/phone_numbers',
    );
    return ($pn, $http);
}

my $BASE = '/api/relay/rest/phone_numbers';

# ============================================================
# 1. PhoneCallHandler enum contract
# ============================================================
subtest 'PhoneCallHandler enum wire values' => sub {
    is(SignalWire::REST::PhoneCallHandler::RELAY_SCRIPT,      'relay_script',      'RELAY_SCRIPT');
    is(SignalWire::REST::PhoneCallHandler::LAML_WEBHOOKS,     'laml_webhooks',     'LAML_WEBHOOKS');
    is(SignalWire::REST::PhoneCallHandler::LAML_APPLICATION,  'laml_application',  'LAML_APPLICATION');
    is(SignalWire::REST::PhoneCallHandler::AI_AGENT,          'ai_agent',          'AI_AGENT');
    is(SignalWire::REST::PhoneCallHandler::CALL_FLOW,         'call_flow',         'CALL_FLOW');
    is(SignalWire::REST::PhoneCallHandler::RELAY_APPLICATION, 'relay_application', 'RELAY_APPLICATION');
    is(SignalWire::REST::PhoneCallHandler::RELAY_TOPIC,       'relay_topic',       'RELAY_TOPIC');
    is(SignalWire::REST::PhoneCallHandler::RELAY_CONTEXT,     'relay_context',     'RELAY_CONTEXT');
    is(SignalWire::REST::PhoneCallHandler::RELAY_CONNECTOR,   'relay_connector',   'RELAY_CONNECTOR');
    is(SignalWire::REST::PhoneCallHandler::VIDEO_ROOM,        'video_room',        'VIDEO_ROOM');
    is(SignalWire::REST::PhoneCallHandler::DIALOGFLOW,        'dialogflow',        'DIALOGFLOW');
};

subtest 'PhoneCallHandler values() returns all 11' => sub {
    my @values = SignalWire::REST::PhoneCallHandler::values();
    my %set = map { $_ => 1 } @values;
    my %expected = map { $_ => 1 } qw(
        relay_script laml_webhooks laml_application ai_agent call_flow
        relay_application relay_topic relay_context relay_connector
        video_room dialogflow
    );
    is(scalar @values, 11, '11 wire values');
    is_deeply(\%set, \%expected, 'all expected wire values present');
};

subtest 'PhoneCallHandler exports via Exporter' => sub {
    package TestImporter;
    SignalWire::REST::PhoneCallHandler->import(':all');
    ::is(RELAY_SCRIPT(), 'relay_script', 'RELAY_SCRIPT exported');
    ::is(AI_AGENT(),     'ai_agent',     'AI_AGENT exported');
};

# ============================================================
# 2. PhoneNumbers CRUD/search defaults
# ============================================================
subtest 'update uses PUT' => sub {
    my ($pn, $http) = make_pn();
    $pn->update('pn-1', name => 'Main');
    my @calls = @{ $http->calls };
    is(scalar @calls, 1, 'one call');
    is($calls[0]{method}, 'PUT', 'PUT (not PATCH)');
    is($calls[0]{path}, "$BASE/pn-1", 'path');
    is_deeply($calls[0]{body}, { name => 'Main' }, 'body');
};

subtest 'search -> /search' => sub {
    my ($pn, $http) = make_pn();
    $pn->search(area_code => '512');
    my @calls = @{ $http->calls };
    is(scalar @calls, 1, 'one call');
    is($calls[0]{method}, 'GET',            'GET');
    is($calls[0]{path},   "$BASE/search",   'path');
    is_deeply($calls[0]{params}, { area_code => '512' }, 'params');
};

# ============================================================
# 3. set_swml_webhook - the post-mortem happy path
# ============================================================
subtest 'set_swml_webhook' => sub {
    my ($pn, $http) = make_pn();
    $pn->set_swml_webhook('pn-1', url => 'https://example.com/swml');
    my @calls = @{ $http->calls };
    is(scalar @calls, 1, 'exactly one HTTP call');
    is($calls[0]{method}, 'PUT', 'PUT');
    is($calls[0]{path},   "$BASE/pn-1", 'path');
    is_deeply(
        $calls[0]{body},
        {
            call_handler          => 'relay_script',
            call_relay_script_url => 'https://example.com/swml',
        },
        'body has call_handler + call_relay_script_url'
    );
};

subtest 'set_swml_webhook passes extra args through' => sub {
    my ($pn, $http) = make_pn();
    $pn->set_swml_webhook('pn-1', url => 'https://example.com/swml', name => 'Support');
    my $body = $http->calls->[0]{body};
    is($body->{call_handler}, 'relay_script', 'call_handler set');
    is($body->{call_relay_script_url}, 'https://example.com/swml', 'url set');
    is($body->{name}, 'Support', 'extra name arg passed through');
};

subtest 'set_swml_webhook requires url' => sub {
    my ($pn) = make_pn();
    eval { $pn->set_swml_webhook('pn-1') };
    like($@, qr/'url' is required/, 'missing url dies');
};

# ============================================================
# 4. set_cxml_webhook
# ============================================================
subtest 'set_cxml_webhook minimal' => sub {
    my ($pn, $http) = make_pn();
    $pn->set_cxml_webhook('pn-1', url => 'https://example.com/voice.xml');
    is_deeply(
        $http->calls->[0]{body},
        {
            call_handler     => 'laml_webhooks',
            call_request_url => 'https://example.com/voice.xml',
        },
        'minimal body'
    );
};

subtest 'set_cxml_webhook with fallback and status' => sub {
    my ($pn, $http) = make_pn();
    $pn->set_cxml_webhook(
        'pn-1',
        url                 => 'https://example.com/voice.xml',
        fallback_url        => 'https://example.com/fallback.xml',
        status_callback_url => 'https://example.com/status',
    );
    is_deeply(
        $http->calls->[0]{body},
        {
            call_handler            => 'laml_webhooks',
            call_request_url        => 'https://example.com/voice.xml',
            call_fallback_url       => 'https://example.com/fallback.xml',
            call_status_callback_url => 'https://example.com/status',
        },
        'full body'
    );
};

# ============================================================
# 5. set_cxml_application
# ============================================================
subtest 'set_cxml_application' => sub {
    my ($pn, $http) = make_pn();
    $pn->set_cxml_application('pn-1', application_id => 'app-1');
    is_deeply(
        $http->calls->[0]{body},
        {
            call_handler             => 'laml_application',
            call_laml_application_id => 'app-1',
        },
        'body'
    );
};

# ============================================================
# 6. set_ai_agent
# ============================================================
subtest 'set_ai_agent' => sub {
    my ($pn, $http) = make_pn();
    $pn->set_ai_agent('pn-1', agent_id => 'agent-1');
    is_deeply(
        $http->calls->[0]{body},
        {
            call_handler     => 'ai_agent',
            call_ai_agent_id => 'agent-1',
        },
        'body'
    );
};

# ============================================================
# 7. set_call_flow
# ============================================================
subtest 'set_call_flow minimal' => sub {
    my ($pn, $http) = make_pn();
    $pn->set_call_flow('pn-1', flow_id => 'cf-1');
    is_deeply(
        $http->calls->[0]{body},
        {
            call_handler => 'call_flow',
            call_flow_id => 'cf-1',
        },
        'minimal body'
    );
};

subtest 'set_call_flow with version' => sub {
    my ($pn, $http) = make_pn();
    $pn->set_call_flow('pn-1', flow_id => 'cf-1', version => 'current_deployed');
    is_deeply(
        $http->calls->[0]{body},
        {
            call_handler      => 'call_flow',
            call_flow_id      => 'cf-1',
            call_flow_version => 'current_deployed',
        },
        'body with version'
    );
};

# ============================================================
# 8. set_relay_application
# ============================================================
subtest 'set_relay_application' => sub {
    my ($pn, $http) = make_pn();
    $pn->set_relay_application('pn-1', name => 'my-app');
    is_deeply(
        $http->calls->[0]{body},
        {
            call_handler           => 'relay_application',
            call_relay_application => 'my-app',
        },
        'body'
    );
};

# ============================================================
# 9. set_relay_topic
# ============================================================
subtest 'set_relay_topic minimal' => sub {
    my ($pn, $http) = make_pn();
    $pn->set_relay_topic('pn-1', topic => 'office');
    is_deeply(
        $http->calls->[0]{body},
        {
            call_handler     => 'relay_topic',
            call_relay_topic => 'office',
        },
        'minimal body'
    );
};

subtest 'set_relay_topic with status callback' => sub {
    my ($pn, $http) = make_pn();
    $pn->set_relay_topic(
        'pn-1',
        topic               => 'office',
        status_callback_url => 'https://example.com/status',
    );
    is_deeply(
        $http->calls->[0]{body},
        {
            call_handler     => 'relay_topic',
            call_relay_topic => 'office',
            call_relay_topic_status_callback_url => 'https://example.com/status',
        },
        'full body'
    );
};

# ============================================================
# 10. REGRESSION: the post-mortem anti-patterns are NOT exercised
# ============================================================
subtest 'regression: set_swml_webhook does not pre-create fabric webhook' => sub {
    my ($pn, $http) = make_pn();
    $pn->set_swml_webhook('pn-1', url => 'https://example.com/swml');
    my @calls = @{ $http->calls };
    # Exactly one HTTP call (no pre-create of swml_webhooks Fabric resource,
    # no separate assign_phone_route POST).
    is(scalar @calls, 1, 'exactly one HTTP call (no extra create or assign)');
    is($calls[0]{method}, 'PUT', 'call is a PUT (phone_numbers update)');
    is($calls[0]{path},   "$BASE/pn-1", 'call targets phone_numbers/{sid}');

    # Neither path fragment must appear among any call URL.
    for my $c (@calls) {
        unlike($c->{path}, qr{/api/fabric/resources/swml_webhooks},
            'no fabric swml_webhooks create');
        unlike($c->{path}, qr{/phone_routes\b},
            'no assign_phone_route call');
    }
};

subtest 'regression: wire-level form (update) also works without helpers' => sub {
    my ($pn, $http) = make_pn();
    $pn->update(
        'pn-1',
        call_handler          => SignalWire::REST::PhoneCallHandler::RELAY_SCRIPT,
        call_relay_script_url => 'https://example.com/swml',
    );
    my $body = $http->calls->[0]{body};
    is($body->{call_handler}, 'relay_script', 'enum constant -> wire value');
    is($body->{call_relay_script_url}, 'https://example.com/swml', 'url set');
};

# ============================================================
# 11. All seven helpers present on the namespace
# ============================================================
subtest 'all seven helpers present on phone_numbers namespace' => sub {
    my $client = SignalWire::REST::RestClient->new(
        project => 'p', token => 't', host => 'h',
    );
    my $pn = $client->phone_numbers;
    my @helpers = qw(
        set_swml_webhook
        set_cxml_webhook
        set_cxml_application
        set_ai_agent
        set_call_flow
        set_relay_application
        set_relay_topic
    );
    for my $h (@helpers) {
        ok($pn->can($h), "phone_numbers has $h");
    }
};

# ============================================================
# 12. Deprecation warnings on the legacy paths
# ============================================================
sub _capture_warnings {
    my $fn = shift;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $ret = eval { $fn->() };
    my $err = $@;
    return { warnings => \@warnings, result => $ret, error => $err };
}

subtest 'assign_phone_route emits deprecation warning but still POSTs' => sub {
    my $client = SignalWire::REST::RestClient->new(
        project => 'p', token => 't', host => 'h',
    );
    my $http = MockHttp->new;
    my $resources = SignalWire::REST::Namespaces::Fabric::GenericResources->new(
        _http      => $http,
        _base_path => '/api/fabric/resources',
    );
    my $captured = _capture_warnings(sub {
        $resources->assign_phone_route('res-1', phone_route_id => 'pr-1');
    });
    my @warnings = @{ $captured->{warnings} };
    ok(scalar @warnings >= 1, 'at least one warning emitted');
    like($warnings[0], qr/DEPRECATED/, 'warning says DEPRECATED');
    like($warnings[0], qr/phone_numbers->set_/, 'warning points at helpers');

    # But the call still POSTed for backcompat.
    my @calls = @{ $http->calls };
    is(scalar @calls, 1, 'one POST was made');
    is($calls[0]{method}, 'POST', 'POST method');
    is($calls[0]{path}, '/api/fabric/resources/res-1/phone_routes', 'correct path');
    is_deeply($calls[0]{body}, { phone_route_id => 'pr-1' }, 'body passed through');
};

subtest 'swml_webhooks->create emits deprecation warning pointing at helper' => sub {
    my $client = SignalWire::REST::RestClient->new(
        project => 'p', token => 't', host => 'h',
    );
    my $http = MockHttp->new(response => { id => 'sw-1' });
    my $swh = SignalWire::REST::Namespaces::Fabric::SwmlWebhooks->new(
        _http      => $http,
        _base_path => '/api/fabric/resources/swml_webhooks',
    );
    my $captured = _capture_warnings(sub {
        $swh->create(
            name                => 'Orphan',
            primary_request_url => 'https://example.com/swml',
        );
    });
    my @warnings = @{ $captured->{warnings} };
    ok(scalar @warnings >= 1, 'deprecation warning emitted');
    like($warnings[0], qr/DEPRECATED/, 'says DEPRECATED');
    like($warnings[0], qr/set_swml_webhook/, 'points at set_swml_webhook');

    # create still works (backcompat).
    my @calls = @{ $http->calls };
    is(scalar @calls, 1, 'POST was made');
    is($calls[0]{method}, 'POST', 'POST');
    is($calls[0]{path}, '/api/fabric/resources/swml_webhooks', 'path');
};

subtest 'cxml_webhooks->create emits deprecation warning pointing at helper' => sub {
    my $http = MockHttp->new(response => { id => 'cw-1' });
    my $cwh = SignalWire::REST::Namespaces::Fabric::CxmlWebhooks->new(
        _http      => $http,
        _base_path => '/api/fabric/resources/cxml_webhooks',
    );
    my $captured = _capture_warnings(sub {
        $cwh->create(
            name                => 'Orphan',
            primary_request_url => 'https://example.com/voice.xml',
        );
    });
    my @warnings = @{ $captured->{warnings} };
    ok(scalar @warnings >= 1, 'deprecation warning emitted');
    like($warnings[0], qr/set_cxml_webhook/, 'points at set_cxml_webhook');
};

subtest 'swml/cxml_webhooks list/get/update/delete DO NOT warn' => sub {
    my $http = MockHttp->new(response => { data => [] });
    my $swh = SignalWire::REST::Namespaces::Fabric::SwmlWebhooks->new(
        _http      => $http,
        _base_path => '/api/fabric/resources/swml_webhooks',
    );
    for my $op (
        sub { $swh->list },
        sub { $swh->get('sw-1') },
        sub { $swh->update('sw-1', name => 'Updated') },
        sub { $swh->delete_resource('sw-1') },
    ) {
        my $captured = _capture_warnings($op);
        is(scalar @{ $captured->{warnings} }, 0,
            'no deprecation warning on non-create op');
    }
};

subtest 'wired class types survive the deprecation refactor' => sub {
    # swml_webhooks is now a SwmlWebhooks (subclass of Resource), cxml_webhooks
    # is a CxmlWebhooks (subclass of Resource). Legacy isa_ok against the base
    # class should still succeed via inheritance.
    my $client = SignalWire::REST::RestClient->new(
        project => 'p', token => 't', host => 'h',
    );
    isa_ok($client->fabric->swml_webhooks,
        'SignalWire::REST::Namespaces::Fabric::Resource',
        'swml_webhooks still isa Resource');
    isa_ok($client->fabric->cxml_webhooks,
        'SignalWire::REST::Namespaces::Fabric::Resource',
        'cxml_webhooks still isa Resource');
    isa_ok($client->fabric->swml_webhooks,
        'SignalWire::REST::Namespaces::Fabric::SwmlWebhooks',
        'swml_webhooks is specifically SwmlWebhooks');
    isa_ok($client->fabric->cxml_webhooks,
        'SignalWire::REST::Namespaces::Fabric::CxmlWebhooks',
        'cxml_webhooks is specifically CxmlWebhooks');
};

done_testing;
