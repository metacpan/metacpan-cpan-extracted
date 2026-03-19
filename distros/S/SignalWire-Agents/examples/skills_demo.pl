#!/usr/bin/env perl
# Skills System Demo
#
# Demonstrates the modular skills system. Skills are automatically
# discovered and can be added with simple one-liner calls.
#
# The datetime and math skills work without any additional setup.
# The web_search skill requires GOOGLE_SEARCH_API_KEY and
# GOOGLE_SEARCH_ENGINE_ID environment variables.

use strict;
use warnings;
use lib 'lib';
use SignalWire::Agents;
use SignalWire::Agents::Agent::AgentBase;

my $agent = SignalWire::Agents::Agent::AgentBase->new(
    name  => 'Multi-Skill Assistant',
    route => '/assistant',
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');

$agent->prompt_add_section(
    'Role',
    'You are a helpful assistant with access to various skills including '
    . 'date/time information, mathematical calculations, and web search.',
);

$agent->set_params({ ai_model => 'gpt-4.1-nano' });

print "Creating agent with multiple skills...\n";

# Add skills using the skills system
eval {
    $agent->add_skill('datetime');
    print "Added datetime skill\n";
};
print "Failed to add datetime skill: $@\n" if $@;

eval {
    $agent->add_skill('math');
    print "Added math skill\n";
};
print "Failed to add math skill: $@\n" if $@;

eval {
    my $api_key   = $ENV{GOOGLE_SEARCH_API_KEY};
    my $engine_id = $ENV{GOOGLE_SEARCH_ENGINE_ID};

    die "Missing GOOGLE_SEARCH_API_KEY or GOOGLE_SEARCH_ENGINE_ID\n"
        unless $api_key && $engine_id;

    $agent->add_skill('web_search', {
        api_key          => $api_key,
        search_engine_id => $engine_id,
        num_results      => 1,
        delay            => 0,
    });
    print "Added web_search skill\n";
};
print "Web search not available: $@\n" if $@;

# List loaded skills
my $loaded = $agent->list_skills;
print "\nLoaded skills: " . join(', ', @$loaded) . "\n" if $loaded && @$loaded;

print "\nStarting Skills Demo Agent\n";
print "Available at: http://localhost:3000/assistant\n";

$agent->run;
