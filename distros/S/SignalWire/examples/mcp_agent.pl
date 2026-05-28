#!/usr/bin/env perl
# MCP Integration Example
#
# Demonstrates both MCP features:
# - MCP Client: connect to external MCP servers for tool discovery
# - MCP Server: expose this agent's tools as an MCP endpoint
#
# Run: perl -Ilib examples/mcp_agent.pl

use strict;
use warnings;
use lib 'lib';
use SignalWire::Agent::AgentBase;
use SignalWire::SWAIG::FunctionResult;

my $agent = SignalWire::Agent::AgentBase->new(
    name  => 'mcp-demo',
    route => '/mcp-demo',
);

$agent->set_prompt_text("You are a helpful assistant with access to external tools via MCP.");

# MCP Client: connect to external MCP servers
# Tools are discovered at call time via the MCP protocol
$agent->add_mcp_server(
    'https://mcp.example.com/tools',
    headers => { 'Authorization' => 'Bearer sk-xxx' },
);

# MCP Client with resources: fetch data into global_data
$agent->add_mcp_server(
    'https://mcp.example.com/crm',
    headers  => { 'Authorization' => 'Bearer crm-key' },
    resources => 1,
    resource_vars => { caller_id => '${caller_id_number}' },
);

# MCP Server: expose this agent's tools at /mcp-demo/mcp
$agent->enable_mcp_server();

# Define a tool (available via both SWAIG webhooks AND MCP)
$agent->define_tool(
    name        => 'get_weather',
    description => 'Get weather for a location',
    parameters  => { location => { type => 'string', description => 'City name' } },
    handler     => sub {
        my ($args, $raw_data) = @_;
        my $location = $args->{location} || 'unknown';
        return SignalWire::SWAIG::FunctionResult->new(
            response => "72F and sunny in $location"
        );
    },
);

$agent->run;
