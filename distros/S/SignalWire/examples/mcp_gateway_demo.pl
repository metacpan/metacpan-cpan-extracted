#!/usr/bin/env perl
# MCP Gateway Demo
#
# Demonstrates connecting a SignalWire AI agent to MCP (Model Context Protocol)
# servers through the mcp_gateway skill. The gateway bridges MCP tools so the
# agent can use them as SWAIG functions.
#
# Prerequisites:
#   Install and start a gateway server: mcp-gateway -c config.json
#
# Environment variables:
#   MCP_GATEWAY_URL          - URL of the running MCP gateway service
#   MCP_GATEWAY_AUTH_USER    - Basic auth username
#   MCP_GATEWAY_AUTH_PASSWORD - Basic auth password

use strict;
use warnings;
use lib 'lib';
use SignalWire;
use SignalWire::Agent::AgentBase;

my $agent = SignalWire::Agent::AgentBase->new(
    name  => 'MCP Gateway Agent',
    route => '/mcp-gateway',
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

$agent->prompt_add_section(
    'Role',
    'You are a helpful assistant with access to external tools provided '
    . 'through MCP servers. Use the available tools to help users accomplish '
    . 'their tasks.',
);

# Connect to MCP gateway - tools are discovered automatically
eval {
    $agent->add_skill('mcp_gateway', {
        gateway_url   => $ENV{MCP_GATEWAY_URL}           // 'http://localhost:8080',
        auth_user     => $ENV{MCP_GATEWAY_AUTH_USER}      // 'admin',
        auth_password => $ENV{MCP_GATEWAY_AUTH_PASSWORD}  // 'changeme',
        services      => [{ name => 'todo' }],
    });
    print "MCP Gateway skill loaded successfully\n";
};
if ($@) {
    print "Warning: Failed to load MCP Gateway skill: $@\n";
    print "Set MCP_GATEWAY_URL, MCP_GATEWAY_AUTH_USER, MCP_GATEWAY_AUTH_PASSWORD\n";
}

print "Starting MCP Gateway Agent\n";
print "Available at: http://localhost:3000/mcp-gateway\n\n";

$agent->run;
