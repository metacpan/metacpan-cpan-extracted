#!/usr/bin/env perl
# Example: Control an active call with media operations (play, record, transcribe, denoise).
#
# NOTE: These commands require an active call. The call_id used here is
# illustrative -- in production you would obtain it from a dial response.
#
# Set these env vars:
#   SIGNALWIRE_PROJECT_ID   - your SignalWire project ID
#   SIGNALWIRE_API_TOKEN    - your SignalWire API token
#   SIGNALWIRE_SPACE        - your SignalWire space

use strict;
use warnings;
use lib 'lib';
use SignalWire::REST::RestClient;

my $client = SignalWire::REST::RestClient->new(
    project => $ENV{SIGNALWIRE_PROJECT_ID} // die("Set SIGNALWIRE_PROJECT_ID\n"),
    token   => $ENV{SIGNALWIRE_API_TOKEN}  // die("Set SIGNALWIRE_API_TOKEN\n"),
    host    => $ENV{SIGNALWIRE_SPACE}      // die("Set SIGNALWIRE_SPACE\n"),
);

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

# 1. Dial an outbound call
print "Dialing outbound call...\n";
my $call = safe('Dial', sub {
    $client->calling->dial(
        from_ => '+15559876543',
        to    => '+15551234567',
        url   => 'https://example.com/call-handler',
    );
});
my $call_id = ($call && $call->{id}) ? $call->{id} : 'demo-call-id';
print "  Call initiated: $call_id\n";

# 2. Play TTS audio
print "\nPlaying TTS on call...\n";
safe('Play', sub {
    $client->calling->play($call_id,
        play => [{ type => 'tts', text => 'Welcome to SignalWire.' }]);
});

# 3. Pause, resume, adjust volume, stop playback
print "\nControlling playback...\n";
safe('Pause',      sub { $client->calling->play_pause($call_id) });
safe('Resume',     sub { $client->calling->play_resume($call_id) });
safe('Volume +2dB', sub { $client->calling->play_volume($call_id, volume => 2.0) });
safe('Stop',       sub { $client->calling->play_stop($call_id) });

# 4. Record the call
print "\nRecording call...\n";
safe('Record', sub {
    $client->calling->record($call_id, beep => 1, format => 'mp3');
});

# 5. Pause, resume, stop recording
print "\nControlling recording...\n";
safe('Pause',  sub { $client->calling->record_pause($call_id) });
safe('Resume', sub { $client->calling->record_resume($call_id) });
safe('Stop',   sub { $client->calling->record_stop($call_id) });

# 6. Transcribe the call
print "\nTranscribing call...\n";
safe('Start transcribe', sub { $client->calling->transcribe($call_id, language => 'en-US') });
safe('Stop transcribe',  sub { $client->calling->transcribe_stop($call_id) });

# 7. Denoise the call
print "\nEnabling denoise...\n";
safe('Start denoise', sub { $client->calling->denoise($call_id) });
safe('Stop denoise',  sub { $client->calling->denoise_stop($call_id) });

# 8. End the call
print "\nEnding call...\n";
safe('End call', sub { $client->calling->end($call_id, reason => 'hangup') });
