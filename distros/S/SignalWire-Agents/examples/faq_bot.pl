#!/usr/bin/env perl
# FAQ Bot Agent Example
#
# Demonstrates the FAQBot prefab for answering frequently asked questions
# from a predefined knowledge base. Shows structured knowledge in the prompt,
# custom persona, and conversation summary processing.

use strict;
use warnings;
use lib 'lib';
use JSON qw(encode_json);
use SignalWire::Agents;
use SignalWire::Agents::Prefabs::FAQBot;

my $agent = SignalWire::Agents::Prefabs::FAQBot->new(
    name    => 'signalwire_faq',
    route   => '/faq',
    persona => 'You are a helpful FAQ assistant for SignalWire.',
    faqs    => [
        {
            question => 'What is SignalWire?',
            answer   => 'SignalWire is a communications platform that provides APIs for voice, video, and messaging.',
        },
        {
            question => 'How do I create an AI Agent?',
            answer   => 'You can create an AI Agent using the SignalWire AI Agent SDK, which provides a simple way to build and deploy conversational AI agents.',
        },
        {
            question => 'What is SWML?',
            answer   => 'SWML (SignalWire Markup Language) is a markup language for defining communications workflows, including AI interactions.',
        },
        {
            question => 'What are your hours?',
            answer   => 'We are open Monday through Friday, 9am to 5pm.',
        },
        {
            question => 'Do you offer refunds?',
            answer   => "Yes, we offer refunds within 30 days of purchase if you're not satisfied.",
        },
    ],
    suggest_related => 1,
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

# Post-prompt for structured summary
$agent->set_post_prompt(<<'POST');
Provide a JSON summary of the interaction:
{
    "question_type": "CATEGORY_OF_QUESTION",
    "answered_from_kb": true/false,
    "follow_up_needed": true/false
}
POST

$agent->on_summary(sub {
    my ($summary, $raw) = @_;
    if ($summary) {
        print "FAQ Bot conversation summary: " . encode_json($summary) . "\n";
    }
});

print "Starting FAQ Bot Agent\n";
print "Available at: http://localhost:3000/faq\n";

$agent->run;
