#!perl
use strict;
use Speech::Recognition::Vosk::Recognizer;

my $recognizer = Speech::Recognition::Vosk::Recognizer->new(
    model_dir => 'model-en',
    sample_rate => 44100,
);

# record from PulseAudio device 11
open my $voice, 'ffmpeg -hide_banner -loglevel error -nostats -f pulse -i 11 -t 30 -ac 1 -ar 44100 -f s16le - |';
binmode $voice, ':raw';

while( ! eof($voice)) {
    read($voice, my $buf, 3200);

    my $complete = $recognizer->accept_waveform($buf);
    my $info;
    if( $complete ) {
        $info = $recognizer->result();
    } else {
        $info = $recognizer->partial_result();
    }
    if( $info->{text}) {
        print $info->{text},"\n";
    } else {
        local $| = 1;
        print $info->{partial}, "\r";
    };
};
my $info = $recognizer->final_result();
print $info->{text},"\n";
