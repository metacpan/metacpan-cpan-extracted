#!/usr/bin/env perl
# Simple example of using the SignalWire AI Agent SDK (Perl)
#
# This example demonstrates creating an agent using explicit methods
# to manipulate the POM (Prompt Object Model) structure directly.

use strict;
use warnings;
use lib 'lib';
use SignalWire::Agents;
use SignalWire::Agents::Agent::AgentBase;
use SignalWire::Agents::SWAIG::FunctionResult;
use POSIX qw(strftime);

# Create an agent
my $agent = SignalWire::Agents::Agent::AgentBase->new(
    name  => 'simple',
    route => '/simple',
    host  => '0.0.0.0',
    port  => 3000,
);

# --- Prompt Configuration ---

$agent->prompt_add_section('Personality', 'You are a friendly and helpful assistant.');
$agent->prompt_add_section('Goal', 'Help users with basic tasks and answer questions.');
$agent->prompt_add_section('Instructions', '',
    bullets => [
        'Be concise and direct in your responses.',
        "If you don't know something, say so clearly.",
        'Use the get_time function when asked about the current time.',
        'Use the get_weather function when asked about the weather.',
    ],
);

# LLM parameters
$agent->set_prompt_llm_params(
    temperature       => 0.3,
    top_p             => 0.9,
    barge_confidence  => 0.7,
    presence_penalty  => 0.1,
    frequency_penalty => 0.2,
);

# Post-prompt for summary generation
$agent->set_post_prompt(<<'POST_PROMPT');
Return a JSON summary of the conversation:
{
    "topic": "MAIN_TOPIC",
    "satisfied": true/false,
    "follow_up_needed": true/false
}
POST_PROMPT

# --- Pronunciation and Hints ---

$agent->add_hints('SignalWire', 'SWML', 'SWAIG');
$agent->add_pronunciation('API', 'A P I', ignore_case => 0);
$agent->add_pronunciation('SIP', 'sip',   ignore_case => 1);

# --- Languages ---

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->add_language(name => 'Spanish', code => 'es',    voice => 'inworld.Sarah');
$agent->add_language(name => 'French',  code => 'fr-FR', voice => 'inworld.Hanna');

# --- AI Behavior ---

$agent->set_params({
    ai_model             => 'gpt-4.1-nano',
    wait_for_user        => JSON::false,
    end_of_speech_timeout => 1000,
    ai_volume            => 5,
    languages_enabled    => JSON::true,
    local_tz             => 'America/Los_Angeles',
});

$agent->set_global_data({
    company_name       => 'SignalWire',
    product            => 'AI Agent SDK',
    supported_features => ['Voice AI', 'Telephone integration', 'SWAIG functions'],
});

# --- Native Functions ---

$agent->set_native_functions(['check_time', 'wait_seconds']);

# --- Tool Definitions ---

$agent->define_tool(
    name        => 'get_time',
    description => 'Get the current time',
    parameters  => { type => 'object', properties => {} },
    handler     => sub {
        my ($args, $raw_data) = @_;
        my $time = strftime('%H:%M:%S', localtime);
        return SignalWire::Agents::SWAIG::FunctionResult->new("The current time is $time");
    },
);

$agent->define_tool(
    name        => 'get_weather',
    description => 'Get the current weather for a location',
    parameters  => {
        type       => 'object',
        properties => {
            location => { type => 'string', description => 'The city or location to get weather for' },
        },
    },
    handler => sub {
        my ($args, $raw_data) = @_;
        my $location = $args->{location} // 'Unknown location';
        my $result = SignalWire::Agents::SWAIG::FunctionResult->new(
            "It's sunny and 72F in $location."
        );
        $result->add_action('set_global_data', { weather_location => $location });
        return $result;
    },
);

# --- Summary Callback ---

$agent->on_summary(sub {
    my ($summary, $raw_data) = @_;
    if ($summary) {
        require JSON;
        if (ref $summary) {
            print "SUMMARY: " . JSON::encode_json($summary) . "\n";
        } else {
            print "SUMMARY: $summary\n";
        }
    }
});

# --- Start the Agent ---

my $user = $agent->basic_auth_user;
my $pass = $agent->basic_auth_password;

print "Starting the agent. Press Ctrl+C to stop.\n";
print "Agent 'simple' is available at:\n";
print "URL: http://localhost:3000/simple\n";
print "Basic Auth: $user:$pass\n";

$agent->run;
