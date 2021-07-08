# Very rough example testing built-in BMP support
# Based on https://gamedev.stackexchange.com/questions/71990/render-two-images-to-an-sdl-window
use strictures 2;
use lib '../lib';
use SDL2::FFI qw[:all];
my $done       = 0;
my $event      = SDL2::Event->new;
my $button_pos = SDL2::Rect->new( { x => 0, y => 0, w => 320, h => 65 } );
SDL_Init(SDL_INIT_VIDEO);
END { SDL_QUIT() }
my $window = SDL_CreateWindow( 'Weird but okay',
    SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 320, 568, SDL_WINDOW_SHOWN );
my $renderer           = SDL_CreateRenderer( $window, -1, SDL_RENDERER_ACCELERATED );
my $background_surface = SDL_LoadBMP('output_1.bmp');
my $background_texture = SDL_CreateTextureFromSurface( $renderer, $background_surface );
my $button_surface     = SDL_LoadBMP('output_2.bmp');
my $button_texture     = SDL_CreateTextureFromSurface( $renderer, $button_surface );

while ( !$done ) {
    SDL_WaitEventTimeout( $event, 10 );
    $done = $event->type == SDL_QUIT;
    SDL_RenderClear($renderer);
    SDL_RenderCopy( $renderer, $background_texture, undef, undef );
    SDL_RenderCopy( $renderer, $button_texture,     undef, $button_pos );
    SDL_RenderPresent($renderer);
}
SDL_DestroyTexture($button_texture);
SDL_FreeSurface($button_surface);
SDL_DestroyRenderer($renderer);
SDL_DestroyTexture($background_texture);
SDL_FreeSurface($background_surface);
SDL_DestroyWindow($window);
SDL_Quit();
