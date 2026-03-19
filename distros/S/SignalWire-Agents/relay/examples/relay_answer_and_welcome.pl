#!/usr/bin/env perl
# Example: Answer an inbound call and say "Welcome to SignalWire!"
#
# Set these env vars:
#   SIGNALWIRE_PROJECT_ID   - your SignalWire project ID
#   SIGNALWIRE_API_TOKEN    - your SignalWire API token
#   SIGNALWIRE_SPACE        - your SignalWire space (e.g. example.signalwire.com)

use strict;
use warnings;
use lib 'lib';
use SignalWire::Agents::Relay::Client;

my $client = SignalWire::Agents::Relay::Client->new(
    project  => $ENV{SIGNALWIRE_PROJECT_ID}  // die("Set SIGNALWIRE_PROJECT_ID\n"),
    token    => $ENV{SIGNALWIRE_API_TOKEN}    // die("Set SIGNALWIRE_API_TOKEN\n"),
    host     => $ENV{SIGNALWIRE_SPACE}        // 'relay.signalwire.com',
    contexts => ['default'],
);

$client->on_call(sub {
    my ($call) = @_;
    print "Incoming call: " . $call->call_id . "\n";
    $call->answer;

    my $action = $call->play(
        media => [{ type => 'tts', params => { text => 'Welcome to SignalWire!' } }],
    );
    $action->wait;

    $call->hangup;
    print "Call ended: " . $call->call_id . "\n";
});

$client->connect_ws  or die "Connection failed\n";
$client->authenticate;
print "Waiting for inbound calls on context 'default' ...\n";
$client->run;
