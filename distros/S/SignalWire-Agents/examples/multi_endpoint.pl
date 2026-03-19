#!/usr/bin/env perl
# Multi-Endpoint Agent Example
#
# Demonstrates serving multiple endpoints from a single agent:
# - /swml       - Voice AI SWML endpoint
# - /swml/swaig - SWAIG webhook callbacks
# - /health     - Health check (auto-provided)
# - /ready      - Readiness check (auto-provided)
#
# The agent's SWML and SWAIG endpoints are mounted at /swml, while health
# and readiness endpoints are available at the root level automatically.

use strict;
use warnings;
use lib 'lib';
use POSIX qw(strftime);
use SignalWire::Agents;
use SignalWire::Agents::Agent::AgentBase;
use SignalWire::Agents::SWAIG::FunctionResult;

my $agent = SignalWire::Agents::Agent::AgentBase->new(
    name  => 'multi-endpoint',
    route => '/swml',
    host  => '0.0.0.0',
    port  => 8080,
);

# Configure the voice AI agent
$agent->prompt_add_section('Role', 'You are a helpful voice assistant.');
$agent->prompt_add_section('Instructions', '',
    bullets => [
        'Greet callers warmly',
        'Be concise in your responses',
        'Use the available functions when appropriate',
    ],
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

# Tool: get_time
$agent->define_tool(
    name        => 'get_time',
    description => 'Get the current time',
    parameters  => { type => 'object', properties => {} },
    handler     => sub {
        my ($args, $raw) = @_;
        my $now = strftime('%I:%M %p', localtime);
        return SignalWire::Agents::SWAIG::FunctionResult->new("The current time is $now");
    },
);

my $user = $agent->basic_auth_user;
my $pass = $agent->basic_auth_password;

print "Multi-Endpoint Agent starting...\n";
print "Server: http://0.0.0.0:8080\n";
print "Basic Auth: $user:$pass\n\n";
print "Endpoints:\n";
print "  SWML:     http://0.0.0.0:8080/swml\n";
print "  SWAIG:    http://0.0.0.0:8080/swml/swaig\n";
print "  Health:   http://0.0.0.0:8080/health\n";
print "  Ready:    http://0.0.0.0:8080/ready\n\n";

$agent->run;
