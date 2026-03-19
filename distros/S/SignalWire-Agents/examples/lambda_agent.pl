#!/usr/bin/env perl
# AWS Lambda / Serverless Deployment Example
#
# Demonstrates how to prepare a SignalWire AI Agent for serverless deployment.
# The agent is configured identically to a normal server deployment; the SDK
# auto-detects the serverless environment at runtime.
#
# In a real Lambda deployment you would use a Perl PSGI adapter (e.g.,
# AWS::Lambda::PSGI) to bridge Lambda events to the PSGI app produced
# by $agent->to_psgi_app.
#
# For local testing, just run it normally:
#   perl -Ilib examples/lambda_agent.pl

use strict;
use warnings;
use lib 'lib';
use POSIX qw(strftime);
use SignalWire::Agents;
use SignalWire::Agents::Agent::AgentBase;
use SignalWire::Agents::SWAIG::FunctionResult;

my $agent = SignalWire::Agents::Agent::AgentBase->new(
    name  => 'lambda-agent',
    route => '/',
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

$agent->prompt_add_section(
    'Role',
    'You are a helpful AI assistant running in AWS Lambda.',
);
$agent->prompt_add_section('Instructions', '',
    bullets => [
        'Greet users warmly and offer help',
        'Use the greet_user function when asked to greet someone',
        'Use the get_time function when asked about the current time',
    ],
);

$agent->define_tool(
    name        => 'greet_user',
    description => 'Greet a user by name',
    parameters  => {
        type       => 'object',
        properties => {
            name => { type => 'string', description => 'Name of the user to greet' },
        },
    },
    handler => sub {
        my ($args, $raw) = @_;
        my $name = $args->{name} // 'friend';
        return SignalWire::Agents::SWAIG::FunctionResult->new(
            "Hello $name! I'm running in AWS Lambda!"
        );
    },
);

$agent->define_tool(
    name        => 'get_time',
    description => 'Get the current time',
    parameters  => { type => 'object', properties => {} },
    handler     => sub {
        my ($args, $raw) = @_;
        my $time = strftime('%Y-%m-%dT%H:%M:%S', localtime);
        return SignalWire::Agents::SWAIG::FunctionResult->new(
            "Current time: $time"
        );
    },
);

print "Starting Lambda Agent (local testing mode)\n";
print "Available at: http://localhost:3000/\n";
print "In production, deploy with a PSGI-to-Lambda adapter.\n\n";

$agent->run;
