use v5.40;
use SDL3 qw[:all];
$|++;

# Polyphonic Piano Synth
#
# This could be the start of a larger music project. It just demonstrates audio generation and mixing so far.
#
# Controls:
#  - Play by pressing keys on your keyboard. They map to A => K and W => U
#
# Config
my $SAMPLE_RATE = 48000;
my $BASE_VOLUME = 0.5;

# Init
die 'Init Error: ' . SDL_GetError() unless SDL_Init( SDL_INIT_VIDEO | SDL_INIT_AUDIO );
my $win       = SDL_CreateWindow( 'Polyphonic Synth (A,S,D,F...)', 800, 400, 0 );
my $ren       = SDL_CreateRenderer( $win, undef );
my $event_ptr = Affix::malloc(128);

# Audio setup
my $spec   = { format => SDL_AUDIO_F32, channels => 1, freq => $SAMPLE_RATE };                      # Float32, Mono, 48kHz
my $stream = SDL_OpenAudioDeviceStream( SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, $spec, undef, undef );
die 'Audio Error: ' . SDL_GetError() unless $stream;
my $dev_id = SDL_GetAudioStreamDevice($stream);
SDL_ResumeAudioDevice($dev_id);

# Music math
# Frequency = 440 * 2^((Note - 69) / 12)
# We map scancodes to semitones relative to C4
my %key_map = (
    SDL_SCANCODE_A => 0,     # C4
    SDL_SCANCODE_W => 1,     # C#4
    SDL_SCANCODE_S => 2,     # D4
    SDL_SCANCODE_E => 3,     # D#4
    SDL_SCANCODE_D => 4,     # E4
    SDL_SCANCODE_F => 5,     # F4
    SDL_SCANCODE_T => 6,     # F#4
    SDL_SCANCODE_G => 7,     # G4
    SDL_SCANCODE_Y => 8,     # G#4
    SDL_SCANCODE_H => 9,     # A4
    SDL_SCANCODE_U => 10,    # A#4
    SDL_SCANCODE_J => 11,    # B4
    SDL_SCANCODE_K => 12     # C5
);
sub get_freq($semitone) { 261.63 * ( 2**( $semitone / 12.0 ) ) }

# State
my $running = 1;

# Active voices: { scancode => { freq => 440.0, phase => 0.0 } }
my %voices;
my @last_buffer = (0) x 800;
say 'Synth Ready! Use A,W,S,E,D,F... to play keys.';
while ($running) {

    # Input
    while ( SDL_PollEvent($event_ptr) ) {
        my $h = Affix::cast( $event_ptr, SDL_CommonEvent );
        if ( $h->{type} == SDL_EVENT_QUIT ) {
            $running = 0;
        }
        elsif ( $h->{type} == SDL_EVENT_KEY_DOWN ) {
            my $k  = Affix::cast( $event_ptr, SDL_KeyboardEvent );
            my $sc = $k->{scancode};

            # Only add if mapped and not already playing (prevents stutter on key repeat)
            if ( exists $key_map{$sc} && !exists $voices{$sc} ) {
                $voices{$sc} = { freq => get_freq( $key_map{$sc} ), phase => 0.0 };
            }
        }
        elsif ( $h->{type} == SDL_EVENT_KEY_UP ) {
            my $k = Affix::cast( $event_ptr, SDL_KeyboardEvent );
            delete $voices{ $k->{scancode} };
        }
    }

    # Audio mixer
    my $queued = SDL_GetAudioStreamQueued($stream);
    if ( $queued < 8192 ) {
        my @buffer;
        my $num_voices = scalar keys %voices;

        # Volume limiter: The more keys you hold, the quieter each one gets to prevent clipping
        my $voice_vol = ( $num_voices > 0 ) ? ( $BASE_VOLUME / sqrt($num_voices) ) : 0;
        for ( 1 .. 800 ) {
            my $sample = 0.0;

            # Sum all active voices
            for my $v ( values %voices ) {
                $sample += sin( $v->{phase} );

                # Advance phase for this specific voice
                $v->{phase} += ( 6.28318 * $v->{freq} ) / $SAMPLE_RATE;
                if ( $v->{phase} > 6.28318 ) { $v->{phase} -= 6.28318; }
            }

            # Apply volume
            push @buffer, $sample * $voice_vol;
        }
        if (@buffer) {
            my $bin = pack( 'f*', @buffer );
            SDL_PutAudioStreamData( $stream, $bin, length($bin) );
            @last_buffer = @buffer;
        }
    }

    # Visualization
    SDL_SetRenderDrawColor( $ren, 20, 20, 30, 255 );
    SDL_RenderClear($ren);
    SDL_SetRenderDrawColor( $ren, 0, 255, 255, 255 );    # Cyan
    my $prev_y = 200;
    for my $x ( 0 .. 799 ) {
        my $idx = int( ( $x / 800 ) * scalar(@last_buffer) );
        my $val = $last_buffer[$idx] // 0;

        # Visualize loudness
        my $y = 200 + ( $val * 300 );
        SDL_RenderLine( $ren, $x - 1, $prev_y, $x, $y );
        $prev_y = $y;
    }

    # Draw active voice count
    SDL_RenderDebugText( $ren, 10, 10, 'Voices: ' . scalar keys %voices );
    SDL_RenderPresent($ren);
}
SDL_DestroyRenderer($ren);
SDL_DestroyWindow($win);
SDL_Quit();
