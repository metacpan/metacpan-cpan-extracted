#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON qw(encode_json decode_json);
use MIME::Base64 qw(encode_base64);

use_ok('SignalWire::Agent::AgentBase');

# ============================================================
# 1. Webhook URL setters
# ============================================================
subtest 'set_web_hook_url' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'wh');
    my $ret = $a->set_web_hook_url('https://example.com/swaig');
    is($ret, $a, 'returns self');
    is($a->webhook_url, 'https://example.com/swaig', 'webhook_url set');
};

subtest 'set_post_prompt_url' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'pp');
    my $ret = $a->set_post_prompt_url('https://example.com/post_prompt');
    is($ret, $a, 'returns self');
    is($a->post_prompt_url, 'https://example.com/post_prompt', 'post_prompt_url set');
};

# ============================================================
# 2. Proxy URL
# ============================================================
subtest 'manual_set_proxy_url' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'proxy');
    my $ret = $a->manual_set_proxy_url('https://proxy.example.com');
    is($ret, $a, 'returns self');
    is($a->proxy_url_base, 'https://proxy.example.com', 'proxy_url_base set');
};

subtest 'proxy URL from env' => sub {
    local $ENV{SWML_PROXY_URL_BASE} = 'https://env-proxy.example.com';
    my $a = SignalWire::Agent::AgentBase->new(name => 'env_proxy');
    is($a->proxy_url_base, 'https://env-proxy.example.com', 'proxy from env');
};

# ============================================================
# 3. Query params
# ============================================================
subtest 'add_swaig_query_params' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'qp');
    my $ret = $a->add_swaig_query_params(key1 => 'val1', key2 => 'val2');
    is($ret, $a, 'returns self');
    is($a->swaig_query_params->{key1}, 'val1', 'key1 set');
    is($a->swaig_query_params->{key2}, 'val2', 'key2 set');
};

subtest 'add_swaig_query_params merge' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'qpm');
    $a->add_swaig_query_params(k1 => 'v1');
    $a->add_swaig_query_params(k2 => 'v2');
    is($a->swaig_query_params->{k1}, 'v1', 'first param preserved');
    is($a->swaig_query_params->{k2}, 'v2', 'second param merged');
};

subtest 'clear_swaig_query_params' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'cqp');
    $a->add_swaig_query_params(k => 'v');
    my $ret = $a->clear_swaig_query_params;
    is($ret, $a, 'returns self');
    is(scalar keys %{$a->swaig_query_params}, 0, 'params cleared');
};

# ============================================================
# 4. Query params in webhook URL
# ============================================================
subtest 'query params in webhook URL' => sub {
    my $a = SignalWire::Agent::AgentBase->new(
        name               => 'qp_url',
        basic_auth_user    => 'u',
        basic_auth_password => 'p',
    );
    $a->add_swaig_query_params(agent_id => '123', mode => 'test');
    $a->define_tool(name => 'tool1', description => 'T', handler => sub { {} });
    my $swml = $a->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    my $url = $ai[0]{ai}{SWAIG}{functions}[0]{web_hook_url};
    like($url, qr/agent_id=123/, 'query param agent_id in URL');
    like($url, qr/mode=test/, 'query param mode in URL');
};

# ============================================================
# 5. Dynamic config callback
# ============================================================
subtest 'set_dynamic_config_callback' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'dc');
    my $cb = sub { 1 };
    my $ret = $a->set_dynamic_config_callback($cb);
    is($ret, $a, 'returns self');
    is($a->dynamic_config_callback, $cb, 'callback set');
};

subtest 'dynamic config callback invoked via PSGI' => sub {
    my $a = SignalWire::Agent::AgentBase->new(
        name               => 'dc_psgi',
        basic_auth_user    => 'u',
        basic_auth_password => 'p',
    );
    my $callback_called = 0;
    $a->set_dynamic_config_callback(sub {
        my ($q, $b, $h, $clone) = @_;
        $callback_called = 1;
        $clone->add_hint('dynamic_hint');
    });

    my $app = $a->psgi_app;
    my $auth = encode_base64('u:p', '');
    my $res = $app->({
        REQUEST_METHOD     => 'GET',
        PATH_INFO          => '/',
        SCRIPT_NAME        => '',
        SERVER_NAME        => 'localhost',
        SERVER_PORT        => 3000,
        HTTP_AUTHORIZATION => "Basic $auth",
        QUERY_STRING       => 'foo=bar',
        'psgi.input'       => do { open my $fh, '<', \(''); $fh },
    });
    is($res->[0], 200, 'request succeeds');
    ok($callback_called, 'callback was invoked');
    # Original agent should not have the hint
    ok(!grep({ $_ eq 'dynamic_hint' } @{$a->hints}), 'original unmodified');
};

