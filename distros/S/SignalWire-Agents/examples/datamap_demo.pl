#!/usr/bin/env perl
# DataMap Demo - Shows how to use the DataMap class for server-side tools
#
# This demo creates an agent with data_map tools:
# 1. Simple API call (weather)
# 2. Expression-based pattern matching
# These tools execute on SignalWire's servers, no webhook needed.

use strict;
use warnings;
use lib 'lib';
use SignalWire::Agents;
use SignalWire::Agents::Agent::AgentBase;
use SignalWire::Agents::DataMap;
use SignalWire::Agents::SWAIG::FunctionResult;

my $agent = SignalWire::Agents::Agent::AgentBase->new(
    name  => 'datamap-demo',
    route => '/datamap-demo',
);

$agent->prompt_add_section(
    'Role',
    'You are a helpful assistant with access to weather data and file playback control.',
);

# 1. Simple weather API via DataMap
my $weather = SignalWire::Agents::DataMap->new('get_weather')
    ->description('Get weather for a location')
    ->parameter('location', 'string', 'City name or location', required => 1)
    ->webhook('GET', 'https://api.weather.com/v1/current?key=API_KEY&q=${args.location}')
    ->output(
        SignalWire::Agents::SWAIG::FunctionResult->new(
            'Current weather in ${args.location}: ${response.current.condition.text}, ${response.current.temp_f}F'
        )
    );

$agent->register_swaig_function($weather->to_swaig_function);

# 2. Expression-based file control (no API calls)
my $file_control = SignalWire::Agents::DataMap->new('file_control')
    ->description('Control audio/video playback')
    ->parameter('command', 'string', 'Playback command', required => 1,
        enum => ['play', 'pause', 'stop', 'next', 'previous'])
    ->expression(
        '${args.command}',
        'play|resume',
        SignalWire::Agents::SWAIG::FunctionResult->new('Playback started'),
        nomatch_output => SignalWire::Agents::SWAIG::FunctionResult->new('Playback stopped'),
    );

$agent->register_swaig_function($file_control->to_swaig_function);

# 3. Regular SWAIG function for comparison
$agent->define_tool(
    name        => 'echo_test',
    description => 'A simple echo function for testing',
    parameters  => {
        type       => 'object',
        properties => {
            message => { type => 'string', description => 'Message to echo back' },
        },
    },
    handler => sub {
        my ($args, $raw) = @_;
        my $msg = $args->{message} // 'nothing';
        return SignalWire::Agents::SWAIG::FunctionResult->new("Echo: $msg");
    },
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

print "Starting DataMap Demo Agent\n";
print "Available at: http://localhost:3000/datamap-demo\n";

$agent->run;
