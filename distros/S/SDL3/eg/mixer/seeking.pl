use v5.40;
use SDL3        qw[:all :main];
use SDL3::Mixer qw[:all];

# Port of SDL_mixer's examples/basics/06-seeking.
#
# Creates a mixer, loads a single sound, and plays it on a loop, letting you
# seek around in playback by clicking or dragging in the progress bar.
# We will use this renderer to draw into this window every frame.
my ( $window, $renderer, $mixer, $audio, $track );

# The progress bar we draw and hit-test against.
my $PROGRESSBAR = { x => 120, y => 225, w => 400, h => 75 };
my $KNOB_WIDTH  = 30;

# Locate a bundled asset next to this script.
sub asset ($name) {
    my $dir = __FILE__ =~ s{[^/\\]+$}{}r;
    return $dir . 'assets/' . $name;
}

# Seek based on where the user clicked/dragged inside the progress bar.
sub seek_audio ( $x, $y ) {
    return unless SDL_PointInRectFloat( { x => $x, y => $y }, $PROGRESSBAR );

    # Jump to a new position in the track, as a fraction of the audio's length.
    my $pct = ( $x - $PROGRESSBAR->{x} ) / $PROGRESSBAR->{w};
    MIX_SetTrackPlaybackPosition( $track, int( MIX_GetAudioDuration($audio) * $pct ) );
}

# This function runs once at startup.
sub SDL_AppInit ( $appstate, $argc, $argv ) {
    SDL_SetAppMetadata( 'Example Seeking', '1.0', 'com.example.seeking' );

    # This doesn't have to run very much, so give up tons of CPU time between iterations. Optional!
    SDL_SetHint( SDL_HINT_MAIN_CALLBACK_RATE, '5' );

    # We don't need video, but we'll make a window for smooth operation.
    if ( !SDL_Init(SDL_INIT_VIDEO) ) {
        SDL_Log( q[Couldn't initialize SDL: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    if ( !SDL_CreateWindowAndRenderer( 'examples/basic/seeking', 640, 480, SDL_WINDOW_RESIZABLE, $window, $renderer ) ) {
        SDL_Log( q[Couldn't create window/renderer: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    if ( !MIX_Init() ) {
        SDL_Log( q[Couldn't init SDL_mixer library: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }

    # Create a mixer on the default audio device. Don't care about the specific audio format.
    $mixer = MIX_CreateMixerDevice( SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, undef );
    if ( !$mixer ) {
        SDL_Log( q[Couldn't create mixer on default device: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }

    # Load a sound file.
    my $path = asset('music.mp3');
    $audio = MIX_LoadAudio( $mixer, $path, 0 );
    if ( !$audio ) {
        SDL_Log( q[Couldn't load %s: %s], $path, SDL_GetError() );
        return SDL_APP_FAILURE;
    }

    # We need a track on the mixer to play the audio. Each track has audio assigned to it, and
    # all playing tracks are mixed together for the final output.
    $track = MIX_CreateTrack($mixer);
    if ( !$track ) {
        SDL_Log( q[Couldn't create a mixer track: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    MIX_SetTrackAudio( $track, $audio );

    # Start the audio playing!
    my $options = SDL_CreateProperties();
    if ( !$options ) {
        SDL_Log( q[Couldn't create play options: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }

    # Note these use MILLISECONDS, since the track is generic, but you can use equivalent FRAMES
    # properties for frame-perfect mixing.
    SDL_SetNumberProperty( $options, MIX_PROP_PLAY_LOOPS_NUMBER, -1 );    # loop forever
    MIX_PlayTrack( $track, $options );
    SDL_DestroyProperties($options);                                      # MIX_PlayTrack makes a copy of the options, so this can go away.
    return SDL_APP_CONTINUE;
}

# This function runs when a new event (mouse input, keypresses, etc) occurs.
sub SDL_AppEvent ( $appstate, $event ) {
    my $type = $event->{type};
    if ( $type == SDL_EVENT_QUIT ) {
        return SDL_APP_SUCCESS;
    }
    elsif ( $type == SDL_EVENT_MOUSE_BUTTON_DOWN ) {
        seek_audio( $event->{button}{x}, $event->{button}{y} ) if $event->{button}{button} == 1;
    }
    elsif ( $type == SDL_EVENT_MOUSE_MOTION ) {

        # Dragging with the left button held keeps seeking.
        seek_audio( $event->{motion}{x}, $event->{motion}{y} ) if $event->{motion}{state} & SDL_BUTTON_LMASK;
    }
    return SDL_APP_CONTINUE;
}

# This function runs once per frame, and is the heart of the program.
sub SDL_AppIterate ($appstate) {
    my $duration = MIX_GetAudioDuration($audio);
    my $position = MIX_GetTrackPlaybackPosition($track);

    # Place the knob along the bar according to how far playback has gotten.
    my $knob = { x => $PROGRESSBAR->{x}, y => $PROGRESSBAR->{y}, w => $KNOB_WIDTH, h => $PROGRESSBAR->{h} };
    $knob->{x} += ( $PROGRESSBAR->{w} - $knob->{w} ) * ( $position / $duration );
    SDL_SetRenderDrawColor( $renderer, 0, 0, 100, 255 );
    SDL_RenderClear($renderer);
    SDL_SetRenderDrawColor( $renderer, 255, 255, 0, 255 );
    SDL_RenderFillRect( $renderer, $PROGRESSBAR );
    SDL_SetRenderDrawColor( $renderer, 255, 0, 0, 255 );
    SDL_RenderFillRect( $renderer, $knob );
    SDL_RenderPresent($renderer);
    return SDL_APP_CONTINUE;
}

# This function runs once at shutdown.
sub SDL_AppQuit ( $appstate, $result ) {

    # SDL will clean up the window/renderer for us, MIX_Quit() destroys any mixer objects we made.
    MIX_Quit();
}
