#!/usr/bin/env perl
# Joke Skill Demo -- Using the Modular Skills System
#
# Demonstrates the joke skill via the skills system with DataMap
# for serverless execution. Compare with joke_agent.pl (raw data_map).
#
# Required: API_NINJAS_KEY environment variable.

use strict;
use warnings;
use lib 'lib';
use SignalWire;
use SignalWire::Agent::AgentBase;

my $api_key = $ENV{API_NINJAS_KEY};
unless ($api_key) {
    die "Error: API_NINJAS_KEY environment variable is required.\n"
      . "Get your free API key from https://api.api-ninjas.com/\n";
}

my $agent = SignalWire::Agent::AgentBase->new(
    name  => 'Joke Skill Demo',
    route => '/joke-skill',
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

$agent->prompt_add_section('Personality',
    'You are a cheerful comedian who loves sharing jokes and making people laugh.');
$agent->prompt_add_section('Instructions', '',
    bullets => [
        'When users ask for jokes, use your joke functions to provide them',
        'Be enthusiastic and fun in your responses',
        'You can tell both regular jokes and dad jokes',
    ],
);

$agent->add_skill('joke', { api_key => $api_key });

print "Joke Skill Demo (modular skills system)\n";
print "  Benefits over raw DataMap:\n";
print "    - One-liner integration via skills system\n";
print "    - Automatic validation and error handling\n";
print "    - Reusable across agents\n\n";

$agent->run;
