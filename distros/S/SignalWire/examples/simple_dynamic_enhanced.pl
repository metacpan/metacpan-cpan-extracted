#!/usr/bin/env perl
# Enhanced Dynamic Agent
#
# Adapts based on request parameters:
# - vip=true/false (premium voice, faster response)
# - department=sales/support/billing (specialized expertise)
# - customer_id=<string> (personalized experience)
# - language=en/es (language and voice selection)
#
# Test:
#   curl "http://localhost:3000/?vip=true&department=sales"
#   curl "http://localhost:3000/?department=billing&language=es"

use strict;
use warnings;
use lib 'lib';
use SignalWire;
use SignalWire::Agent::AgentBase;

my $agent = SignalWire::Agent::AgentBase->new(
    name        => 'Enhanced Dynamic Agent',
    auto_answer => 1,
    record_call => 1,
);

$agent->set_dynamic_config_callback(sub {
    my ($query_params, $body_params, $headers, $clone) = @_;

    my $is_vip      = lc($query_params->{vip} // '') eq 'true';
    my $department   = lc($query_params->{department} // 'general');
    my $customer_id  = $query_params->{customer_id} // '';
    my $language     = lc($query_params->{language} // 'en');

    # Voice and language
    my $voice = $is_vip ? 'inworld.Sarah' : 'inworld.Mark';
    if ($language eq 'es') {
        $clone->add_language(name => 'Spanish', code => 'es-ES', voice => $voice);
    } else {
        $clone->add_language(name => 'English', code => 'en-US', voice => $voice);
    }

    # AI parameters
    $clone->set_params({
        ai_model              => 'gpt-4.1-nano',
        end_of_speech_timeout => $is_vip ? 300 : 500,
        attention_timeout     => $is_vip ? 20000 : 15000,
    });

    # Hints
    my @hints = ('SignalWire', 'SWML', 'API', 'webhook', 'SIP');
    if ($department eq 'sales') {
        push @hints, qw(pricing enterprise upgrade);
    } elsif ($department eq 'billing') {
        push @hints, qw(invoice payment charges);
    } else {
        push @hints, qw(support troubleshoot help);
    }
    $clone->add_hints(@hints);

    # Global data
    my %global = (
        department    => $department,
        service_level => $is_vip ? 'vip' : 'standard',
    );
    $global{customer_id} = $customer_id if $customer_id;
    $clone->set_global_data(\%global);

    # Role prompt
    my $role = $customer_id
        ? "You are a customer service rep helping customer $customer_id."
        : 'You are a professional customer service representative.';
    $role .= ' This is a VIP customer who receives priority service.' if $is_vip;
    $clone->prompt_add_section('Role and Purpose', $role);

    # Department expertise
    if ($department eq 'sales') {
        $clone->prompt_add_section('Sales Expertise', 'You specialize in sales:',
            bullets => [
                'Present product features and benefits',
                'Handle pricing questions',
                'Process orders and upgrades',
            ]);
    } elsif ($department eq 'billing') {
        $clone->prompt_add_section('Billing Expertise', 'You specialize in billing:',
            bullets => [
                'Explain statements and charges',
                'Process payment arrangements',
                'Handle dispute resolution',
            ]);
    } else {
        $clone->prompt_add_section('Support Guidelines', 'Follow these principles:',
            bullets => [
                'Listen carefully to customer needs',
                'Provide accurate information',
                'Escalate complex issues when appropriate',
            ]);
    }

    # VIP service standards
    if ($is_vip) {
        $clone->prompt_add_section('VIP Standards', 'Premium service:',
            bullets => [
                'Provide immediate attention',
                'Offer exclusive options',
                'Ensure complete satisfaction',
            ]);
    }
});

print "Starting Enhanced Dynamic Agent\n";
print "  ?vip=true          Premium voice + faster response\n";
print "  ?department=sales  Sales expertise\n";
print "  ?customer_id=X     Personalized experience\n";
print "  ?language=es       Spanish\n\n";

$agent->run;
