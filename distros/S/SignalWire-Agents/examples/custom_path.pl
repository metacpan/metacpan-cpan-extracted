#!/usr/bin/env perl
# Custom Path Agent Example
#
# Demonstrates how to create an agent with a custom route/path.
# Instead of the default "/" route, this agent is available at "/chat".
#
# Useful for:
# - Running multiple agents on the same server at different paths
# - Creating semantic URLs that describe the agent's purpose
# - Organizing agents by department or function
#
# Usage:
#   curl "http://localhost:3000/chat"
#   curl "http://localhost:3000/chat?user_name=Alice&topic=AI&mood=casual"

use strict;
use warnings;
use lib 'lib';
use SignalWire::Agents;
use SignalWire::Agents::Agent::AgentBase;

my $agent = SignalWire::Agents::Agent::AgentBase->new(
    name        => 'Chat Assistant',
    route       => '/chat',
    auto_answer => 1,
    record_call => 1,
);

# Base prompt
$agent->prompt_add_section(
    'Role',
    'You are a friendly chat assistant ready to help with any questions or conversations.',
);

# Dynamic configuration based on query parameters
$agent->set_dynamic_config_callback(sub {
    my ($qp, $bp, $headers, $a) = @_;

    my $user_name = $qp->{user_name} // 'friend';
    my $topic     = $qp->{topic}     // 'general conversation';
    my $mood      = lc($qp->{mood}   // 'friendly');

    # Personalize the greeting
    $a->prompt_add_section(
        'Personalization',
        "The user's name is $user_name. They're interested in discussing $topic.",
    );

    # Voice setup
    $a->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
    $a->set_params({ ai_model => 'gpt-4.1-nano' });

    # Mood-based communication style
    if ($mood eq 'professional') {
        $a->prompt_add_section('Communication Style',
            'Maintain a professional, business-appropriate tone in all interactions.',
        );
    } elsif ($mood eq 'casual') {
        $a->prompt_add_section('Communication Style',
            'Use a casual, relaxed conversational style. Feel free to use informal language.',
        );
    } else {
        $a->prompt_add_section('Communication Style',
            'Be warm, friendly, and approachable in your responses.',
        );
    }

    $a->set_global_data({
        user_name    => $user_name,
        topic        => $topic,
        mood         => $mood,
        session_type => 'chat',
    });

    $a->add_hints('chat', 'assistant', 'help', 'conversation', 'question');
});

print "Starting Chat Agent at custom path /chat\n";
print "Available at: http://localhost:3000/chat\n";
print "\nTry:\n";
print "  curl 'http://localhost:3000/chat?user_name=Alice&topic=AI&mood=casual'\n\n";

$agent->run;
