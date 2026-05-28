#!/usr/bin/env perl
# Gather Info Mode Demo
#
# Demonstrates the contexts system's gather_info mode for structured data
# collection. Uses add_gather_question() to present questions one at a time.
# Answers are stored in global_data under the configured output key.
#
# This example models a patient intake workflow with three steps:
# 1. Demographics collection (gather mode)
# 2. Symptoms collection (gather mode)
# 3. Confirmation (normal conversational step)

use strict;
use warnings;
use lib 'lib';
use SignalWire;
use SignalWire::Agent::AgentBase;

my $agent = SignalWire::Agent::AgentBase->new(
    name  => 'Patient Intake Agent',
    route => '/patient-intake',
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

$agent->prompt_add_section(
    'Role',
    'You are a friendly medical office intake assistant. '
    . 'Collect patient information accurately and professionally.',
);

# Define a context with gather-info steps
my $ctx_builder = $agent->define_contexts;
my $ctx = $ctx_builder->add_context('default');

# Step 1: Gather patient demographics
my $step1 = $ctx->add_step('demographics');
$step1->set_text('Collect the patient\'s basic information.');
$step1->set_gather_info(
    output_key => 'patient_demographics',
    prompt     => 'Please collect the following patient information.',
);
$step1->add_gather_question('full_name',      'What is your full name?',     type => 'string');
$step1->add_gather_question('date_of_birth',  'What is your date of birth?', type => 'string');
$step1->add_gather_question('phone_number',   'What is your phone number?',  type => 'string', confirm => 1);
$step1->add_gather_question('email',          'What is your email address?', type => 'string');
$step1->set_valid_steps(['symptoms']);

# Step 2: Gather symptoms
my $step2 = $ctx->add_step('symptoms');
$step2->set_text('Ask about the patient\'s current symptoms and reason for visit.');
$step2->set_gather_info(
    output_key => 'patient_symptoms',
    prompt     => 'Now let\'s talk about why you\'re visiting today.',
);
$step2->add_gather_question('reason_for_visit',  'What is the main reason for your visit today?',  type => 'string');
$step2->add_gather_question('symptom_duration',  'How long have you been experiencing these symptoms?', type => 'string');
$step2->add_gather_question('pain_level',        'On a scale of 1 to 10, how would you rate your discomfort?', type => 'string');
$step2->set_valid_steps(['confirmation']);

# Step 3: Confirmation (normal conversational mode)
my $step3 = $ctx->add_step('confirmation');
$step3->set_text(
    'Summarize all the information collected and confirm with the patient '
    . 'that everything is correct. Thank them for their time.'
);
$step3->set_step_criteria('Patient has confirmed all information is correct');

print "Starting Patient Intake Agent (gather info mode)\n";
print "Available at: http://localhost:3000/patient-intake\n";
print "Steps: demographics -> symptoms -> confirmation\n\n";

$agent->run;
