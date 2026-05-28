#!/usr/bin/env perl
# Declarative Agent Example
#
# Demonstrates defining an agent's prompt using prompt_add_section calls
# in a clean, declarative style. The entire prompt structure is set up
# at construction time with no dynamic configuration.
#
# Also shows:
# - Post-prompt for structured summary output
# - SWAIG tool definitions with handlers
# - Summary callback processing

use strict;
use warnings;
use lib 'lib';
use JSON qw(encode_json);
use POSIX qw(strftime);
use SignalWire;
use SignalWire::Agent::AgentBase;
use SignalWire::SWAIG::FunctionResult;

my $agent = SignalWire::Agent::AgentBase->new(
    name  => 'declarative',
    route => '/declarative',
);

# --- Declarative Prompt Sections ---

$agent->prompt_add_section(
    'Personality',
    'You are a friendly and helpful AI assistant who responds in a casual, conversational tone.',
);

$agent->prompt_add_section(
    'Goal',
    'Help users with their questions about time and weather.',
);

$agent->prompt_add_section('Instructions', '',
    bullets => [
        'Be concise and direct in your responses.',
        "If you don't know something, say so clearly.",
        'Use the get_time function when asked about the current time.',
        'Use the get_weather function when asked about the weather.',
    ],
);

$agent->prompt_add_section('Examples',
    'Here are examples of how to respond to common requests:',
);
$agent->prompt_add_subsection('Examples', 'Time request',
    "User: What time is it?\nAssistant: Let me check for you. [call get_time]",
);
$agent->prompt_add_subsection('Examples', 'Weather request',
    "User: What's the weather like in Paris?\nAssistant: Let me check the weather for you. [call get_weather]",
);

# --- Post-prompt for summary ---

$agent->set_post_prompt(<<'POST');
Return a JSON summary of the conversation:
{
    "topic": "MAIN_TOPIC",
    "satisfied": true/false,
    "follow_up_needed": true/false
}
POST

# --- Tool definitions ---

$agent->define_tool(
    name        => 'get_time',
    description => 'Get the current time',
    parameters  => { type => 'object', properties => {} },
    handler     => sub {
        my ($args, $raw) = @_;
        my $time = strftime('%H:%M:%S', localtime);
        return SignalWire::SWAIG::FunctionResult->new("The current time is $time");
    },
);

$agent->define_tool(
    name        => 'get_weather',
    description => 'Get the current weather for a location',
    parameters  => {
        type       => 'object',
        properties => {
            location => { type => 'string', description => 'The city or location' },
        },
    },
    handler => sub {
        my ($args, $raw) = @_;
        my $loc = $args->{location} // 'Unknown';
        return SignalWire::SWAIG::FunctionResult->new(
            "It's sunny and 72F in $loc."
        );
    },
);

# --- Summary callback ---

$agent->on_summary(sub {
    my ($summary, $raw) = @_;
    if ($summary) {
        print "Conversation summary: " . encode_json($summary) . "\n";
    }
});

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

print "Starting Declarative Agent\n";
print "Available at: http://localhost:3000/declarative\n";

$agent->run;
