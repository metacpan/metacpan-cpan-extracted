#!/usr/bin/env perl
# Example: IVR input collection, AI operations, and advanced call control.
#
# NOTE: These commands require an active call. The call_id used here is
# illustrative -- in production you would obtain it from a dial response or
# inbound call event.
#
# Set these env vars:
#   SIGNALWIRE_PROJECT_ID   - your SignalWire project ID
#   SIGNALWIRE_API_TOKEN    - your SignalWire API token
#   SIGNALWIRE_SPACE        - your SignalWire space

use strict;
use warnings;
use lib 'lib';
use SignalWire::Agents::REST::SignalWireClient;

my $client = SignalWire::Agents::REST::SignalWireClient->new(
    project => $ENV{SIGNALWIRE_PROJECT_ID} // die("Set SIGNALWIRE_PROJECT_ID\n"),
    token   => $ENV{SIGNALWIRE_API_TOKEN}  // die("Set SIGNALWIRE_API_TOKEN\n"),
    host    => $ENV{SIGNALWIRE_SPACE}      // die("Set SIGNALWIRE_SPACE\n"),
);

my $CALL_ID = 'demo-call-id';

sub safe {
    my ($label, $fn) = @_;
    my $result = eval { $fn->() };
    if ($@) {
        print "  $label: failed ($@)\n";
        return undef;
    }
    print "  $label: OK\n";
    return $result;
}

# 1. Collect DTMF input
print "Collecting DTMF input...\n";
safe('Collect', sub {
    $client->calling->collect(
        $CALL_ID,
        digits => { max => 4, terminators => '#' },
        play   => [{ type => 'tts', text => 'Enter your PIN followed by pound.' }],
    );
});
safe('Start input timers', sub { $client->calling->collect_start_input_timers($CALL_ID) });
safe('Stop collect',       sub { $client->calling->collect_stop($CALL_ID) });

# 2. Answering machine detection
print "\nDetecting answering machine...\n";
safe('Detect',      sub { $client->calling->detect($CALL_ID, type => 'machine') });
safe('Stop detect', sub { $client->calling->detect_stop($CALL_ID) });

# 3. AI operations
print "\nAI agent operations...\n";
safe('AI message', sub {
    $client->calling->ai_message($CALL_ID,
        message => 'The customer wants to check their balance.');
});
safe('AI hold',   sub { $client->calling->ai_hold($CALL_ID) });
safe('AI unhold', sub { $client->calling->ai_unhold($CALL_ID) });
safe('AI stop',   sub { $client->calling->ai_stop($CALL_ID) });

# 4. Live transcription and translation
print "\nLive transcription and translation...\n";
safe('Live transcribe', sub {
    $client->calling->live_transcribe($CALL_ID, language => 'en-US');
});
safe('Live translate', sub {
    $client->calling->live_translate($CALL_ID, language => 'es');
});

# 5. Tap (media fork)
print "\nTap (media fork)...\n";
safe('Tap start', sub {
    $client->calling->tap($CALL_ID,
        tap    => { type => 'audio', direction => 'both' },
        device => { type => 'rtp', addr => '192.168.1.100', port => 9000 },
    );
});
safe('Tap stop', sub { $client->calling->tap_stop($CALL_ID) });

# 6. Stream (WebSocket)
print "\nStream (WebSocket)...\n";
safe('Stream start', sub {
    $client->calling->stream($CALL_ID, url => 'wss://example.com/audio-stream');
});
safe('Stream stop', sub { $client->calling->stream_stop($CALL_ID) });

# 7. User event
print "\nSending user event...\n";
safe('User event', sub {
    $client->calling->user_event($CALL_ID,
        event_name => 'agent_note',
        data       => { note => 'VIP caller' },
    );
});

# 8. SIP refer
print "\nSIP refer...\n";
safe('SIP refer', sub {
    $client->calling->refer($CALL_ID, sip_uri => 'sip:support@example.com');
});

# 9. Fax stop commands
print "\nFax stop commands...\n";
safe('Send fax stop',    sub { $client->calling->send_fax_stop($CALL_ID) });
safe('Receive fax stop', sub { $client->calling->receive_fax_stop($CALL_ID) });

# 10. Transfer and disconnect
print "\nTransfer and disconnect...\n";
safe('Transfer', sub {
    $client->calling->transfer($CALL_ID, dest => '+15559999999');
});
safe('Update call', sub {
    $client->calling->update(call_id => $CALL_ID, metadata => { priority => 'high' });
});
safe('Disconnect', sub { $client->calling->disconnect($CALL_ID) });
