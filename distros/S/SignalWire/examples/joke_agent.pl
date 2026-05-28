#!/usr/bin/env perl
# Joke Agent Example
#
# Demonstrates using a raw data_map configuration to integrate with the
# API Ninjas joke API.
#
# Run with: API_NINJAS_KEY=your_api_key perl -Ilib examples/joke_agent.pl
# Get a free key at: https://api.api-ninjas.com/

use strict;
use warnings;
use lib 'lib';
use SignalWire;
use SignalWire::Agent::AgentBase;

my $api_key = $ENV{API_NINJAS_KEY};
unless ($api_key) {
    print "Error: API_NINJAS_KEY environment variable is required\n";
    print "Get your free API key from https://api.api-ninjas.com/\n";
    print "Then run: API_NINJAS_KEY=your_key perl -Ilib examples/joke_agent.pl\n";
    exit 1;
}

my $agent = SignalWire::Agent::AgentBase->new(
    name  => 'Joke Agent',
    route => '/joke-agent',
);

$agent->prompt_add_section('Personality', 'You are a funny assistant who loves to tell jokes.');
$agent->prompt_add_section('Goal', 'Make people laugh with great jokes.');
$agent->prompt_add_section('Instructions', '',
    bullets => [
        'Use the get_joke function to tell jokes when asked',
        'You can tell either regular jokes or dad jokes',
        'Be enthusiastic about sharing humor',
    ],
);

# Register the joke function with raw data_map configuration
$agent->register_swaig_function({
    function    => 'get_joke',
    description => 'tell a joke',
    data_map    => {
        webhooks => [
            {
                url     => "https://api.api-ninjas.com/v1/%{args.type}",
                headers => { 'X-Api-Key' => $api_key },
                output  => {
                    response => 'Tell the user: %{array[0].joke}',
                    action   => [
                        {
                            SWML => {
                                sections => {
                                    main => [{ set => { dad_joke => '%{array[0].joke}' } }],
                                },
                                version => '1.0.0',
                            },
                        },
                    ],
                },
                error_keys => 'error',
                method     => 'GET',
            },
        ],
        output => {
            response => 'Tell the user that the joke service is not working right now and just make up a joke on your own',
        },
    },
    parameters => {
        type       => 'object',
        properties => {
            type => {
                description => "must either be 'jokes' or 'dadjokes'",
                type        => 'string',
            },
        },
    },
});

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

print "Starting Joke Agent\n";
print "Available at: http://localhost:3000/joke-agent\n";
print "Available function: get_joke (jokes or dadjokes)\n\n";

$agent->run;