# ============================================================
# 6. Proxy detection from headers
# ============================================================
subtest 'proxy detection X-Forwarded' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'proxy_detect');
    my $url = $a->_detect_proxy_url({
        HTTP_X_FORWARDED_PROTO => 'https',
        HTTP_X_FORWARDED_HOST  => 'proxy.example.com',
    });
    is($url, 'https://proxy.example.com', 'proxy detected from forwarded headers');
};

subtest 'proxy detection X-Original-URL' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'proxy_orig');
    my $url = $a->_detect_proxy_url({
        HTTP_X_ORIGINAL_URL => 'https://original.example.com',
    });
    is($url, 'https://original.example.com', 'proxy detected from X-Original-URL');
};

subtest 'proxy detection fallback' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'proxy_fb', host => 'myhost', port => 5000);
    my $url = $a->_detect_proxy_url({});
    is($url, 'http://myhost:5000', 'fallback to host:port');
};

# ============================================================
# 7. get_full_url
# ============================================================
subtest 'get_full_url' => sub {
    my $a = SignalWire::Agent::AgentBase->new(
        name               => 'full_url',
        route              => '/myagent',
        host               => 'localhost',
        port               => 5000,
        basic_auth_user    => 'user',
        basic_auth_password => 'pass',
    );
    my $url = $a->get_full_url;
    like($url, qr/localhost:5000\/myagent/, 'includes host, port, route');
    unlike($url, qr/user:pass/, 'no auth by default');

    my $auth_url = $a->get_full_url(include_auth => 1);
    like($auth_url, qr/user:pass\@/, 'auth included');
};

# ============================================================
# 8. Summary callback
# ============================================================
subtest 'on_summary registration form (coderef)' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'sum');
    my $cb = sub { 1 };
    my $ret = $a->on_summary($cb);
    is($ret, $a, 'returns self when called with coderef');
    is($a->summary_callback, $cb, 'callback set');
};

# Python parity: AgentBase.on_summary(summary, raw_data=None).
# When called with a non-coderef (the normal Python invocation form),
# dispatches to the registered callback.
subtest 'on_summary dispatch form invokes registered callback' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'sum_dispatch');
    my @captured;
    $a->on_summary(sub { @captured = @_; return 'dispatched'; });
    my $ret = $a->on_summary({ stage => 'final', text => 'hello' },
                             { raw => 'payload' });
    is($ret, 'dispatched', 'returns the callback return value');
    is_deeply($captured[0], { stage => 'final', text => 'hello' },
              'callback got summary');
    is_deeply($captured[1], { raw => 'payload' },
              'callback got raw_data');
};

subtest 'on_summary dispatch with no callback registered is a no-op' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'sum_no_cb');
    my $ret = $a->on_summary({ stage => 'x' }, undef);
    is($ret, undef, 'no callback => returns undef (mirrors Python pass)');
};

# ============================================================
# 9. Debug event handler
# ============================================================
subtest 'on_debug_event' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'dbg');
    my $cb = sub { 1 };
    my $ret = $a->on_debug_event($cb);
    is($ret, $a, 'returns self');
    is($a->debug_event_handler, $cb, 'handler set');
};

# ============================================================
# 10. Custom webhook URL overrides default
# ============================================================
subtest 'custom webhook URL in SWML' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'custom_wh');
    $a->set_web_hook_url('https://custom.example.com/swaig');
    $a->define_tool(name => 'tool1', description => 'T', handler => sub { {} });
    my $swml = $a->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    like($ai[0]{ai}{SWAIG}{functions}[0]{web_hook_url}, qr/custom\.example\.com/, 'custom webhook used');
};

done_testing;
