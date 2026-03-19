#!/usr/bin/env perl
# Multi-Agent Server Example
#
# Demonstrates running multiple agents on the same server, each with
# different paths and configurations.
#
# Available Agents:
#   /healthcare - Healthcare-focused agent with HIPAA compliance
#   /finance    - Finance-focused agent with regulatory compliance
#   /retail     - Retail/customer service agent with sales focus

use strict;
use warnings;
use lib 'lib';
use SignalWire::Agents;
use SignalWire::Agents::Agent::AgentBase;
use SignalWire::Agents::Server::AgentServer;

# --- Healthcare Agent ---

my $healthcare = SignalWire::Agents::Agent::AgentBase->new(
    name        => 'Healthcare AI Assistant',
    route       => '/healthcare',
    auto_answer => 1,
    record_call => 1,
);

$healthcare->prompt_add_section(
    'Healthcare Role',
    'You are a HIPAA-compliant healthcare AI assistant. You help patients and '
    . 'healthcare providers with information, scheduling, and basic guidance.',
);
$healthcare->prompt_add_section(
    'Compliance Guidelines',
    'Always maintain patient privacy and confidentiality:',
    bullets => [
        'Never share patient information with unauthorized parties',
        'Direct medical diagnoses to qualified healthcare providers',
        'Use appropriate medical terminology',
        'Maintain professional, caring communication',
    ],
);

$healthcare->set_dynamic_config_callback(sub {
    my ($qp, $bp, $headers, $a) = @_;
    my $urgency = lc($qp->{urgency} // 'normal');

    if ($urgency eq 'high') {
        $a->add_language(name => 'English', code => 'en-US', voice => 'inworld.Sarah');
        $a->set_params({ ai_model => 'gpt-4.1-nano', end_of_speech_timeout => 300 });
    } else {
        $a->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
        $a->set_params({ ai_model => 'gpt-4.1-nano', end_of_speech_timeout => 500 });
    }

    $a->set_global_data({
        customer_id      => $qp->{customer_id} // '',
        urgency_level    => $urgency,
        department       => $qp->{department} // 'general',
        compliance_level => 'hipaa',
        session_type     => 'healthcare',
    });
});

# --- Finance Agent ---

my $finance = SignalWire::Agents::Agent::AgentBase->new(
    name        => 'Financial Services AI',
    route       => '/finance',
    auto_answer => 1,
    record_call => 1,
);

$finance->prompt_add_section(
    'Financial Services Role',
    'You are a financial services AI assistant specializing in banking, '
    . 'investments, and financial planning guidance.',
);
$finance->prompt_add_section(
    'Regulatory Compliance',
    'Adhere to financial industry regulations:',
    bullets => [
        'Protect sensitive financial information',
        'Never provide specific investment advice without disclaimers',
        'Refer complex matters to licensed financial advisors',
        'Maintain accurate, professional communication',
    ],
);

$finance->set_dynamic_config_callback(sub {
    my ($qp, $bp, $headers, $a) = @_;
    my $account_type = lc($qp->{account_type} // 'standard');

    if ($account_type eq 'premium') {
        $a->add_language(name => 'English', code => 'en-US', voice => 'inworld.Sarah');
        $a->set_params({ ai_model => 'gpt-4.1-nano', end_of_speech_timeout => 600 });
    } else {
        $a->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
        $a->set_params({ ai_model => 'gpt-4.1-nano', end_of_speech_timeout => 400 });
    }

    $a->set_global_data({
        customer_id      => $qp->{customer_id} // '',
        account_type     => $account_type,
        service_area     => $qp->{service} // 'general',
        compliance_level => 'financial',
        session_type     => 'finance',
    });
});

# --- Retail Agent ---

my $retail = SignalWire::Agents::Agent::AgentBase->new(
    name        => 'Retail Customer Service AI',
    route       => '/retail',
    auto_answer => 1,
    record_call => 1,
);

$retail->prompt_add_section(
    'Customer Service Role',
    'You are a friendly retail customer service AI assistant focused on '
    . 'providing excellent customer experiences and sales support.',
);
$retail->prompt_add_section(
    'Service Excellence',
    'Customer service principles:',
    bullets => [
        'Maintain friendly, helpful demeanor',
        'Listen actively to customer needs',
        'Provide accurate product information',
        'Look for opportunities to enhance the shopping experience',
    ],
);

$retail->set_dynamic_config_callback(sub {
    my ($qp, $bp, $headers, $a) = @_;
    my $tier = lc($qp->{customer_tier} // 'standard');

    if ($tier eq 'vip') {
        $a->add_language(name => 'English', code => 'en-US', voice => 'inworld.Sarah');
        $a->set_params({ ai_model => 'gpt-4.1-nano', end_of_speech_timeout => 600 });
    } else {
        $a->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
        $a->set_params({ ai_model => 'gpt-4.1-nano', end_of_speech_timeout => 400 });
    }

    $a->set_global_data({
        customer_id   => $qp->{customer_id} // '',
        department    => $qp->{department} // 'general',
        customer_tier => $tier,
        session_type  => 'retail',
    });
});

# --- Server Setup ---

my $server = SignalWire::Agents::Server::AgentServer->new(
    host => '0.0.0.0',
    port => 3000,
);

$server->register($healthcare);
$server->register($finance);
$server->register($retail);

print "Starting Multi-Agent AI Server\n\n";
print "Available agents:\n";
print "- http://localhost:3000/healthcare - Healthcare AI (HIPAA compliant)\n";
print "- http://localhost:3000/finance    - Financial Services AI\n";
print "- http://localhost:3000/retail     - Retail Customer Service AI\n";
print "\nExample requests:\n";
print "curl 'http://localhost:3000/healthcare?customer_id=patient123&urgency=high'\n";
print "curl 'http://localhost:3000/finance?account_type=premium&service=investment'\n";
print "curl 'http://localhost:3000/retail?department=electronics&customer_tier=vip'\n\n";

$server->run;
