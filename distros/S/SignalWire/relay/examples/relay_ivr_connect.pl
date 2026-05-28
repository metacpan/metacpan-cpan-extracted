#!/usr/bin/env perl
# Example: IVR menu with DTMF collection, playback, and call connect.
#
# Answers an inbound call, plays a greeting, collects a digit, and
# routes the caller based on their choice:
#   1 - Hear a sales message
#   2 - Hear a support message
#   0 - Connect to a live agent at +19184238080
#
# Set these env vars:
#   SIGNALWIRE_PROJECT_ID   - your SignalWire project ID
#   SIGNALWIRE_API_TOKEN    - your SignalWire API token
#   SIGNALWIRE_SPACE        - your SignalWire space (optional)

use strict;
use warnings;
use lib 'lib';
use SignalWire::Relay::Client;

my $AGENT_NUMBER = '+19184238080';

my $client = SignalWire::Relay::Client->new(
    project  => $ENV{SIGNALWIRE_PROJECT_ID} // die("Set SIGNALWIRE_PROJECT_ID\n"),
    token    => $ENV{SIGNALWIRE_API_TOKEN}  // die("Set SIGNALWIRE_API_TOKEN\n"),
    host     => $ENV{SIGNALWIRE_SPACE}      // 'relay.signalwire.com',
    contexts => ['default'],
);

# Helper to build a TTS play element
sub tts {
    my ($text) = @_;
    return { type => 'tts', params => { text => $text } };
}

$client->on_call(sub {
    my ($call) = @_;
    print "Incoming call: " . $call->call_id . "\n";
    $call->answer;

    # Play greeting and collect a single digit
    my $collect_action = $call->play_and_collect(
        media => [
            tts('Welcome to SignalWire!'),
            tts('Press 1 for sales. Press 2 for support. Press 0 to speak with an agent.'),
        ],
        collect => {
            digits => {
                max           => 1,
                digit_timeout => 5.0,
            },
            initial_timeout => 10.0,
        },
    );

    my $result_event = $collect_action->wait;
    my $result       = {};
    my $result_type  = '';
    my $digits       = '';

    if ($result_event && $result_event->can('params')) {
        $result      = $result_event->params->{result} // {};
        $result_type = $result->{type}   // '';
        $digits      = ($result->{params} // {})->{digits} // '';
    }

    print "Collect result: type=$result_type digits=$digits\n";

    if ($result_type eq 'digit' && $digits eq '1') {
        # Sales
        my $action = $call->play(
            media => [tts('Thank you for your interest! A sales representative will be with you shortly.')],
        );
        $action->wait;
    }
    elsif ($result_type eq 'digit' && $digits eq '2') {
        # Support
        my $action = $call->play(
            media => [tts('Please hold while we connect you to our support team.')],
        );
        $action->wait;
    }
    elsif ($result_type eq 'digit' && $digits eq '0') {
        # Connect to live agent
        my $action = $call->play(
            media => [tts('Connecting you to an agent now. Please hold.')],
        );
        $action->wait;

        my $from_number = ($call->device->{params} // {})->{to_number} // '';
        print "Connecting to $AGENT_NUMBER from $from_number\n";

        $call->connect(
            devices  => [[{
                type   => 'phone',
                params => {
                    to_number   => $AGENT_NUMBER,
                    from_number => $from_number,
                    timeout     => 30,
                },
            }]],
            ringback => [tts('Please wait while we connect your call.')],
        );

        # Stay on the call until the bridge ends
        while ($call->state ne 'ended') {
            $client->_read_once;
        }
        print "Connected call ended: " . $call->call_id . "\n";
        return;
    }
    else {
        # No input or invalid
        my $action = $call->play(
            media => [tts("We didn't receive a valid selection.")],
        );
        $action->wait;
    }

    $call->hangup;
    print "Call ended: " . $call->call_id . "\n";
});

$client->connect_ws  or die "Connection failed\n";
$client->authenticate;
print "Waiting for inbound calls on context 'default' ...\n";
$client->run;
