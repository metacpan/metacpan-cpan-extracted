#!/usr/bin/env perl
# Comprehensive Dynamic Agent Configuration Example
#
# Demonstrates advanced per-request dynamic configuration:
# - Dynamic voice and language selection
# - Tier-based feature settings (standard/premium/enterprise)
# - Industry-specific prompt customization
# - A/B testing configuration
# - Multi-tenant global data
#
# Usage:
#   curl "http://localhost:3000/dynamic?tier=premium&industry=healthcare"
#   curl "http://localhost:3000/dynamic?tier=enterprise&industry=retail&language=es"

use strict;
use warnings;
use lib 'lib';
use SignalWire::Agents;
use SignalWire::Agents::Agent::AgentBase;

my $agent = SignalWire::Agents::Agent::AgentBase->new(
    name        => 'Comprehensive Dynamic Agent',
    route       => '/dynamic',
    auto_answer => 1,
    record_call => 1,
);

# Industry-specific configs
my %industry_configs = (
    healthcare => { compliance_level => 'high',     response_style => 'professional' },
    finance    => { compliance_level => 'high',     response_style => 'formal' },
    retail     => { compliance_level => 'medium',   response_style => 'friendly' },
    general    => { compliance_level => 'standard', response_style => 'conversational' },
);

$agent->set_dynamic_config_callback(sub {
    my ($qp, $bp, $headers, $a) = @_;

    my $tier       = lc($qp->{tier}       // 'standard');
    my $industry   = lc($qp->{industry}   // 'general');
    my $language   = lc($qp->{language}   // 'en');
    my $test_group = uc($qp->{test_group} // 'A');
    my $debug_mode = lc($qp->{debug}      // '') eq 'true';

    # --- Voice & Language ---
    if ($language eq 'es') {
        $a->add_language(name => 'Spanish', code => 'es-ES', voice => 'inworld.Sarah');
    } elsif ($language eq 'fr') {
        $a->add_language(name => 'French',  code => 'fr-FR', voice => 'inworld.Hanna');
    } else {
        my $voice = ($tier eq 'premium' || $tier eq 'enterprise')
            ? 'inworld.Sarah' : 'inworld.Mark';
        $a->add_language(name => 'English', code => 'en-US', voice => $voice);
    }

    # --- Tier-based parameters ---
    my %params = (ai_model => 'gpt-4.1-nano');
    if ($tier eq 'enterprise') {
        %params = (%params,
            end_of_speech_timeout  => 800,
            attention_timeout      => 25000,
            background_file_volume => -35,
        );
    } elsif ($tier eq 'premium') {
        %params = (%params,
            end_of_speech_timeout  => 600,
            attention_timeout      => 20000,
            background_file_volume => -30,
        );
    } else {
        %params = (%params,
            end_of_speech_timeout  => 400,
            attention_timeout      => 15000,
            background_file_volume => -20,
        );
    }
    # A/B variation
    if ($test_group eq 'B') {
        $params{end_of_speech_timeout} = int($params{end_of_speech_timeout} * 1.2);
    }
    $a->set_params(\%params);

    # --- Industry-specific prompts ---
    my $config = $industry_configs{$industry} // $industry_configs{general};
    $a->prompt_add_section(
        'Role and Purpose',
        "You are a professional AI assistant specialized in $industry services. "
        . "Maintain $config->{response_style} communication standards.",
    );

    if ($industry eq 'healthcare') {
        $a->prompt_add_section('Healthcare Guidelines',
            'Follow HIPAA compliance standards.',
            bullets => [
                'Protect patient privacy at all times',
                'Direct medical questions to qualified providers',
                'Use appropriate medical terminology',
            ],
        );
    } elsif ($industry eq 'finance') {
        $a->prompt_add_section('Financial Guidelines',
            'Adhere to financial industry regulations.',
            bullets => [
                'Never provide specific investment advice',
                'Protect sensitive financial information',
                'Refer complex matters to qualified advisors',
            ],
        );
    } elsif ($industry eq 'retail') {
        $a->prompt_add_section('Customer Service Excellence',
            'Focus on customer satisfaction and sales support.',
            bullets => [
                'Maintain friendly, helpful demeanor',
                'Handle complaints with empathy',
                'Enhance the shopping experience',
            ],
        );
    }

    # Enhanced capabilities for higher tiers
    if ($tier eq 'premium' || $tier eq 'enterprise') {
        $a->prompt_add_section('Enhanced Capabilities',
            "As a $tier service, you have access to advanced features:",
            bullets => [
                'Extended conversation memory',
                'Priority processing and faster responses',
                'Access to specialized knowledge bases',
            ],
        );
    }

    # --- Global data ---
    my @features = ('basic_conversation', 'function_calling');
    push @features, 'extended_memory', 'priority_processing'
        if $tier eq 'premium' || $tier eq 'enterprise';
    push @features, 'custom_integration', 'dedicated_support'
        if $tier eq 'enterprise';

    $a->set_global_data({
        service_tier     => $tier,
        industry_focus   => $industry,
        test_group       => $test_group,
        features_enabled => \@features,
        compliance_level => $config->{compliance_level},
        ($debug_mode ? (debug_mode => JSON::true) : ()),
    });

    # --- A/B testing ---
    if ($test_group eq 'B') {
        $a->add_hints('enhanced', 'personalized', 'proactive');
        $a->prompt_add_section('Enhanced Interaction Style',
            'Use an enhanced conversation style for this session:',
            bullets => [
                'Ask clarifying questions more frequently',
                'Provide more detailed explanations',
                'Offer proactive suggestions when appropriate',
            ],
        );
    }

    # --- Debug features ---
    if ($debug_mode) {
        $a->prompt_add_section('Debug Mode',
            'Debug mode is enabled. Provide additional context and reasoning.',
            bullets => [
                'Show decision-making process when appropriate',
                'Explain feature availability based on tier',
            ],
        );
    }
});

print "Starting Comprehensive Dynamic Agent\n";
print "Available at: http://localhost:3000/dynamic\n";
print "\nExample requests:\n";
print "  curl 'http://localhost:3000/dynamic?tier=premium&industry=healthcare'\n";
print "  curl 'http://localhost:3000/dynamic?tier=enterprise&industry=retail&language=es'\n";
print "  curl 'http://localhost:3000/dynamic?tier=standard&test_group=B&debug=true'\n\n";

$agent->run;
