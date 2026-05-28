#!/usr/bin/env perl
# RELAY Client Demo
#
# Shows how to use the RELAY client to answer inbound calls and play TTS.
# This is a thin wrapper that demonstrates the RELAY client API.
#
# Set these env vars:
#   SIGNALWIRE_PROJECT_ID
#   SIGNALWIRE_API_TOKEN
#   SIGNALWIRE_SPACE

use strict;
use warnings;
use lib 'lib';
use SignalWire::Relay::Client;

my $client = SignalWire::Relay::Client->new(
    project  => $ENV{SIGNALWIRE_PROJECT_ID} // die("Set SIGNALWIRE_PROJECT_ID\n"),
    token    => $ENV{SIGNALWIRE_API_TOKEN}  // die("Set SIGNALWIRE_API_TOKEN\n"),
    host     => $ENV{SIGNALWIRE_SPACE}      // 'relay.signalwire.com',
    contexts => ['default'],
);

$client->on_call(sub {
    my ($call) = @_;
    print "Incoming call from RELAY: " . $call->call_id . "\n";
    $call->answer;

    # Play a welcome message
    my $action = $call->play(
        media => [{
            type   => 'tts',
            params => { text => 'Hello! This is a demo of the RELAY client in Perl.' },
        }],
    );
    $action->wait;

    # Say goodbye
    my $bye = $call->play(
        media => [{
            type   => 'tts',
            params => { text => 'Thank you for testing. Goodbye!' },
        }],
    );
    $bye->wait;

    $call->hangup;
    print "Call ended: " . $call->call_id . "\n";
});

$client->connect_ws  or die "WebSocket connection failed\n";
$client->authenticate;

print "RELAY Demo: Waiting for inbound calls...\n";
$client->run;
