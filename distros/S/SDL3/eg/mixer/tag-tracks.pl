use v5.40;
use SDL3        qw[:all :main];
use SDL3::Mixer qw[:all];

# Port of SDL_mixer's examples/advanced/01-tag-tracks.
#
# Creates a mixer, plays sounds, and tags them into groups. A background music
# track and a pile of sound effects share the mixer; the effects are all tagged
# "in-game". Pressing SPACE pauses the tag, so every in-game sound freezes at
# once while the untagged background music keeps playing -- exactly the trick
# you want when a game pauses.
# We will use this renderer to draw into this window every frame.
my ( $window, $renderer, $mixer );
my $TAG_INGAME = 'in-game';

# tracks[0] is the music; tracks[1..] are the tagged sound effects.
my @tracks;
my $next_play_ticks = 0;    # next time we will start a sound effect.
my $next_play_track = 1;    # next track we will use when starting a sound effect.
my $paused          = 0;    # whether our fake game is paused at the moment.

# The audio we load up front, in the order the C demo loads it.
my @loaded_audio;           # arrayrefs of [ filename, audio ]

# Locate a bundled asset next to this script.
sub asset ($name) {
    my $dir = __FILE__ =~ s{[^/\\]+$}{}r;
    return $dir . 'assets/' . $name;
}

sub load_audio ($fname) {
    my $path  = asset($fname);
    my $audio = MIX_LoadAudio( $mixer, $path, 0 );
    SDL_Log( q[Couldn't load %s: %s], $path, SDL_GetError() ) if !$audio;
    return $audio;
}

# This function runs once at startup.
sub SDL_AppInit ( $appstate, $argc, $argv ) {
    SDL_SetAppMetadata( 'Example Tagging Tracks', '1.0', 'com.example.tagging-tracks' );
    if ( !SDL_Init(SDL_INIT_VIDEO) ) {
        SDL_Log( q[Couldn't initialize SDL: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    if ( !SDL_CreateWindowAndRenderer( 'examples/advanced/tagging-tracks', 640, 480, SDL_WINDOW_RESIZABLE, $window, $renderer ) ) {
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

    # Load our audio files. Note that you can use any supported file format!
    for my $fname ( 'music.mp3', 'sword.wav', 'splash.wav', 'spring.wav' ) {
        my $audio = load_audio($fname);
        return SDL_APP_FAILURE if !$audio;    # we reported the error in load_audio
        push @loaded_audio, $audio;
    }

    # We need tracks on the mixer to play the audio. Each track has audio assigned to it, and
    # all playing tracks are mixed together for the final output.
    for my $i ( 0 .. 31 ) {
        my $track = MIX_CreateTrack($mixer);
        if ( !$track ) {
            SDL_Log( q[Couldn't create a mixer track: %s], SDL_GetError() );
            return SDL_APP_FAILURE;
        }

        # Everything but the background music is tagged as in-game for this example.
        if ( $i > 0 ) {
            if ( !MIX_TagTrack( $track, $TAG_INGAME ) ) {
                SDL_Log( q[Couldn't tag mixer track #%d: %s], $i, SDL_GetError() );
                return SDL_APP_FAILURE;
            }
        }
        push @tracks, $track;
    }

    # Put the music (first thing we loaded) on tracks[0], for simplicity here.
    MIX_SetTrackAudio( $tracks[0], $loaded_audio[0] );
    my $options = SDL_CreateProperties();
    if ( !$options ) {
        SDL_Log( q[Couldn't create play options: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    SDL_SetNumberProperty( $options, MIX_PROP_PLAY_LOOPS_NUMBER, -1 );    # loop forever.

    # Start the music playing! It loops forever.
    MIX_PlayTrack( $tracks[0], $options );
    SDL_DestroyProperties($options);                                      # MIX_PlayTrack makes a copy of the options, so this can go away.
    return SDL_APP_CONTINUE;
}

# This function runs when a new event (mouse input, keypresses, etc) occurs.
sub SDL_AppEvent ( $appstate, $event ) {
    my $type = $event->{type};
    if ( $type == SDL_EVENT_QUIT ) {
        return SDL_APP_SUCCESS;
    }
    elsif ( $type == SDL_EVENT_KEY_DOWN && $event->{key}{key} == SDLK_SPACE ) {
        $paused = !$paused;
        if ($paused) {
            MIX_PauseTag( $mixer, $TAG_INGAME );
        }
        else {
            MIX_ResumeTag( $mixer, $TAG_INGAME );
        }
    }
    return SDL_APP_CONTINUE;
}

sub draw_centered_text ( $rw, $y_ref, $str ) {
    my $x = ( $rw - length($str) * SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE() ) / 2;
    SDL_RenderDebugText( $renderer, $x, $$y_ref, $str );
    $$y_ref += SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE() * 2;
}

# This function runs once per frame, and is the heart of the program.
sub SDL_AppIterate ($appstate) {
    my $now = SDL_GetTicks();

    # Simulate video game sounds by starting a new one every now and then, with some randomness.
    if ( !$paused && $now >= $next_play_ticks ) {
        my $track = $tracks[$next_play_track];

        # These sounds are short enough that the tracks will finish playing before we reuse them.
        my $pick = $loaded_audio[ SDL_rand_bits() % ( scalar(@loaded_audio) - 1 ) + 1 ];    # a random not-music sound.
        MIX_SetTrackAudio( $track, $pick );
        MIX_PlayTrack( $track, 0 );
        $next_play_track++;
        if ( $next_play_track >= scalar(@tracks) ) {
            $next_play_track = 1;                                                           # tracks[0] is the music, skip it.
        }
        $next_play_ticks = $now + ( SDL_rand_bits() % 1000 );
    }
    my $rw = 0;
    my $rh = 0;
    SDL_GetCurrentRenderOutputSize( $renderer, \$rw, \$rh );
    SDL_SetRenderDrawColor( $renderer, 0, 0, 0, 255 );    # clear to black
    SDL_RenderClear($renderer);
    my $y = SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE() * 8;
    SDL_SetRenderDrawColor( $renderer, 255, 255, 255, 255 );    # white text
    draw_centered_text( $rw, \$y, 'PRETEND THIS IS A VIDEO GAME.' );
    draw_centered_text( $rw, \$y, 'THERE ARE SOUND EFFECTS AND BACKGROUND MUSIC.' );
    draw_centered_text( $rw, \$y, 'THE EFFECTS ARE ON TRACKS TAGGED AS "in-game".' );
    draw_centered_text( $rw, \$y, 'PRESS SPACE TO PAUSE/UNPAUSE THE GAME.' );
    draw_centered_text( $rw, \$y, 'THE IN-GAME SOUNDS WILL PAUSE.' );
    draw_centered_text( $rw, \$y, 'THE MUSIC TRACK, NOT TAGGED, WILL NOT.' );
    $y += SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE() * 8;

    if ($paused) {
        SDL_SetRenderDrawColor( $renderer, 255, 0, 0, 255 );    # red text
        draw_centered_text( $rw, \$y, '[ CURRENTLY PAUSED ]' );
    }
    else {
        SDL_SetRenderDrawColor( $renderer, 0, 255, 0, 255 );    # green text
        draw_centered_text( $rw, \$y, '[ CURRENTLY UNPAUSED ]' );
    }
    SDL_RenderPresent($renderer);
    return SDL_APP_CONTINUE;
}

# This function runs once at shutdown.
sub SDL_AppQuit ( $appstate, $result ) {

    # SDL will clean up the window/renderer for us, MIX_Quit() destroys any mixer objects we made.
    MIX_Quit();
}
