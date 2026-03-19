#!/usr/bin/env perl
# Wikipedia Search Skill Demo
#
# Demonstrates the Wikipedia search skill for factual information retrieval.
# Features:
# - Wikipedia article search and summaries
# - Custom no_results_message with query placeholder
# - Multiple result configuration
# - Combined with datetime skill

use strict;
use warnings;
use lib 'lib';
use SignalWire::Agents;
use SignalWire::Agents::Agent::AgentBase;

my $agent = SignalWire::Agents::Agent::AgentBase->new(
    name  => 'Wikipedia Assistant',
    route => '/wiki-demo',
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

print "Creating Wikipedia search assistant...\n";

# Add datetime skill
eval {
    $agent->add_skill('datetime');
    print "Added datetime skill\n";
};
print "Failed to add datetime skill: $@\n" if $@;

# Add Wikipedia search skill
eval {
    $agent->add_skill('wikipedia_search', {
        num_results        => 2,
        no_results_message => "I couldn't find any Wikipedia articles about '{query}'. "
            . 'You might want to try different keywords or ask about a related topic.',
    });
    print "Added Wikipedia search (tool: search_wiki)\n";
};
if ($@) {
    print "Failed to add Wikipedia skill: $@\n";
    exit 1;
}

my $loaded = $agent->list_skills;
print "Loaded skills: " . join(', ', @$loaded) . "\n" if $loaded && @$loaded;

print "\nWikipedia Assistant available at: http://localhost:3000/wiki-demo\n";
print "Example queries:\n";
print "  'Tell me about Albert Einstein'\n";
print "  'What is quantum physics?'\n";
print "  'Look up Python programming language'\n\n";

$agent->run;
