# TODO.md

This is an evolving list of things I need to remind myself to complete or revisit before I consider the project stable

## Thread Safety

   - [ ] `SDL_AudioCallback` inside SDL2::AudioSpec (see `eg/play_sound.pl` for test)
   - [ ] `SDL_AddCallback` tips over when event loop triggers it; works inside `SDL_Delay( ... )` so don't be fooled
