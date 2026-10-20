use lib '../../lib';
use v5.40;
use SDL3      qw[:all :main];
use SDL3::TTF qw[:all];

# Port of SDL_ttf's examples/showfps.
#
# Draws a live frames-per-second counter using a TTF_Text object held on a
# renderer text engine. The text is updated once per second and re-centered
# every frame using TTF_GetTextSize. The upstream demo embeds a tiny 4px
# font; here we just use a system font at a readable size.
#
# Press any key or close the window to quit.
my ( $window, $renderer, $font, $engine, $text );
my $frames     = 0;
my $last_check = 0;

# Pick a font that exists on this platform.
sub system_font {
    my @candidates = (
        $^O eq 'MSWin32' ? 'C:/Windows/Fonts/arial.ttf' : (), $^O eq 'darwin' ? '/System/Library/Fonts/Helvetica.ttc' : (),
        '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',    '/usr/share/fonts/TTF/DejaVuSans.ttf',
    );
    for my $path (@candidates) {
        return $path if -e $path;
    }
    return $candidates[-1];
}

# This function runs once at startup.
sub SDL_AppInit ( $appstate, $argc, $argv ) {
    my $font_path = system_font();
    if ( !SDL_CreateWindowAndRenderer( 'FPS counter', 800, 600, SDL_WINDOW_RESIZABLE, $window, $renderer ) ) {
        SDL_Log( q[Couldn't create window and renderer: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    if ( !TTF_Init() ) {
        SDL_Log( q[Couldn't initialize SDL_ttf: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    $font = TTF_OpenFont( $font_path, 72.0 );
    if ( !$font ) {
        SDL_Log( q[Couldn't open font %s: %s], $font_path, SDL_GetError() );
        return SDL_APP_FAILURE;
    }

    # A renderer text engine lets us draw (and re-draw) text directly, without
    # creating a new surface/texture each time the string changes.
    $engine = TTF_CreateRendererTextEngine($renderer);
    if ( !$engine ) {
        SDL_Log( q[Couldn't create text engine: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    $text = TTF_CreateText( $engine, $font, 'Calculating...', 0 );
    if ( !$text ) {
        SDL_Log( q[Couldn't create text: %s], SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    TTF_SetTextColor( $text, 255, 255, 255, SDL_ALPHA_OPAQUE );
    $last_check = SDL_GetTicks();
    return SDL_APP_CONTINUE;
}

# This function runs when a new event (mouse input, keypresses, etc) occurs.
sub SDL_AppEvent ( $appstate, $event ) {
    my $type = $event->{type};
    return SDL_APP_SUCCESS if $type == SDL_EVENT_QUIT || $type == SDL_EVENT_KEY_DOWN;
    return SDL_APP_CONTINUE;
}

# This function runs once per frame, and is the heart of the program.
sub SDL_AppIterate ($appstate) {
    my $now = SDL_GetTicks();

    # Update the FPS once per second.
    if ( $now - $last_check >= 1000 ) {
        my $fps = $frames * 1000.0 / ( $now - $last_check );
        TTF_SetTextString( $text, sprintf( '%.2f', $fps ), 0 );
        $last_check = $now;
        $frames     = 0;
    }

    # Pretend to do lots of work so we have a reasonable FPS.
    SDL_Delay(16);

    # Center the text.
    my ( $w,      $h )      = ( 0, 0 );
    my ( $text_w, $text_h ) = ( 0, 0 );
    SDL_GetRenderOutputSize( $renderer, \$w, \$h );
    TTF_GetTextSize( $text, \$text_w, \$text_h );
    my $x = ( $w - $text_w ) / 2;
    my $y = ( $h - $text_h ) / 2;
    SDL_SetRenderDrawColor( $renderer, 0, 0, 0, 255 );
    SDL_RenderClear($renderer);
    TTF_DrawRendererText( $text, $x, $y );
    SDL_RenderPresent($renderer);
    $frames++;
    return SDL_APP_CONTINUE;
}

# This function runs once at shutdown.
sub SDL_AppQuit ( $appstate, $result ) {
    TTF_DestroyText($text)                 if $text;
    TTF_DestroyRendererTextEngine($engine) if $engine;
    TTF_CloseFont($font)                   if $font;
    TTF_Quit();
}
