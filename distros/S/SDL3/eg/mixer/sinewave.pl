use v5.40;
use lib '../../lib';
use SDL3        qw[:all :main];
use SDL3::Mixer qw[:all];
$|++;
warn MIX_MAJOR_VERSION;
warn MIX_MINOR_VERSION;
warn MIX_MICRO_VERSION;
warn MIX_VERSION;
warn MIX_VERSION_ATLEAST( 3, 0, 0 );
warn MIX_VERSION_ATLEAST( 5, 0, 0 );
warn MIX_Version();
MIX_Init();

for ( 0 .. MIX_GetNumAudioDecoders() - 1 ) {    # Requires MIX_Init()
    warn $_ . ': ' . MIX_GetAudioDecoder($_);
}

#~ exit;
#
# This example code creates a mixer, and plays a sinewave forever.
#
# It's not super-useful to play a sinewave, but it is _something_
# to play if you don't have anything else, and it's built-in to
# SDL_mixer.
#
# This code is public domain. Feel free to use it for any purpose!
#
# We will use this renderer to draw into this window every frame.
my ( $window, $renderer );

# This function runs once at startup.
sub SDL_AppInit( $appstate, $argc, @argv ) {

    #~ return SDL_APP_FAILURE;
    my ( $mixer, $audio, $track );
    SDL_SetAppMetadata( 'Example Load And Play', '1.0', 'com.example.load-and-play' );

    # this doesn't have to run very much, so give up tons of CPU time between iterations. Optional!
    SDL_SetHint( SDL_HINT_MAIN_CALLBACK_RATE, '5' );

    # we don't need video, but we'll make a window for smooth operation.
    if ( !SDL_Init(SDL_INIT_VIDEO) ) {
        SDL_Log( q[Couldn't initialize SDL: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    if ( !SDL_CreateWindowAndRenderer( 'examples/basic/load-and-play', 640, 480, SDL_WINDOW_RESIZABLE, $window, $renderer ) ) {
        SDL_Log q[Couldn't create window/renderer: %s], SDL_GetError();
        return SDL_APP_FAILURE;
    }
    if ( !MIX_Init() ) {
        SDL_Log q[Couldn't init SDL_mixer library: %s], SDL_GetError();
        return SDL_APP_FAILURE;
    }

    # Create a mixer on the default audio device. Don't care about the specific audio format.
    $mixer = MIX_CreateMixerDevice( SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, undef );
    if ( !$mixer ) {
        SDL_Log q[Couldn't create mixer on default device: %s], SDL_GetError();
        return SDL_APP_FAILURE;
    }
    warn MIX_GetMixerProperties($mixer);
    warn MIX_GetMixerFormat( $mixer, my $hold );
    warn $hold;
    $audio = MIX_CreateSineWaveAudio( $mixer, 300, 0.25, -1 );    # -1 : play forever. You can specify milliseconds otherwise to have a limit.
    if ( !$audio ) {
        SDL_Log q[Couldn't generate sinewave: %s], SDL_GetError();
        return SDL_APP_FAILURE;
    }

    # we need a track on the mixer to play the audio. Each track has audio assigned to it, and
    # all playing tracks are mixed together for the final output.
    $track = MIX_CreateTrack($mixer);
    if ( !$track ) {
        SDL_Log q[Couldn't create a mixer track: %s], SDL_GetError();
        return SDL_APP_FAILURE;
    }
    MIX_SetTrackAudio( $track, $audio );

    # start the audio playing!
    MIX_PlayTrack( $track, 0 );    # no extra options this time, so a zero for the second argument.

    # we don't save `mixer`, `audio`, or `track`; SDL_mixer will clean it up for us during MIX_Quit().
    return SDL_APP_CONTINUE;       # carry on with the program!
}

# This function runs when a new event (mouse input, keypresses, etc) occurs.
sub SDL_AppEvent( $appstate, $event ) {
    return SDL_APP_SUCCESS if $event->{type} == SDL_EVENT_QUIT;    # end the program, reporting success to the OS.
    return SDL_APP_CONTINUE;                                       # carry on with the program!
}

# This function runs once per frame, and is the heart of the program.
sub SDL_AppIterate($appstate) {
    SDL_RenderClear($renderer);                                    # draw a blank video frame to keep the OS happy
    SDL_RenderPresent($renderer);

    # There's nothing for use to do here, the sinewave will play forever until the app is manually quit.
    return SDL_APP_CONTINUE;                                       # carry on with the program!
}

# This function runs once at shutdown.
sub SDL_AppQuit( $appstate, $result ) {
    MIX_Quit();    # SDL will clean up the window/renderer for us, MIX_Quit() destroys any mixer objects we made.
}
