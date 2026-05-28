#!/usr/bin/env perl
# Call Flow and Actions Demo
#
# Demonstrates call flow verbs (pre/post-answer), debug events, and
# SwaigFunctionResult actions (connect, SMS, record, hold, etc.).

use strict;
use warnings;
use lib 'lib';
use SignalWire;
use SignalWire::Agent::AgentBase;
use SignalWire::SWAIG::FunctionResult;

my $agent = SignalWire::Agent::AgentBase->new(
    name        => 'call-flow-demo',
    route       => '/call-flow',
    auto_answer => 1,
    record_call => 1,
);

# Configure prompt
$agent->prompt_add_section(
    'Role',
    'You are a call routing assistant that can transfer calls, send SMS, '
    . 'and manage call state.',
    bullets => [
        'Use transfer_call to connect callers to the right department',
        'Use send_notification to send an SMS to the caller',
        'Use put_on_hold to hold the caller while looking something up',
    ],
);

# Pre-answer verb: play hold music before the AI answers
$agent->add_pre_answer_verb('play', {
    url    => 'https://cdn.signalwire.com/default-music/welcome.mp3',
    volume => -5,
});

# Post-AI verb: play goodbye message after AI disconnects
$agent->add_post_ai_verb('play', {
    url => 'say:Thank you for calling. Goodbye.',
});

# Enable debug events
$agent->enable_debug_events(1);

# Debug event handler
$agent->on_debug_event(sub {
    my ($event) = @_;
    print "DEBUG EVENT: " . (ref $event ? JSON::encode_json($event) : $event) . "\n";
});

# --- Tool: transfer_call ---
$agent->define_tool(
    name        => 'transfer_call',
    description => 'Transfer the call to a phone number',
    parameters  => {
        type       => 'object',
        properties => {
            department => { type => 'string', description => 'Department name (sales, support, billing)' },
        },
        required => ['department'],
    },
    handler => sub {
        my ($args, $raw) = @_;
        my %numbers = (
            sales   => '+15551001001',
            support => '+15551002002',
            billing => '+15551003003',
        );
        my $dept = lc($args->{department} // 'support');
        my $num  = $numbers{$dept} // $numbers{support};

        my $result = SignalWire::SWAIG::FunctionResult->new(
            "Transferring you to $dept now."
        );
        $result->connect($num);
        return $result;
    },
);

# --- Tool: send_notification ---
$agent->define_tool(
    name        => 'send_notification',
    description => 'Send an SMS notification to the caller',
    parameters  => {
        type       => 'object',
        properties => {
            message => { type => 'string', description => 'SMS message to send' },
        },
        required => ['message'],
    },
    handler => sub {
        my ($args, $raw) = @_;
        my $result = SignalWire::SWAIG::FunctionResult->new(
            "SMS notification sent."
        );
        $result->send_sms(
            to_number   => '+15551234567',
            from_number => '+15559876543',
            body        => $args->{message} // 'Notification from call center',
        );
        return $result;
    },
);

# --- Tool: put_on_hold ---
$agent->define_tool(
    name        => 'put_on_hold',
    description => 'Put the caller on hold briefly',
    parameters  => { type => 'object', properties => {} },
    handler     => sub {
        my ($args, $raw) = @_;
        my $result = SignalWire::SWAIG::FunctionResult->new(
            'Placing you on hold for a moment.'
        );
        $result->hold(30);
        return $result;
    },
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

print "Starting Call Flow Demo\n";
print "Available at: http://localhost:3000/call-flow\n";

$agent->run;
