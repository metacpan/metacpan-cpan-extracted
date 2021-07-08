use lib '../lib', './lib';
use SDL2::FFI qw[:all];
SDL_Init( SDL_INIT_VIDEO | SDL_INIT_AUDIO );
warn SDL_WasInit(SDL_INIT_TIMER);                     # false
warn SDL_WasInit(SDL_INIT_VIDEO);                     # true (32 == SDL_INIT_VIDEO)
my $mask = SDL_WasInit();
warn 'video init!'  if ( $mask & SDL_INIT_VIDEO );    # yep
warn 'video timer!' if ( $mask & SDL_INIT_TIMER );    # nope
