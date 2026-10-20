use v5.40;
use SDL3        qw[:all :main];
use SDL3::Mixer qw[:all];

# Port of SDL_mixer's examples/basics/02-play-with-options.
#
# Creates a mixer, loads a single sound, and plays it with several playback
# options (start offset, max duration, looping, loop point, fade-in).
# We will use this renderer to draw into this window every frame.
my ( $window, $renderer, $mixer, $track, $audio );

# Locate a bundled asset next to this script.
sub asset ($name) {
    my $dir = __FILE__ =~ s{[^/\\]+$}{}r;
    return $dir . 'assets/' . $name;
}

# This function runs once at startup.
sub SDL_AppInit ( $appstate, $argc, $argv ) {
    SDL_SetAppMetadata( 'Example Play With Options', '1.0', 'com.example.play-with-options' );

    # This doesn't have to run very much, so give up tons of CPU time between iterations. Optional!
    SDL_SetHint( SDL_HINT_MAIN_CALLBACK_RATE, '5' );

    # We don't need video, but we'll make a window for smooth operation.
    if ( !SDL_Init(SDL_INIT_VIDEO) ) {
        SDL_Log( q[Couldn't initialize SDL: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    if ( !SDL_CreateWindowAndRenderer( 'examples/basic/play-with-options', 640, 480, SDL_WINDOW_RESIZABLE, $window, $renderer ) ) {
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

    # We need a track on the mixer to play the audio.
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

    # These all use MILLISECONDS, since the track is generic, but you can use equivalent FRAMES
    # properties for frame-perfect mixing.
    SDL_SetNumberProperty( $options, MIX_PROP_PLAY_START_MILLISECOND_NUMBER,      1000 );     # start the first loop 1 second in.
    SDL_SetNumberProperty( $options, MIX_PROP_PLAY_MAX_MILLISECONDS_NUMBER,       11000 );    # play at most 10 seconds before ending/looping.
    SDL_SetNumberProperty( $options, MIX_PROP_PLAY_LOOPS_NUMBER,                  2 );        # loop 2 times; 3rd time through doesn't loop.
    SDL_SetNumberProperty( $options, MIX_PROP_PLAY_LOOP_START_MILLISECOND_NUMBER, 2000 );     # when looping, start again here.
    SDL_SetNumberProperty( $options, MIX_PROP_PLAY_FADE_IN_MILLISECONDS_NUMBER,   5000 );     # fade-in the first loop over five seconds.
    MIX_PlayTrack( $track, $options );
    SDL_DestroyProperties($options);    # MIX_PlayTrack makes a copy of the options, so this can go away.
    return SDL_APP_CONTINUE;
}

# This function runs when a new event (mouse input, keypresses, etc) occurs.
sub SDL_AppEvent ( $appstate, $event ) {
    return SDL_APP_SUCCESS if $event->{type} == SDL_EVENT_QUIT;
    return SDL_APP_CONTINUE;
}

# This function runs once per frame, and is the heart of the program.
sub SDL_AppIterate ($appstate) {

    # Draw a blank video frame to keep the OS happy.
    SDL_RenderClear($renderer);
    SDL_RenderPresent($renderer);

    # When the track has finished playing, end the program.
    return SDL_APP_SUCCESS unless MIX_TrackPlaying($track);
    return SDL_APP_CONTINUE;
}

# This function runs once at shutdown.
sub SDL_AppQuit ( $appstate, $result ) {

    # SDL will clean up the window/renderer for us, MIX_Quit() destroys any mixer objects we made.
    MIX_Quit();
}
