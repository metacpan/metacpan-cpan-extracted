#!/usr/bin/env perl
# InfoGatherer Prefab Example
#
# Demonstrates using the InfoGatherer prefab agent to collect structured
# information from callers via a guided question flow.

use strict;
use warnings;
use lib 'lib';
use SignalWire::Agents;
use SignalWire::Agents::Prefabs::InfoGatherer;

my $agent = SignalWire::Agents::Prefabs::InfoGatherer->new(
    name  => 'registration',
    route => '/register',
    questions => [
        { question_text => 'What is your full name?',     field => 'full_name' },
        { question_text => 'What is your email address?', field => 'email' },
        { question_text => 'What is your phone number?',  field => 'phone' },
    ],
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

# Post-prompt for structured output
$agent->set_post_prompt(<<'POST');
Return a JSON object with all collected information:
{
    "full_name": "NAME",
    "email": "EMAIL",
    "phone": "PHONE",
    "completed": true/false
}
POST

$agent->on_summary(sub {
    my ($summary, $raw) = @_;
    if ($summary) {
        require JSON;
        print "Registration completed:\n";
        if (ref $summary) {
            print JSON::encode_json($summary) . "\n";
        } else {
            print "$summary\n";
        }
    }
});

print "Starting InfoGatherer Agent\n";
print "Available at: http://localhost:3000/register\n";
print "This agent will collect: name, email, phone\n\n";

$agent->run;
