#!/usr/bin/env perl
# Kubernetes-Ready Agent Example
#
# Demonstrates an agent configured for production Kubernetes deployment with:
# - Health and readiness endpoints (auto-provided at /health and /ready)
# - Environment variable configuration (PORT, LOG_LEVEL)
# - Graceful shutdown handling
#
# Usage:
#   perl -Ilib examples/kubernetes.pl
#   PORT=8081 perl -Ilib examples/kubernetes.pl

use strict;
use warnings;
use lib 'lib';
use SignalWire;
use SignalWire::Agent::AgentBase;
use SignalWire::SWAIG::FunctionResult;

# Port from environment or default 8080
my $port = $ENV{PORT} || 8080;

my $agent = SignalWire::Agent::AgentBase->new(
    name  => 'k8s-agent',
    route => '/',
    host  => '0.0.0.0',
    port  => $port,
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

$agent->prompt_add_section(
    'Role',
    'You are a production-ready AI agent running in Kubernetes. '
    . 'You can help users with general questions and demonstrate cloud-native deployment patterns.',
);

# Health status tool
$agent->define_tool(
    name        => 'health_status',
    description => 'Get the health status of this agent',
    parameters  => { type => 'object', properties => {} },
    handler     => sub {
        my ($args, $raw) = @_;
        return SignalWire::SWAIG::FunctionResult->new(
            "Agent k8s-agent is healthy, running on port $port in Kubernetes."
        );
    },
);

print "READY: Kubernetes-ready agent starting on port $port\n";
print "HEALTH: Health check: http://localhost:$port/health\n";
print "STATUS: Readiness check: http://localhost:$port/ready\n";
print "LOG: Log level: " . ($ENV{LOG_LEVEL} || 'INFO') . "\n\n";

$agent->run;
