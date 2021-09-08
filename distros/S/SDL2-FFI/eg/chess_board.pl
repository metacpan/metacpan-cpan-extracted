use strictures 2;
use lib '../lib';
use SDL2::FFI qw[:all];

#warn SDLK_KP_LEFTPAREN();
# Taken from example found here: https://wiki.libsdl.org/SDL_CreateSoftwareRenderer
# Globals
my ( $window, $renderer, $done );
my $id = SDL_AddTimer( 10000, sub {...} );

sub DrawChessBoard {
    my ($renderer) = @_;
    my ( $row, $column, $x );
    my $rect = SDL2::Rect->new;

    # Get the Size of drawing surface
    SDL_RenderGetViewport( $renderer, my $darea = SDL2::Rect->new() );
    for my $row ( 0 .. 7 ) {
        $column = $row % 2;
        $x      = $column;
        for ( ; $column < 4 + ( $row % 2 ); $column++ ) {
            SDL_SetRenderDrawColor( $renderer, 0, 0, 0, 0xFF );
            $rect = SDL2::Rect->new(
                {   w => $darea->w / 8,
                    h => $darea->h / 8,
                    x => $x * $rect->w,
                    y => $row * $rect->h
                }
            );
            $x = $x + 2;
            SDL_RenderFillRect( $renderer, $rect );
        }
    }
}

# Enable standard application logging
SDL_LogSetPriority( SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_INFO );

# Initialize SDL
if ( SDL_Init(SDL_INIT_VIDEO) != 0 ) {
    SDL_LogError( SDL_LOG_CATEGORY_APPLICATION, "SDL_Init fail : %s\n", SDL_GetError() );
    exit 1;
}

# Create window and renderer for given surface
$window
    = SDL_CreateWindow( "Chess Board", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 640, 480,
    0 );
if ( !$window ) {
    SDL_LogError( SDL_LOG_CATEGORY_APPLICATION, "Window creation fail : %s\n", SDL_GetError() );
    exit 1;
}
$renderer = SDL_CreateSoftwareRenderer( SDL_GetWindowSurface($window) );
if ( !$renderer ) {
    SDL_LogError( SDL_LOG_CATEGORY_APPLICATION, "Render creation for surface fail : %s\n",
        SDL_GetError() );
    exit 1;
}

# Clear the rendering surface with the specified color */
SDL_SetRenderDrawColor( $renderer, 0xFF, 0xFF, 0xFF, 0xFF );
SDL_RenderClear($renderer);

# Draw the Image on rendering surface */
$done = 0;
while ( !$done ) {
    while ( SDL_PollEvent( my $e = SDL2::Event->new ) ) {
        if ( $e->type == SDL_QUIT ) {
            $done = 1;
            exit;
        }
        elsif ( ( $e->type eq SDL_KEYDOWN ) && ( $e->key->keysym->sym == SDLK_ESCAPE ) ) {
            $done = 1;
            exit;
        }
    }
    DrawChessBoard($renderer);

    # Got everything on rendering surface,
    #  now Update the drawing image on window screen
    SDL_UpdateWindowSurface($window);
}
SDL_Quit();
exit 0;
