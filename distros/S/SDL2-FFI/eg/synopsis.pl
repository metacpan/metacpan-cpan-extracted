use lib '../lib';
use strict;
use warnings;
{
    use SDL2::FFI qw[:all];
    die 'Error initializing SDL: ' . SDL_GetError() unless SDL_Init(SDL_INIT_VIDEO) == 0;
    my $win = SDL_CreateWindow( 'Example window!',
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 640, 480, SDL_WINDOW_RESIZABLE );
    die 'Could not create window: ' . SDL_GetError() unless $win;
    my $event = SDL2::Event->new;
    SDL_Init(SDL_INIT_VIDEO);
    my $renderer = SDL_CreateRenderer( $win, -1, 0 );
    SDL_SetRenderDrawColor( $renderer, 242, 242, 242, 255 );
    do {
        SDL_WaitEventTimeout( $event, 10 );
        SDL_RenderClear($renderer);
        SDL_RenderPresent($renderer);
    } until $event->type == SDL_QUIT;
    SDL_DestroyRenderer($renderer);
    SDL_DestroyWindow($win);
    SDL_Quit();
}
