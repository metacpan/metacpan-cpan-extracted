#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON qw(encode_json decode_json);

use_ok('SignalWire::Agent::AgentBase');
use_ok('SignalWire::SWAIG::FunctionResult');

# ============================================================
# Helper: create an MCP-enabled agent with a tool
# ============================================================
sub make_mcp_agent {
    my $agent = SignalWire::Agent::AgentBase->new(
        name  => 'test-mcp',
        route => '/test',
    );
    $agent->enable_mcp_server;

    $agent->define_tool(
        name        => 'get_weather',
        description => 'Get the weather for a location',
        parameters  => {
            location => { type => 'string', description => 'City name' },
        },
        handler => sub {
            my ($args, $raw) = @_;
            my $loc = $args->{location} // 'unknown';
            return SignalWire::SWAIG::FunctionResult->new("72F sunny in $loc");
        },
    );

    return $agent;
}

# ============================================================
# MCP Server tests
# ============================================================

subtest 'build tool list' => sub {
    my $agent = make_mcp_agent();
    my $tools = $agent->_build_mcp_tool_list;

    is(scalar @$tools, 1, 'one tool');
    is($tools->[0]{name}, 'get_weather', 'tool name');
    is($tools->[0]{description}, 'Get the weather for a location', 'description');
    ok(exists $tools->[0]{inputSchema}, 'has inputSchema');
    is($tools->[0]{inputSchema}{type}, 'object', 'type=object');
    ok(exists $tools->[0]{inputSchema}{properties}{location}, 'has location property');
};

subtest 'initialize handshake' => sub {
    my $agent = make_mcp_agent();
    my $resp = $agent->_handle_mcp_request({
        jsonrpc => '2.0',
        id      => 1,
        method  => 'initialize',
        params  => {
            protocolVersion => '2025-06-18',
            capabilities    => {},
            clientInfo      => { name => 'test', version => '1.0' },
        },
    });

    is($resp->{jsonrpc}, '2.0', 'jsonrpc=2.0');
    is($resp->{id}, 1, 'id=1');
    ok(exists $resp->{result}, 'has result');
    is($resp->{result}{protocolVersion}, '2025-06-18', 'protocol version');
    ok(exists $resp->{result}{capabilities}{tools}, 'has tools capability');
};

subtest 'initialized notification' => sub {
    my $agent = make_mcp_agent();
    my $resp = $agent->_handle_mcp_request({
        jsonrpc => '2.0',
        method  => 'notifications/initialized',
    });
    ok(exists $resp->{result}, 'has result');
};

subtest 'tools/list' => sub {
    my $agent = make_mcp_agent();
    my $resp = $agent->_handle_mcp_request({
        jsonrpc => '2.0',
        id      => 2,
        method  => 'tools/list',
        params  => {},
    });

    is($resp->{id}, 2, 'id=2');
    my $tools = $resp->{result}{tools};
    is(scalar @$tools, 1, 'one tool');
    is($tools->[0]{name}, 'get_weather', 'tool name');
};

subtest 'tools/call' => sub {
    my $agent = make_mcp_agent();
    my $resp = $agent->_handle_mcp_request({
        jsonrpc => '2.0',
        id      => 3,
        method  => 'tools/call',
        params  => {
            name      => 'get_weather',
            arguments => { location => 'Orlando' },
        },
    });

    is($resp->{id}, 3, 'id=3');
    ok(!$resp->{result}{isError}, 'isError=false');
    my $content = $resp->{result}{content};
    is(scalar @$content, 1, 'one content item');
    is($content->[0]{type}, 'text', 'type=text');
    like($content->[0]{text}, qr/Orlando/, 'text contains Orlando');
};

subtest 'tools/call unknown' => sub {
    my $agent = make_mcp_agent();
    my $resp = $agent->_handle_mcp_request({
        jsonrpc => '2.0',
        id      => 4,
        method  => 'tools/call',
        params  => { name => 'nonexistent', arguments => {} },
    });

    ok(exists $resp->{error}, 'has error');
    is($resp->{error}{code}, -32602, 'code=-32602');
    like($resp->{error}{message}, qr/nonexistent/, 'message mentions tool');
};

subtest 'unknown method' => sub {
    my $agent = make_mcp_agent();
    my $resp = $agent->_handle_mcp_request({
        jsonrpc => '2.0',
        id      => 5,
        method  => 'resources/list',
        params  => {},
    });

    ok(exists $resp->{error}, 'has error');
    is($resp->{error}{code}, -32601, 'code=-32601');
};

subtest 'ping' => sub {
    my $agent = make_mcp_agent();
    my $resp = $agent->_handle_mcp_request({
        jsonrpc => '2.0',
        id      => 6,
        method  => 'ping',
    });
    ok(exists $resp->{result}, 'has result');
};

subtest 'invalid jsonrpc version' => sub {
    my $agent = make_mcp_agent();
    my $resp = $agent->_handle_mcp_request({
        jsonrpc => '1.0',
        id      => 7,
        method  => 'initialize',
    });

    ok(exists $resp->{error}, 'has error');
    is($resp->{error}{code}, -32600, 'code=-32600');
};

# ============================================================
# MCP Client tests (add_mcp_server)
# ============================================================

subtest 'add_mcp_server basic' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'test');
    $agent->add_mcp_server('https://mcp.example.com/tools');

    is(scalar @{ $agent->mcp_servers }, 1, 'one server');
    is($agent->mcp_servers->[0]{url}, 'https://mcp.example.com/tools', 'url');
};

subtest 'add_mcp_server with headers' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'test');
    $agent->add_mcp_server(
        'https://mcp.example.com/tools',
        headers => { Authorization => 'Bearer sk-xxx' },
    );

    is($agent->mcp_servers->[0]{headers}{Authorization}, 'Bearer sk-xxx', 'auth header');
};

subtest 'add_mcp_server with resources' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'test');
    $agent->add_mcp_server(
        'https://mcp.example.com/crm',
        resources     => 1,
        resource_vars => { caller_id => '${caller_id_number}' },
    );

    ok($agent->mcp_servers->[0]{resources}, 'resources=true');
    is($agent->mcp_servers->[0]{resource_vars}{caller_id}, '${caller_id_number}', 'resource_vars');
};

subtest 'add multiple servers' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'test');
    $agent->add_mcp_server('https://mcp1.example.com');
    $agent->add_mcp_server('https://mcp2.example.com');

    is(scalar @{ $agent->mcp_servers }, 2, 'two servers');
};

subtest 'method chaining' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'test');
    my $result = $agent->add_mcp_server('https://mcp.example.com');
    is($result, $agent, 'returns self');
};

subtest 'enable_mcp_server' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'test');
    ok(!$agent->mcp_server_enabled, 'disabled by default');

    my $result = $agent->enable_mcp_server;
    ok($agent->mcp_server_enabled, 'enabled after call');
    is($result, $agent, 'returns self');
};

subtest 'mcp_servers in swml' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'test', route => '/test');
    $agent->add_mcp_server(
        'https://mcp.example.com/tools',
        headers => { Authorization => 'Bearer key' },
    );

    my $swml = $agent->render_swml;
    my $sections = $swml->{sections}{main};
    my ($ai_verb) = grep { exists $_->{ai} } @$sections;
    ok($ai_verb, 'ai verb exists');

    my $ai_config = $ai_verb->{ai};
    ok(exists $ai_config->{mcp_servers}, 'mcp_servers in AI config');
    is(scalar @{ $ai_config->{mcp_servers} }, 1, 'one server');
    is($ai_config->{mcp_servers}[0]{url}, 'https://mcp.example.com/tools', 'url in swml');
};

done_testing;
