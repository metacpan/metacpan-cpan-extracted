use v5.40;
use SDL3        qw[:all :main];
use SDL3::Image qw[:all];

# Port of SDL_image's examples/showclipboard.
#
# Displays whatever image is currently on the system clipboard. Copy an image
# from any other application and it appears here. The clipboard is re-checked
# whenever SDL_EVENT_CLIPBOARD_UPDATE fires.
#
# Press ESC/Q to quit.
my ( $window, $renderer, $texture );

# Draw a Gimpish checkerboard so transparency is visible.
sub draw_background ( ) {
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

# Grab the clipboard image (if any) and turn it into a texture.
sub load_clipboard () {
    SDL_DestroyTexture($texture) if $texture;
    $texture = undef;
    my $surface = IMG_GetClipboardImage();
    return unless $surface;
    my $text = SDL_GetClipboardText();
    SDL_SetWindowTitle( $window, ( $text && length $text ) ? $text : 'Copy an image and click here' );
    $texture = SDL_CreateTextureFromSurface( $renderer, $surface );
    my ( $w, $h ) = ( $surface->{w}, $surface->{h} );
    SDL_SetWindowSize( $window, $w, $h );
    SDL_SetRenderLogicalPresentation( $renderer, $w, $h, SDL_LOGICAL_PRESENTATION_LETTERBOX );
    SDL_DestroySurface($surface);
}

# This function runs once at startup.
sub SDL_AppInit ( $appstate, $argc, $argv ) {
    SDL_SetAppMetadata( 'Example Show Clipboard', '1.0', 'com.example.show-clipboard' );
    if ( !SDL_CreateWindowAndRenderer( '', 640, 480, SDL_WINDOW_RESIZABLE, $window, $renderer ) ) {
        SDL_Log( 'SDL_CreateWindowAndRenderer() failed: %s', SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    load_clipboard();
    return SDL_APP_CONTINUE;
}

# This function runs when a new event (mouse input, keypresses, etc) occurs.
sub SDL_AppEvent ( $appstate, $event ) {
    my $type = $event->{type};
    return SDL_APP_SUCCESS if $type == SDL_EVENT_QUIT;

    # Re-read the clipboard whenever it changes.
    load_clipboard() if $type == SDL_EVENT_CLIPBOARD_UPDATE;
    if ( $type == SDL_EVENT_KEY_DOWN ) {
        my $key = $event->{key}{key};
        return SDL_APP_SUCCESS if $key == SDLK_ESCAPE || $key == SDLK_Q;
    }
    return SDL_APP_CONTINUE;
}

# This function runs once per frame, and is the heart of the program.
sub SDL_AppIterate ($appstate) {
    draw_background();
    SDL_RenderTexture( $renderer, $texture, undef, undef ) if $texture;
    SDL_RenderPresent($renderer);

    # Nothing to animate; give up CPU between frames.
    SDL_Delay(100);
    return SDL_APP_CONTINUE;
}

# This function runs once at shutdown.
sub SDL_AppQuit ( $appstate, $result ) {
    SDL_DestroyTexture($texture) if $texture;
}
