#!/usr/bin/env perl
# Simple Dynamic Agent Example
#
# This agent is configured dynamically per-request using a callback.
# The configuration happens fresh for each incoming request, allowing
# parameter-based customization (VIP routing, tenant isolation, etc.).

use strict;
use warnings;
use lib 'lib';
use SignalWire::Agents;
use SignalWire::Agents::Agent::AgentBase;

my $agent = SignalWire::Agents::Agent::AgentBase->new(
    name        => 'Simple Customer Service Agent (Dynamic)',
    auto_answer => 1,
    record_call => 1,
);

# Set up a dynamic configuration callback instead of static config
$agent->set_dynamic_config_callback(sub {
    my ($query_params, $body_params, $headers, $agent_clone) = @_;

    # Voice and language
    $agent_clone->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');

    # AI parameters
    $agent_clone->set_params({
        ai_model             => 'gpt-4.1-nano',
        end_of_speech_timeout => 500,
        attention_timeout    => 15000,
        background_file_volume => -20,
    });

    # Hints for speech recognition
    $agent_clone->add_hints('SignalWire', 'SWML', 'API', 'webhook', 'SIP');

    # Global data
    $agent_clone->set_global_data({
        agent_type       => 'customer_service',
        service_level    => 'standard',
        features_enabled => ['basic_conversation', 'help_desk'],
        session_info     => {
            environment => 'production',
            version     => '1.0',
        },
    });

    # Prompt sections
    $agent_clone->prompt_add_section(
        'Role and Purpose',
        'You are a professional customer service representative. Your goal is to help '
        . 'customers with their questions and provide excellent service.',
    );

    $agent_clone->prompt_add_section(
        'Guidelines',
        'Follow these customer service principles:',
        bullets => [
            'Listen carefully to customer needs',
            'Provide accurate and helpful information',
            'Maintain a professional and friendly tone',
            'Escalate complex issues when appropriate',
            'Always confirm understanding before ending',
        ],
    );

    $agent_clone->prompt_add_section(
        'Available Services',
        'You can help customers with:',
        bullets => [
            'General product information',
            'Account questions and support',
            'Technical troubleshooting guidance',
            'Billing and payment inquiries',
            'Service status and updates',
        ],
    );
});

print "Starting Simple Dynamic Agent -- configuration changes based on requests\n";
print "Available at: http://localhost:3000/\n";

$agent->run;
