#!/usr/bin/env perl
# Dynamic InfoGatherer Example
#
# InfoGathererAgent with a callback that selects questions based on
# request parameters (?set=support, ?set=medical, ?set=onboarding).

use strict;
use warnings;
use lib 'lib';
use SignalWire;
use SignalWire::Prefabs::InfoGatherer;

my %question_sets = (
    default => [
        { key_name => 'name',   question_text => 'What is your full name?' },
        { key_name => 'phone',  question_text => 'What is your phone number?', confirm => 1 },
        { key_name => 'reason', question_text => 'How can I help you today?' },
    ],
    support => [
        { key_name => 'customer_name',  question_text => 'What is your name?' },
        { key_name => 'account_number', question_text => 'What is your account number?', confirm => 1 },
        { key_name => 'issue',          question_text => 'What issue are you experiencing?' },
        { key_name => 'priority',       question_text => 'How urgent is this? (Low, Medium, High)' },
    ],
    medical => [
        { key_name => 'patient_name', question_text => "What is the patient's full name?" },
        { key_name => 'symptoms',     question_text => 'What symptoms are you experiencing?', confirm => 1 },
        { key_name => 'duration',     question_text => 'How long have you had these symptoms?' },
        { key_name => 'medications',  question_text => 'Are you currently taking any medications?' },
    ],
    onboarding => [
        { key_name => 'full_name',   question_text => 'What is your full name?' },
        { key_name => 'email',       question_text => 'What is your email address?', confirm => 1 },
        { key_name => 'company',     question_text => 'What company do you work for?' },
        { key_name => 'department',  question_text => 'What department will you be working in?' },
        { key_name => 'start_date',  question_text => 'What is your start date?' },
    ],
);

my $agent = SignalWire::Prefabs::InfoGatherer->new(
    questions => undef,    # dynamic mode
    name      => 'dynamic-intake',
    route     => '/contact',
);

$agent->set_question_callback(sub {
    my ($query_params, $body_params, $headers) = @_;
    my $set = $query_params->{set} // 'default';
    print "Dynamic question set: $set\n";
    return $question_sets{$set} // $question_sets{default};
});

print "Starting Dynamic InfoGatherer\n";
print "  /contact            (default: name, phone, reason)\n";
print "  /contact?set=support (customer support)\n";
print "  /contact?set=medical (medical intake)\n";
print "  /contact?set=onboarding (employee onboarding)\n\n";

$agent->run;
