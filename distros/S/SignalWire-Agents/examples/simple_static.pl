#!/usr/bin/env perl
# Simple Static Agent Example (Traditional Way)
#
# Demonstrates the traditional way of configuring an agent with static settings.
# All configuration is done during initialization and remains the same for
# every request -- no dynamic callback is used.
#
# Features:
# - Professional voice (inworld.Mark)
# - 500ms speech timeout
# - Speech recognition hints
# - Global data with session info
# - Customer service focused prompt
#
# Usage:
#   perl -Ilib examples/simple_static.pl

use strict;
use warnings;
use lib 'lib';
use SignalWire::Agents;
use SignalWire::Agents::Agent::AgentBase;

my $agent = SignalWire::Agents::Agent::AgentBase->new(
    name        => 'Simple Customer Service Agent',
    auto_answer => 1,
    record_call => 1,
);

# STATIC CONFIGURATION - Set once during initialization

# Voice and language
$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');

# AI parameters
$agent->set_params({
    ai_model               => 'gpt-4.1-nano',
    end_of_speech_timeout   => 500,
    attention_timeout       => 15000,
    background_file_volume  => -20,
});

# Hints for speech recognition
$agent->add_hints('SignalWire', 'SWML', 'API', 'webhook', 'SIP');

# Global data (same for every call)
$agent->set_global_data({
    agent_type       => 'customer_service',
    service_level    => 'standard',
    features_enabled => ['basic_conversation', 'help_desk'],
    session_info     => {
        environment => 'production',
        version     => '1.0',
    },
});

# Prompt sections
$agent->prompt_add_section(
    'Role and Purpose',
    'You are a professional customer service representative. Your goal is to help '
    . 'customers with their questions and provide excellent service.',
);

$agent->prompt_add_section(
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

$agent->prompt_add_section(
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

print "Starting Simple Static Agent\n\n";
print "Configuration: STATIC (set once at startup)\n";
print "- Voice: inworld.Mark (professional)\n";
print "- Service Level: standard\n";
print "- Speech Timeout: 500ms\n\n";
print "Available at: http://localhost:3000/\n";
print "Note: Configuration never changes regardless of request parameters\n\n";

$agent->run;
