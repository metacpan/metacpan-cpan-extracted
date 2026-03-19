#!/usr/bin/env perl
# Contexts and Steps Demo Agent
#
# Demonstrates the contexts system including:
# - Context entry parameters (system_prompt, consolidate, full_reset)
# - Step-to-context navigation with context switching
# - Multi-persona experience

use strict;
use warnings;
use lib 'lib';
use SignalWire::Agents;
use SignalWire::Agents::Agent::AgentBase;

my $agent = SignalWire::Agents::Agent::AgentBase->new(
    name  => 'Advanced Computer Sales Agent',
    route => '/advanced-contexts-demo',
);

# Base prompt (required even when using contexts)
$agent->prompt_add_section(
    'Instructions',
    'Follow the structured sales workflow to guide customers through their computer purchase decision.',
    bullets => [
        "Complete each step's specific criteria before advancing",
        'Ask focused questions to gather the exact information needed',
        'Be helpful and consultative, not pushy',
    ],
);

# Define contexts using the ContextBuilder
my $ctx = $agent->define_contexts;

# Sales context
$ctx->add_context('sales',
    system_prompt => 'You are Franklin, a friendly computer sales consultant.',
    consolidate   => 1,
    steps         => [
        {
            name     => 'greeting',
            prompt   => 'Greet the customer and ask what kind of computer they need.',
            criteria => 'Customer has stated their general needs.',
            valid_steps => ['needs_assessment'],
        },
        {
            name     => 'needs_assessment',
            prompt   => 'Ask about budget, use case, and specific requirements.',
            criteria => 'Budget and use case are known.',
            valid_steps    => ['recommendation'],
            valid_contexts => ['support'],
        },
        {
            name   => 'recommendation',
            prompt => 'Recommend a computer based on the gathered requirements.',
            criteria => 'Customer has received a recommendation.',
            valid_contexts => ['support'],
        },
    ],
);

# Support context
$ctx->add_context('support',
    system_prompt => 'You are Rachael, a technical support specialist.',
    full_reset    => 1,
    steps         => [
        {
            name   => 'diagnose',
            prompt => 'Help the customer with any technical questions or issues.',
            criteria => 'Issue has been identified or question answered.',
            valid_contexts => ['sales'],
        },
    ],
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

print "Starting Contexts Demo Agent\n";
print "Available at: http://localhost:3000/advanced-contexts-demo\n";

$agent->run;
