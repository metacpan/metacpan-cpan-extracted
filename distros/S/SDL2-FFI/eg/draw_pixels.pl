use strictures 2;
use lib '../lib';
use SDL2::FFI qw[:all];

# https://gigi.nullneuron.net/gigilabs/sdl2-pixel-drawing/
my $quit  = 0;
my $event = SDL2::Event->new();
SDL_Init(SDL_INIT_VIDEO);
my $window = SDL_CreateWindow( "SDL2 Pixel Drawing",
    SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 640, 480, 0 );
my $renderer = SDL_CreateRenderer( $window, -1, 0 );
my $texture
    = SDL_CreateTexture( $renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STATIC, 640, 480 );
my @pixels;
my $drawing = 0;

while ( !$quit ) {
    SDL_WaitEventTimeout( $event, 10 );
    if ( $event->type == SDL_QUIT ) {
        $quit = 1;
    }
    elsif ( $event->type == SDL_MOUSEBUTTONDOWN && $event->button->button == SDL_BUTTON_LEFT ) {
        $drawing = 1;
    }
    elsif ( $event->type == SDL_MOUSEBUTTONUP && $event->button->button == SDL_BUTTON_LEFT ) {
        $drawing = 0;
    }
    elsif ( $event->type == SDL_MOUSEMOTION && $drawing ) {
        push @pixels,    #{x => $event->motion->x, y => $event->motion->y};
            SDL2::Point->new( { x => $event->motion->x, y => $event->motion->y } );

        #warn sprintf 'x: %d * y: %d', $pixels[-1]->x, $pixels[-1]->y;
    }
    SDL_SetRenderDrawColor( $renderer, 242, 242, 242, 255 );
    SDL_RenderClear($renderer);
    CORE::state $i  = 0;
    CORE::state $up = 1;
    $up = -1 if $i >= 255;
    $up = 1  if $i <= 0;
    $i += $up;
    SDL_SetRenderDrawColor( $renderer, $i, 128, 128, 255 );
    SDL_RenderDrawPoints( $renderer, @pixels ) if @pixels;

    #warn SDL_GetError() if @pixels;
    SDL_RenderPresent($renderer);
}
SDL_DestroyRenderer($renderer);
SDL_DestroyWindow($window);
SDL_Quit();
exit 0;
