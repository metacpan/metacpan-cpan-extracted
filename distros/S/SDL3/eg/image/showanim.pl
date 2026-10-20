use v5.40;
use SDL3        qw[:all :main];
use SDL3::Image qw[:all];

# Port of SDL_image's examples/showanim.
#
# Loads an animated image and plays it back frame by frame. Rather than reach
# into the IMG_Animation struct, this uses the streaming decoder API:
# IMG_CreateAnimationDecoder( ... ) opens the file and
# IMG_GetAnimationDecoderFrame( ... ) hands back one SDL_Surface and its
# delay at a time. We decode the whole animation up front into textures, then
# cycle through them using the per-frame delays.
#
# Press RIGHT/SPACE to restart the animation, ESC/Q to quit.
my @IMAGES = qw[rgbrgb.gif];
my ( $window,   $renderer );
my ( @textures, @delays );
my $count         = 0;
my $loop_count    = -1;
my $current_frame = 0;
my $played        = 0;
my $last_tick     = 0;

# Locate a bundled asset next to this script.
sub asset ($name) {
    my $dir = __FILE__ =~ s{[^/\\]+$}{}r;
    return $dir . 'assets/' . $name;
}

# Draw a Gimpish checkerboard so transparency is visible.
sub draw_background ($renderer) {
    my @col = ( [ 0x66, 0x66, 0x66, 0xFF ], [ 0x99, 0x99, 0x99, 0xFF ] );
    my $dx  = 8;
    my $dy  = 8;
    my ( $w, $h ) = ( 0, 0 );
    SDL_GetCurrentRenderOutputSize( $renderer, \$w, \$h );
    for ( my $y = 0; $y < $h; $y += $dy ) {
        for ( my $x = 0; $x < $w; $x += $dx ) {
            my $i = ( ( $x ^ $y ) >> 3 ) & 1;
            SDL_SetRenderDrawColor( $renderer, @{ $col[$i] } );
            SDL_RenderFillRect( $renderer, { x => $x, y => $y, w => $dx, h => $dy } );
        }
    }
}

# Decode every frame of the animation named in $file into textures.
sub load_animation ($file) {
    @textures      = ();
    @delays        = ();
    $count         = 0;
    $current_frame = 0;
    $played        = 0;
    my $decoder = IMG_CreateAnimationDecoder( asset($file) );
    if ( !$decoder ) {
        SDL_Log( q[Couldn't open %s: %s], $file, SDL_GetError() );
        return 0;
    }
    my ( $w, $h ) = ( 0, 0 );
    while (1) {
        my ( $surface, $delay ) = ( undef, 0 );
        IMG_GetAnimationDecoderFrame( $decoder, \$surface, \$delay );
        last unless $surface;    # NULL surface marks the end of the animation.
        ( $w, $h ) = ( $surface->{w}, $surface->{h} );
        my $texture = SDL_CreateTextureFromSurface( $renderer, $surface );

        # Remember the loop count from the first frame's metadata (-1 = forever).
        if ( !$count ) {
            $loop_count = SDL_GetNumberProperty( SDL_GetSurfaceProperties($surface), IMG_PROP_METADATA_LOOP_COUNT_NUMBER(), -1 );
        }
        push @textures, $texture;
        push @delays,   $delay || 100;
        $count++;
        SDL_DestroySurface($surface);
    }
    IMG_CloseAnimationDecoder($decoder);
    if ( !$count ) {
        SDL_Log( q[No frames decoded from %s: %s], $file, SDL_GetError() );
        return 0;
    }
    SDL_SetWindowTitle( $window, $file );
    SDL_SetWindowSize( $window, $w, $h );
    $last_tick = SDL_GetTicks();
    return 1;
}

# This function runs once at startup.
sub SDL_AppInit ( $appstate, $argc, $argv ) {
    SDL_SetAppMetadata( 'Example Show Animation', '1.0', 'com.example.show-animation' );
    if ( !SDL_CreateWindowAndRenderer( 'animation demo', 0, 0, SDL_WINDOW_RESIZABLE, $window, $renderer ) ) {
        SDL_Log( q[SDL_CreateWindowAndRenderer() failed: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }

    # Try each candidate until one decodes.
    for my $file (@IMAGES) {
        return SDL_APP_CONTINUE if load_animation($file);
    }
    return SDL_APP_FAILURE;
}

# This function runs when a new event (mouse input, keypresses, etc) occurs.
sub SDL_AppEvent ( $appstate, $event ) {
    my $type = $event->{type};
    return SDL_APP_SUCCESS if $type == SDL_EVENT_QUIT;
    if ( $type == SDL_EVENT_KEY_DOWN ) {
        my $key = $event->{key}{key};
        return SDL_APP_SUCCESS if $key == SDLK_ESCAPE || $key == SDLK_Q;
        if ( $key == SDLK_RIGHT || $key == SDLK_SPACE ) {
            $current_frame = 0;
            $played        = 0;
            $last_tick     = SDL_GetTicks();
        }
    }
    return SDL_APP_CONTINUE;
}

# This function runs once per frame, and is the heart of the program.
sub SDL_AppIterate ($appstate) {
    my $now = SDL_GetTicks();

    # Hold each frame for its own delay.
    if ( $now - $last_tick >= $delays[$current_frame] ) {
        $last_tick = $now;
        if ( $current_frame < $count - 1 ) {
            $current_frame++;
        }
        else {
            # Wrap around until we've reached the requested loop count.
            if ( $played != $loop_count - 1 ) {
                $played++;
                $current_frame = 0;
            }
        }
    }
    draw_background($renderer);
    SDL_RenderTexture( $renderer, $textures[$current_frame], undef, undef );
    SDL_RenderPresent($renderer);
    return SDL_APP_CONTINUE;
}

# This function runs once at shutdown.
sub SDL_AppQuit ( $appstate, $result ) {
    SDL_DestroyTexture($_) for @textures;
}
