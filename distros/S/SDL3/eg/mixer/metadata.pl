use v5.40;
use SDL3        qw[:all :main];
use SDL3::Mixer qw[:all];

# Port of SDL_mixer's examples/basics/04-metadata.
#
# Loads a single sound and displays everything SDL_mixer knows about it: the
# audio format and every metadata item found in the file. Metadata lives in an
# SDL properties group, so this also shows how to walk one with
# SDL_EnumerateProperties().
#
# Drop a different audio file onto the window to inspect that instead.
# We will use this renderer to draw into this window every frame.
my ( $window, $renderer, $audio, $path );

# Locate a bundled asset next to this script.
sub asset ($name) {
    my $dir = __FILE__ =~ s{[^/\\]+$}{}r;
    return $dir . 'assets/' . $name;
}

# This function runs once at startup.
sub SDL_AppInit ( $appstate, $argc, $argv ) {
    SDL_SetAppMetadata( 'Example Metadata', '1.0', 'com.example.metadata' );

    # This doesn't have to run very much, so give up tons of CPU time between iterations. Optional!
    SDL_SetHint( SDL_HINT_MAIN_CALLBACK_RATE, '5' );

    # We don't need video, but we'll make a window for smooth operation.
    if ( !SDL_Init(SDL_INIT_VIDEO) ) {
        SDL_Log( q[Couldn't initialize SDL: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    if ( !SDL_CreateWindowAndRenderer( 'examples/basic/metadata', 640, 480, SDL_WINDOW_RESIZABLE, $window, $renderer ) ) {
        SDL_Log( q[Couldn't create window/renderer: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    if ( !MIX_Init() ) {
        SDL_Log( q[Couldn't init SDL_mixer library: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }

    # MIX_Audio is shared between mixers, so a NULL mixer is fine here; a real one would just
    # let it optimize for that specific output.
    $path  = asset('music.mp3');
    $audio = MIX_LoadAudio( undef, $path, 0 );

    # If MIX_LoadAudio failed it's okay, the user can drop a new file on the window.
    return SDL_APP_CONTINUE;
}

# This function runs when a new event (mouse input, keypresses, etc) occurs.
sub SDL_AppEvent ( $appstate, $event ) {
    my $type = $event->{type};
    if ( $type == SDL_EVENT_QUIT ) {
        return SDL_APP_SUCCESS;
    }
    elsif ( $type == SDL_EVENT_DROP_FILE ) {
        MIX_DestroyAudio($audio) if $audio;
        $path  = $event->{drop}{data};
        $audio = MIX_LoadAudio( undef, $path, 0 );
    }
    return SDL_APP_CONTINUE;
}

# Format one metadata item as a line of text, the way the C demo's RenderMetadata
# switch does. SDL_EnumerateProperties calls this once per item.
sub describe_metadata ( $props, $name ) {
    my $type = SDL_GetPropertyType( $props, $name );

    # SDL_GetPropertyType returns one of the SDL_PROPERTY_TYPE_* values, which
    # compare numerically against the constants exported by SDL3.
    if ( $type == SDL_PROPERTY_TYPE_INVALID ) {
        return sprintf ' - %s [invalid type]', $name;
    }
    elsif ( $type == SDL_PROPERTY_TYPE_POINTER ) {
        return sprintf ' - %s [pointer=%s]', $name, SDL_GetPointerProperty( $props, $name, undef );
    }
    elsif ( $type == SDL_PROPERTY_TYPE_STRING ) {
        return sprintf ' - %s [string="%s"]', $name, SDL_GetStringProperty( $props, $name, '' );
    }
    elsif ( $type == SDL_PROPERTY_TYPE_NUMBER ) {
        return sprintf ' - %s [number=%d]', $name, SDL_GetNumberProperty( $props, $name, 0 );
    }
    elsif ( $type == SDL_PROPERTY_TYPE_FLOAT ) {
        return sprintf ' - %s [float=%f]', $name, SDL_GetFloatProperty( $props, $name, 0.0 );
    }
    elsif ( $type == SDL_PROPERTY_TYPE_BOOLEAN ) {
        return sprintf ' - %s [boolean=%s]', $name, ( SDL_GetBooleanProperty( $props, $name, 0 ) ? 'true' : 'false' );
    }
    return sprintf ' - %s [unknown type]', $name;
}

# This function runs once per frame, and is the heart of the program.
sub SDL_AppIterate ($appstate) {

    # Audio file metadata is stored in an SDL properties group; you can hang any app-specific
    # metadata on here too!
    my $props = MIX_GetAudioProperties($audio);
    my $spec  = {};
    my $y     = 0.0;
    SDL_SetRenderDrawColor( $renderer, 0, 0, 0, 255 );    # black
    SDL_RenderClear($renderer);
    SDL_SetRenderDrawColor( $renderer, 255, 255, 255, 255 );    # white
    MIX_GetAudioFormat( $audio, $spec );
    SDL_RenderDebugText( $renderer, 0.0, $y, '== Drop a file on this window to get its metadata. ==' );
    $y += SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE() * 2.0;

    if ($audio) {
        SDL_RenderDebugText( $renderer, 0.0, $y, $path );
        $y += SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE() + 2.0;
        SDL_RenderDebugText(
            $renderer, 0.0, $y,
            sprintf '%s, %d channel%s, %d freq',
            SDL_GetAudioFormatName( $spec->{format} ),
            $spec->{channels}, ( $spec->{channels} == 1 ? '' : 's' ),
            $spec->{freq}
        );
        $y += SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE() * 2.0;

        # Now draw all the metadata. The closure runs once per item and advances
        # $y, so each line lands below the last -- the callback signature is
        # (userdata, properties, name), and userdata comes through as undef here.
        my $draw_one = sub ( $userdata, $props, $name ) {
            SDL_RenderDebugText( $renderer, 0.0, $y, describe_metadata( $props, $name ) );
            $y += SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE() + 2;
        };
        SDL_EnumerateProperties( $props, $draw_one, undef );
    }
    SDL_RenderPresent($renderer);
    return SDL_APP_CONTINUE;
}

# This function runs once at shutdown.
sub SDL_AppQuit ( $appstate, $result ) {

    # SDL will clean up the window/renderer for us, MIX_Quit() destroys any mixer objects we made.
    MIX_Quit();
}
