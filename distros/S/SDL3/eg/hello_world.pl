use v5.40;
use lib '../lib';
use SDL3 qw[:all :main];
$|++;
#
my ( $window, $renderer, %mouseposrect );
#
sub SDL_AppIterate($appstate) {

    # fade between shades of red every 3 seconds, from 0 to 255.
    my $r = ( ( ( ( SDL_GetTicks() % 3000 ) ) / 3000.0 ) * 255.0 );
    SDL_SetRenderDrawColor( $renderer, $r, 0, 0, 255 );

    # you have to draw the whole window every frame. Clearing it makes sure the whole thing is sane.
    SDL_RenderClear($renderer);    # clear whole window to that fade color.

    # set the color to white
    SDL_SetRenderDrawColor( $renderer, 255, 255, 255, 255 );

    # draw a square where the mouse cursor currently is.
    SDL_RenderFillRect( $renderer, \%mouseposrect );

    # put everything we drew to the screen.
    SDL_RenderPresent($renderer);
    #
    return SDL_APP_CONTINUE;
}

sub SDL_AppEvent( $appstate, $event ) {

    # triggers on last window close and other things. End the program.
    return SDL_APP_SUCCESS if $event->{type} == SDL_EVENT_QUIT;

    # quit if user hits ESC key
    return SDL_APP_SUCCESS if $event->{type} == SDL_EVENT_KEY_DOWN && $event->{key}{scancode} == SDL_SCANCODE_ESCAPE;

    # keep track of the last mouse position
    if ( $event->{type} == SDL_EVENT_MOUSE_MOTION ) {

        # center the square where the mouse is
        $mouseposrect{x} = $event->{motion}{x} - ( $mouseposrect{w} / 2 );
        $mouseposrect{y} = $event->{motion}{y} - ( $mouseposrect{h} / 2 );
    }
    return SDL_APP_CONTINUE;
}

sub SDL_AppInit( $appstate, $argc, $argv ) {
    SDL_SetAppMetadata( 'SDL Hello World Example', '1.0', 'com.example.sdl-hello-world' );
    if ( !SDL_Init(SDL_INIT_VIDEO) ) {
        SDL_Log( 'SDL_Init(SDL_INIT_VIDEO) failed: %s', SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    if ( !SDL_CreateWindowAndRenderer( 'Hello SDL', 640, 480, SDL_WINDOW_RESIZABLE, \$window, \$renderer ) ) {
        SDL_Log( sprintf 'SDL_CreateWindowAndRenderer() failed: %s', SDL_GetError() );
        return SDL_APP_FAILURE;
    }
    #
    $mouseposrect{x} = $mouseposrect{y} = -1000;    # -1000 so it's offscreen at start
    $mouseposrect{w} = $mouseposrect{h} = 50;
    return SDL_APP_CONTINUE;
}

sub SDL_AppQuit( $appstate, $result ) {
    SDL_DestroyRenderer($renderer);
    SDL_DestroyWindow($window);
    SDL_Quit();
}
__END__
Based on https://github.com/libsdl-org/SDL_helloworld
