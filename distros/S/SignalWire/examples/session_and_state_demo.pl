#!/usr/bin/env perl
# Session and State Demo
#
# Demonstrates session lifecycle management:
# - on_summary hook for processing conversation summaries
# - set_global_data for providing context to the AI
# - update_global_data for modifying state during a call
# - Tool result actions (hangup, set_global_data, etc.)

use strict;
use warnings;
use lib 'lib';
use SignalWire;
use SignalWire::Agent::AgentBase;
use SignalWire::SWAIG::FunctionResult;
use JSON qw(encode_json);

my $agent = SignalWire::Agent::AgentBase->new(
    name  => 'session-state-demo',
    route => '/session-state',
);

# Configure prompt
$agent->prompt_add_section(
    'Role',
    'You are a customer service agent that tracks session state.',
    bullets => [
        'Use check_account to look up customer info',
        'Use update_preferences to modify customer preferences',
        'Use end_call to hang up when the customer is done',
    ],
);

# Initial global data for every session
$agent->set_global_data({
    company     => 'Acme Corp',
    department  => 'customer_service',
    call_reason => 'unknown',
});

# Post-prompt for summary
$agent->set_post_prompt(<<'POST');
Summarize the conversation as JSON:
{
    "customer_name": "NAME_OR_UNKNOWN",
    "call_reason": "REASON",
    "resolved": true/false,
    "actions_taken": ["action1", "action2"]
}
POST

# Summary callback
$agent->on_summary(sub {
    my ($summary, $raw) = @_;
    if ($summary) {
        print "CONVERSATION SUMMARY:\n";
        if (ref $summary) {
            print encode_json($summary) . "\n";
        } else {
            print "$summary\n";
        }
    }
});

# --- Tool: check_account ---
$agent->define_tool(
    name        => 'check_account',
    description => 'Look up a customer account by name or ID',
    parameters  => {
        type       => 'object',
        properties => {
            identifier => { type => 'string', description => 'Customer name or account ID' },
        },
        required => ['identifier'],
    },
    handler => sub {
        my ($args, $raw) = @_;
        my $id = $args->{identifier} // 'unknown';
        my $result = SignalWire::SWAIG::FunctionResult->new(
            "Found account for $id: Premium tier, active since 2020."
        );
        # Update global data so the AI knows the customer
        $result->update_global_data({
            customer_name => $id,
            account_tier  => 'premium',
            call_reason   => 'account_inquiry',
        });
        return $result;
    },
);

# --- Tool: update_preferences ---
$agent->define_tool(
    name        => 'update_preferences',
    description => 'Update customer communication preferences',
    parameters  => {
        type       => 'object',
        properties => {
            email_notifications => { type => 'boolean', description => 'Enable email notifications' },
            sms_notifications   => { type => 'boolean', description => 'Enable SMS notifications' },
        },
    },
    handler => sub {
        my ($args, $raw) = @_;
        my @prefs;
        push @prefs, 'email' if $args->{email_notifications};
        push @prefs, 'SMS'   if $args->{sms_notifications};
        my $pref_str = @prefs ? join(' and ', @prefs) : 'none';
        return SignalWire::SWAIG::FunctionResult->new(
            "Preferences updated: $pref_str notifications enabled."
        );
    },
);

# --- Tool: end_call ---
$agent->define_tool(
    name        => 'end_call',
    description => 'End the call after saying goodbye',
    parameters  => { type => 'object', properties => {} },
    handler     => sub {
        my ($args, $raw) = @_;
        my $result = SignalWire::SWAIG::FunctionResult->new(
            'Thank you for calling. Goodbye!'
        );
        $result->hangup;
        return $result;
    },
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

print "Starting Session State Demo\n";
print "Available at: http://localhost:3000/session-state\n";

$agent->run;
