#!/usr/bin/env perl
# Dial a number and play "Welcome to SignalWire" using the RELAY client.
#
# Requires env vars:
#     SIGNALWIRE_PROJECT_ID
#     SIGNALWIRE_API_TOKEN
#     RELAY_FROM_NUMBER   - a number on your SignalWire project
#     RELAY_TO_NUMBER     - destination to call

use strict;
use warnings;
use lib 'lib';
use SignalWire::Relay::Client;

my $from_number = $ENV{RELAY_FROM_NUMBER} // die("Set RELAY_FROM_NUMBER\n");
my $to_number   = $ENV{RELAY_TO_NUMBER}   // die("Set RELAY_TO_NUMBER\n");

my $client = SignalWire::Relay::Client->new(
    project => $ENV{SIGNALWIRE_PROJECT_ID} // die("Set SIGNALWIRE_PROJECT_ID\n"),
    token   => $ENV{SIGNALWIRE_API_TOKEN}  // die("Set SIGNALWIRE_API_TOKEN\n"),
    host    => $ENV{SIGNALWIRE_SPACE}      // 'relay.signalwire.com',
);

$client->connect_ws  or die "Connection failed\n";
$client->authenticate;
print "Connected -- protocol: " . $client->protocol . "\n";

# Dial the number
my $call = eval {
    $client->dial(
        devices => [[{
            type   => 'phone',
            params => {
                to_number   => $to_number,
                from_number => $from_number,
            },
        }]],
        timeout => 30,
    );
};
if ($@) {
    print "Dial failed: $@\n";
    $client->disconnect_ws;
    exit 1;
}

print "Dialing $to_number from $from_number -- call_id: " . $call->call_id . "\n";
print "Call answered -- playing TTS\n";

# Play TTS
my $play_action = $call->play(
    media => [{ type => 'tts', params => { text => 'Welcome to SignalWire' } }],
);

# Wait for playback to finish
$play_action->wait(timeout => 15);
print "Playback finished -- hanging up\n";

$call->hangup;

# Allow the ended event to arrive
for (1 .. 50) {
    last if $call->state eq 'ended';
    $client->_read_once;
}
print "Call ended\n";

$client->disconnect_ws;
print "Disconnected\n";
