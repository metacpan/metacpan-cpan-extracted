#!/usr/bin/env perl
# DataSphere Multiple Instance Demo
#
# Loads the datasphere skill multiple times with different knowledge bases
# and custom tool names for separate search tools.

use strict;
use warnings;
use lib 'lib';
use SignalWire;
use SignalWire::Agent::AgentBase;

my $agent = SignalWire::Agent::AgentBase->new(
    name  => 'Multi-DataSphere',
    route => '/datasphere-multi',
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

$agent->prompt_add_section('Role',
    'You are an assistant with access to multiple knowledge bases. '
    . 'Use the appropriate search tool depending on the topic.');

eval { $agent->add_skill('datetime') };
eval { $agent->add_skill('math') };

my %base = (
    space_name => 'your-space',
    project_id => 'your-project-id',
    token      => 'your-token',
);

# Instance 1: Drinks
eval {
    $agent->add_skill('datasphere', {
        %base,
        document_id => 'drinks-doc-123',
        tool_name   => 'search_drinks_knowledge',
        count       => 2,
        distance    => 5.0,
    });
    print "Added drinks knowledge (tool: search_drinks_knowledge)\n";
};
print "Drinks DataSphere: $@\n" if $@;

# Instance 2: Food
eval {
    $agent->add_skill('datasphere', {
        %base,
        document_id => 'food-doc-456',
        tool_name   => 'search_food_knowledge',
        count       => 3,
        distance    => 4.0,
    });
    print "Added food knowledge (tool: search_food_knowledge)\n";
};
print "Food DataSphere: $@\n" if $@;

# Instance 3: General (default tool name)
eval {
    $agent->add_skill('datasphere', {
        %base,
        document_id => 'general-doc-789',
        count       => 1,
        distance    => 3.0,
    });
    print "Added general knowledge (tool: search_knowledge)\n";
};
print "General DataSphere: $@\n" if $@;

print "\nTools: search_drinks_knowledge, search_food_knowledge, search_knowledge\n";
print "Note: Replace credentials with your actual DataSphere details.\n\n";

$agent->run;
