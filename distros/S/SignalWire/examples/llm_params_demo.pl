#!/usr/bin/env perl
# LLM Parameters Demo
#
# Demonstrates customizing LLM parameters for different agent personalities:
# 1. Precise Assistant  - Low temperature, hard to interrupt (technical support)
# 2. Creative Assistant  - High temperature, easy to interrupt (creative writing)
# 3. Customer Service    - Balanced parameters (professional support)
#
# Usage:
#   perl -Ilib examples/llm_params.pl              # default: customer service
#   perl -Ilib examples/llm_params.pl precise       # precise technical assistant
#   perl -Ilib examples/llm_params.pl creative      # creative writing assistant
#   perl -Ilib examples/llm_params.pl support       # customer service

use strict;
use warnings;
use lib 'lib';
use SignalWire;
use SignalWire::Agent::AgentBase;
use SignalWire::SWAIG::FunctionResult;

my $mode = lc($ARGV[0] // 'support');

my $agent;

if ($mode eq 'precise') {
    $agent = SignalWire::Agent::AgentBase->new(
        name  => 'precise-assistant',
        route => '/precise',
    );
    $agent->prompt_add_section('Role', 'You are a precise technical assistant.');
    $agent->prompt_add_section('Instructions', '',
        bullets => [
            'Provide accurate, factual information',
            'Be concise and direct',
            'Avoid speculation or guessing',
            'If uncertain, say so clearly',
        ],
    );
    $agent->set_prompt_llm_params(
        temperature       => 0.2,
        top_p             => 0.85,
        barge_confidence  => 0.8,
        presence_penalty  => 0.0,
        frequency_penalty => 0.1,
    );
    $agent->set_post_prompt('Provide a brief technical summary of the key points discussed.');
    $agent->set_post_prompt_llm_params(temperature => 0.1);

    $agent->define_tool(
        name        => 'get_system_info',
        description => 'Get technical system information',
        parameters  => { type => 'object', properties => {} },
        handler     => sub {
            return SignalWire::SWAIG::FunctionResult->new(
                'System Status: CPU 45%, Memory 8GB, Disk 200GB free, Uptime 14 days'
            );
        },
    );
    print "Starting Precise Assistant (low temperature, hard to interrupt)...\n";

} elsif ($mode eq 'creative') {
    $agent = SignalWire::Agent::AgentBase->new(
        name  => 'creative-assistant',
        route => '/creative',
    );
    $agent->prompt_add_section('Role', 'You are a creative writing assistant.');
    $agent->prompt_add_section('Instructions', '',
        bullets => [
            'Be imaginative and creative',
            'Use varied vocabulary and expressions',
            'Encourage creative thinking',
            'Suggest unique perspectives',
        ],
    );
    $agent->set_prompt_llm_params(
        temperature       => 0.8,
        top_p             => 0.95,
        barge_confidence  => 0.5,
        presence_penalty  => 0.2,
        frequency_penalty => 0.3,
    );
    $agent->set_post_prompt('Create an artistic summary of our conversation.');
    $agent->set_post_prompt_llm_params(temperature => 0.7);

    $agent->define_tool(
        name        => 'generate_story_prompt',
        description => 'Generate a creative story prompt',
        parameters  => {
            type       => 'object',
            properties => {
                theme => { type => 'string', description => 'Story theme' },
            },
        },
        handler => sub {
            my ($args, $raw) = @_;
            my $theme = $args->{theme} // 'adventure';
            my %prompts = (
                adventure => 'A compass that points to what you need most',
                mystery   => 'A library book that writes itself',
            );
            my $prompt = $prompts{lc($theme)} // 'An ordinary object with extraordinary powers';
            return SignalWire::SWAIG::FunctionResult->new(
                "Story prompt for $theme: $prompt"
            );
        },
    );
    print "Starting Creative Assistant (high temperature, easy to interrupt)...\n";

} else {
    $agent = SignalWire::Agent::AgentBase->new(
        name  => 'customer-service',
        route => '/support',
    );
    $agent->prompt_add_section('Role', 'You are a professional customer service representative.');
    $agent->prompt_add_section('Guidelines', '',
        bullets => [
            'Always be polite and empathetic',
            'Listen carefully to customer concerns',
            'Provide clear, helpful solutions',
            'Follow company policies',
        ],
    );
    $agent->set_prompt_llm_params(
        temperature       => 0.4,
        top_p             => 0.9,
        barge_confidence  => 0.7,
        presence_penalty  => 0.1,
        frequency_penalty => 0.1,
    );
    $agent->set_post_prompt('Summarize the customer issue and resolution for the ticket system.');
    $agent->set_post_prompt_llm_params(temperature => 0.3);

    $agent->define_tool(
        name        => 'check_order_status',
        description => 'Check the status of a customer order',
        parameters  => {
            type       => 'object',
            properties => {
                order_id => { type => 'string', description => 'Order ID' },
            },
        },
        handler => sub {
            my ($args, $raw) = @_;
            my $oid = $args->{order_id} // 'unknown';
            return SignalWire::SWAIG::FunctionResult->new(
                "Order $oid status: Shipped - Expected delivery in 2 days"
            );
        },
    );
    print "Starting Customer Service Agent (balanced parameters)...\n";
    print "Try: perl -Ilib examples/llm_params.pl [precise|creative|support]\n";
}

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

print "Available at: http://localhost:3000" . $agent->route . "\n\n";

$agent->run;
