#!/usr/bin/env perl
# Survey Prefab Example
#
# Demonstrates using the Survey prefab agent to conduct a structured
# survey with multiple question types and validation.

use strict;
use warnings;
use lib 'lib';
use SignalWire::Agents;
use SignalWire::Agents::Prefabs::Survey;

my $agent = SignalWire::Agents::Prefabs::Survey->new(
    name        => 'customer-satisfaction',
    route       => '/survey',
    survey_name => 'Customer Satisfaction Survey',
    brand_name  => 'Acme Corp',
    introduction => 'Thank you for choosing Acme Corp! We would love your feedback.',
    conclusion   => 'Thank you for completing our survey. Your feedback helps us improve!',
    survey_questions => [
        {
            id       => 'satisfaction',
            text     => 'On a scale of 1-5, how satisfied are you with our service?',
            type     => 'rating',
            required => 1,
        },
        {
            id       => 'recommend',
            text     => 'Would you recommend us to a friend? Yes or no.',
            type     => 'yes_no',
            required => 1,
        },
        {
            id       => 'feedback',
            text     => 'Do you have any additional comments or suggestions?',
            type     => 'open_ended',
            required => 0,
        },
    ],
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

$agent->set_post_prompt(<<'POST');
Return a JSON summary of the survey responses:
{
    "satisfaction_rating": NUMBER,
    "would_recommend": true/false,
    "comments": "TEXT_OR_NONE",
    "survey_completed": true/false
}
POST

$agent->on_summary(sub {
    my ($summary, $raw) = @_;
    if ($summary) {
        require JSON;
        print "Survey results:\n";
        if (ref $summary) {
            print JSON::encode_json($summary) . "\n";
        } else {
            print "$summary\n";
        }
    }
});

print "Starting Customer Satisfaction Survey\n";
print "Available at: http://localhost:3000/survey\n";
print "Questions: satisfaction rating, recommendation, open feedback\n\n";

$agent->run;
