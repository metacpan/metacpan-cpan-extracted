#!/usr/bin/env perl
# DataSphere Multiple Instance Demo
#
# Demonstrates the DataSphere skill with multiple instance support.
# You can load the same skill multiple times with different configurations
# and tool names.
#
# Features:
# - Multiple instances of the same skill
# - Custom tool names per instance
# - Different configurations per instance
# - Custom no_results_message per instance
#
# Prerequisites:
#   Valid space_name, project_id, token, and document_id values

use strict;
use warnings;
use lib 'lib';
use SignalWire;
use SignalWire::Agent::AgentBase;

my $agent = SignalWire::Agent::AgentBase->new(
    name  => 'Multi-DataSphere Assistant',
    route => '/datasphere-demo',
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

print "Creating agent with multiple DataSphere skill instances...\n";

# Add basic skills
eval { $agent->add_skill('datetime'); print "Added datetime skill\n" };
print "Failed to add datetime: $@\n" if $@;

eval { $agent->add_skill('math'); print "Added math skill\n" };
print "Failed to add math: $@\n" if $@;

# Example config (replace with real DataSphere credentials)
my %base_config = (
    space_name => 'your-space',
    project_id => 'your-project-id',
    token      => 'your-token',
);

# Instance 1: Drinks knowledge base
eval {
    $agent->add_skill('datasphere', {
        %base_config,
        document_id        => 'drinks-doc-123',
        tool_name          => 'search_drinks_knowledge',
        tags               => ['Drinks', 'Bar', 'Cocktails'],
        count              => 2,
        distance           => 5.0,
        no_results_message => "I couldn't find any drink recipes about '{query}'. Try a different cocktail.",
    });
    print "Added drinks knowledge search (tool: search_drinks_knowledge)\n";
};
print "Failed to add drinks DataSphere: $@\n" if $@;

# Instance 2: Food knowledge base
eval {
    $agent->add_skill('datasphere', {
        %base_config,
        document_id        => 'food-doc-456',
        tool_name          => 'search_food_knowledge',
        tags               => ['Food', 'Recipes', 'Cooking'],
        count              => 3,
        distance           => 4.0,
        no_results_message => "I couldn't find cooking information about '{query}'. Try a different dish.",
    });
    print "Added food knowledge search (tool: search_food_knowledge)\n";
};
print "Failed to add food DataSphere: $@\n" if $@;

# Instance 3: General knowledge (default tool name)
eval {
    $agent->add_skill('datasphere', {
        %base_config,
        document_id        => 'general-doc-789',
        count              => 1,
        distance           => 3.0,
        no_results_message => "I couldn't find information about '{query}'. Please try rephrasing.",
    });
    print "Added general knowledge search (tool: search_knowledge - default)\n";
};
print "Failed to add general DataSphere: $@\n" if $@;

my $loaded = $agent->list_skills;
print "\nLoaded skill instances: " . join(', ', @$loaded) . "\n" if $loaded && @$loaded;

print "\nAgent available at: http://localhost:3000/datasphere-demo\n";
print "Note: Replace example credentials with your actual DataSphere details\n\n";

$agent->run;
