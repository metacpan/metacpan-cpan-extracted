#!/usr/bin/env perl
# SWAIG Features Example
#
# Demonstrates enhanced SWAIG features of the SignalWire AI Agent SDK:
# - Default webhook URL for all functions
# - Properly structured parameters with type:object and properties
# - Speech fillers for functions (provide feedback during processing)
# - Multiple tool definitions with different parameter styles

use strict;
use warnings;
use lib 'lib';
use POSIX qw(strftime);
use SignalWire::Agents;
use SignalWire::Agents::Agent::AgentBase;
use SignalWire::Agents::SWAIG::FunctionResult;

my $agent = SignalWire::Agents::Agent::AgentBase->new(
    name  => 'swaig_features',
    route => '/swaig_features',
);

# --- Prompt sections ---

$agent->prompt_add_section('Personality', 'You are a friendly and helpful assistant.');
$agent->prompt_add_section('Goal', 'Demonstrate advanced SWAIG features.');
$agent->prompt_add_section('Instructions', '',
    bullets => [
        'Be concise and direct in your responses.',
        'Use the get_weather function when asked about weather.',
        'Use the get_time function when asked about the current time.',
    ],
);

# Post-prompt for summary
$agent->set_post_prompt(<<'POST');
Return a JSON summary of the conversation:
{
    "topic": "MAIN_TOPIC",
    "functions_used": ["list", "of", "functions", "used"]
}
POST

# --- Tool: get_time with fillers ---

$agent->define_tool(
    name        => 'get_time',
    description => 'Get the current time',
    parameters  => { type => 'object', properties => {} },
    fillers     => {
        'en-US' => [
            'Let me check the time for you',
            'One moment while I check the current time',
        ],
    },
    handler => sub {
        my ($args, $raw) = @_;
        my $time = strftime('%H:%M:%S', localtime);
        return SignalWire::Agents::SWAIG::FunctionResult->new("The current time is $time");
    },
);

# --- Tool: get_weather with multilingual fillers ---

$agent->define_tool(
    name        => 'get_weather',
    description => 'Get the current weather for a location (including Star Wars planets)',
    parameters  => {
        type       => 'object',
        properties => {
            location => { type => 'string', description => 'The city or location' },
        },
    },
    fillers => {
        'en-US' => [
            'I am checking the weather for you',
            'Let me look up the weather information',
        ],
        'es' => [
            'Estoy consultando el clima para ti',
        ],
    },
    handler => sub {
        my ($args, $raw) = @_;
        my $location = $args->{location} // 'Unknown';
        my %weather = (
            tatooine => 'Hot and dry, with occasional sandstorms. Twin suns at their peak.',
            hoth     => 'Extremely cold with blizzard conditions. High of -20C.',
            endor    => 'Mild forest weather. Partly cloudy with a high of 22C.',
        );
        my $result = $weather{lc($location)} // "It's sunny and 72F";
        return SignalWire::Agents::SWAIG::FunctionResult->new(
            "The weather in $location: $result"
        );
    },
);

# --- Tool: get_forecast ---

$agent->define_tool(
    name        => 'get_forecast',
    description => 'Get a 3-day weather forecast for a location',
    parameters  => {
        type       => 'object',
        properties => {
            location => { type => 'string', description => 'The city or location' },
            units    => {
                type        => 'string',
                description => 'Temperature units (celsius or fahrenheit)',
                enum        => ['celsius', 'fahrenheit'],
            },
        },
    },
    handler => sub {
        my ($args, $raw) = @_;
        my $location = $args->{location} // 'Unknown';
        my $units    = $args->{units}    // 'fahrenheit';
        my @forecast = (
            { day => 'Today',     temp => 72, condition => 'Sunny' },
            { day => 'Tomorrow',  temp => 68, condition => 'Partly Cloudy' },
            { day => 'Day After', temp => 75, condition => 'Clear' },
        );
        my $suffix = 'F';
        if ($units eq 'celsius') {
            $suffix = 'C';
            for my $d (@forecast) {
                $d->{temp} = int(($d->{temp} - 32) * 5 / 9);
            }
        }
        my $text = join("\n", map { "$_->{day}: $_->{temp}$suffix, $_->{condition}" } @forecast);
        return SignalWire::Agents::SWAIG::FunctionResult->new(
            "3-day forecast for $location:\n$text"
        );
    },
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

print "Starting SWAIG Features Agent\n";
print "Available at: http://localhost:3000/swaig_features\n";

$agent->run;
