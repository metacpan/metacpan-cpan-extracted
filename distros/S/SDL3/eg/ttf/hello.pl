use lib '../../lib';
use v5.40;
use SDL3      qw[:all :main];
use SDL3::TTF qw[:all];
my ( $window, $renderer, $texture, $font );

# Runs once at startup
sub SDL_AppInit ( $appstate, $argc, $argv ) {
    my $color = { r => rand 255, g => rand 255, b => rand 255, a => SDL_ALPHA_OPAQUE };

    # Create window and renderer
    if ( !SDL_CreateWindowAndRenderer( 'Hello, World', 800, 600, 0, $window, $renderer ) ) {
        SDL_Log( "Couldn't create window and renderer: %s\n", SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    if ( !TTF_Init() ) {
        SDL_Log( "Couldn't initialize SDL_ttf: %s\n", SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    #
    $font = TTF_OpenFont(
        $^O eq 'MSWin32'    ? 'C:/Windows/Fonts/arial.ttf' :             # Windows
            $^O eq 'darwin' ? '/System/Library/Fonts/Helvetica.ttc' :    # macOS
            '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'            # Linux, etc. (ugh...)
        , 48.0
    );
    if ( !$font ) {
        SDL_Log( "Couldn't open font: %s\n", SDL_GetError() );
        return SDL_APP_FAILURE;
    }

    # Render text surface and convert to texture
    my $text = TTF_RenderText_Blended( $font, 'Hello, World!', 0, $color );
    if ($text) {
        $texture = SDL_CreateTextureFromSurface( $renderer, $text );
        SDL_DestroySurface($text);
    }
    if ( !$texture ) {
        SDL_Log( "Couldn't create text: %s\n", SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    return SDL_APP_CONTINUE;
}

# Runs on input/events
sub SDL_AppEvent ( $appstate, $event ) {
    return SDL_APP_SUCCESS if $event->{type} == SDL_EVENT_KEY_DOWN || $event->{type} == SDL_EVENT_QUIT;
    return SDL_APP_CONTINUE;
}

# Runs once per frame
sub SDL_AppIterate ($appstate) {
    my ( $w,  $h )  = ( 0, 0 );
    my ( $tw, $th ) = ( 0, 0 );
    my $scale = 1.0;
    SDL_GetRenderOutputSize( $renderer, \$w, \$h );
    SDL_SetRenderScale( $renderer, $scale, $scale );
    SDL_GetTextureSize( $texture, \$tw, \$th );
    my $dst = { w => $tw, h => $th, x => ( ( $w / $scale ) - $tw ) / 2, y => ( ( $h / $scale ) - $th ) / 2, };
    SDL_SetRenderDrawColor( $renderer, 0, 0, 0, 255 );
    SDL_RenderClear($renderer);
    SDL_RenderTexture( $renderer, $texture, undef, $dst );
    SDL_RenderPresent($renderer);
    return SDL_APP_CONTINUE;
}

# Runs at shutdown
sub SDL_AppQuit ( $appstate, $result ) {
    TTF_CloseFont($font) if $font;
    TTF_Quit();
}
