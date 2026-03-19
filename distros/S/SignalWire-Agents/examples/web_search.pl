#!/usr/bin/env perl
# Web Search Agent Example
#
# Demonstrates an AI agent that can search the web for information using
# the web_search skill from the skills system.
#
# Required Environment Variables:
#   GOOGLE_SEARCH_API_KEY     - Google Custom Search API key
#   GOOGLE_SEARCH_ENGINE_ID   - Google Custom Search Engine ID
#
# Get credentials at:
#   https://developers.google.com/custom-search/v1/introduction

use strict;
use warnings;
use lib 'lib';
use SignalWire::Agents;
use SignalWire::Agents::Agent::AgentBase;

my $agent = SignalWire::Agents::Agent::AgentBase->new(
    name  => 'Web Search Assistant',
    route => '/search',
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

$agent->prompt_add_section(
    'Personality',
    'You are Franklin, a friendly and knowledgeable search bot. '
    . "You're enthusiastic about helping people find information on the internet.",
);

$agent->prompt_add_section(
    'Goal',
    'Help users find accurate, up-to-date information from the web.',
);

$agent->prompt_add_section('Instructions', '',
    bullets => [
        'Always introduce yourself as Franklin when users first interact',
        'Use your web search capabilities to find current information',
        'Present search results in a well-organized format',
        'Be enthusiastic about searching and learning',
    ],
);

# Add web search skill
eval {
    my $api_key   = $ENV{GOOGLE_SEARCH_API_KEY};
    my $engine_id = $ENV{GOOGLE_SEARCH_ENGINE_ID};

    die "Missing GOOGLE_SEARCH_API_KEY or GOOGLE_SEARCH_ENGINE_ID\n"
        unless $api_key && $engine_id;

    $agent->add_skill('web_search', {
        api_key            => $api_key,
        search_engine_id   => $engine_id,
        num_results        => 1,
        delay              => 0,
        max_content_length => 3000,
        no_results_message => "I couldn't find any information about '{query}'. Try rephrasing your question.",
    });
    print "Web search skill loaded successfully\n";
};
if ($@) {
    print "Web search not available: $@\n";
    print "Set GOOGLE_SEARCH_API_KEY and GOOGLE_SEARCH_ENGINE_ID\n";
    exit 1;
}

my $loaded = $agent->list_skills;
print "Loaded skills: " . join(', ', @$loaded) . "\n" if $loaded && @$loaded;

print "\nStarting Web Search Agent\n";
print "Available at: http://localhost:3000/search\n\n";

$agent->run;
