use v5.40;
use SDL3 qw[:all :main];
my ( $x, $y, $dx, $dy, $ren ) = ( 300, 200, 5, 5 );

sub SDL_AppInit( $app, $ac, $av ) {
    state $win;
    SDL_Init(SDL_INIT_VIDEO);
    SDL_CreateWindowAndRenderer( 'Bouncing Box', 640, 480, 0, \$win, \$ren );
    SDL_SetRenderVSync( $ren, 1 );
    SDL_APP_CONTINUE;
}

sub SDL_AppEvent( $app, $ev ) {
    $ev->{type} == SDL_EVENT_QUIT ? SDL_APP_SUCCESS : SDL_APP_CONTINUE;
}

sub SDL_AppIterate($app) {
    $dx *= -1 if $x <= 0 || $x >= 620;    # Bounce X (Window 640 - Rect 20)
    $dy *= -1 if $y <= 0 || $y >= 460;    # Bounce Y (Window 480 - Rect 20)
    $x  += $dx;
    $y  += $dy;
    SDL_SetRenderDrawColor( $ren, 20, 20, 30, 255 );
    SDL_RenderClear($ren);
    SDL_SetRenderDrawColor( $ren, int($x) % 255, int($y) % 255, 200, 255 );
    SDL_RenderFillRect( $ren, { x => $x, y => $y, w => 20, h => 20 } );
    SDL_RenderPresent($ren);
    SDL_APP_CONTINUE;
}
sub SDL_AppQuit { }
__END__
This is just a copy/paste of the main module's synopsis
