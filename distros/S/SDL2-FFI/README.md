[![Actions Status](https://github.com/sanko/SDL2.pm/workflows/CI/badge.svg)](https://github.com/sanko/SDL2.pm/actions) [![MetaCPAN Release](https://badge.fury.io/pl/SDL2-FFI.svg)](https://metacpan.org/release/SDL2-FFI)
# NAME

SDL2::FFI - FFI Wrapper for SDL (Simple DirectMedia Layer) Development Library

# SYNOPSIS

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

# DESCRIPTION

SDL2::FFI is an [FFI::Platypus](https://metacpan.org/pod/FFI%3A%3APlatypus) backed bindings to the **S**imple
**D**irectMedia **L**ayer - a cross-platform development library designed to
provide low level access to audio, keyboard, mouse, joystick, and graphics
hardware.

# Initialization and Shutdown

The functions in this category are used to set SDL up for use and generally
have global effects in your program. These functions may be imported with the
`:init` or `:default` tag.

## `SDL_Init( ... )`

Initializes the SDL library. This must be called before using most other SDL
functions.

        SDL_Init( SDL_INIT_TIMER | SDL_INIT_VIDEO | SDL_INIT_EVENTS );

`SDL_Init( ... )` simply forwards to calling [`SDL_InitSubSystem( ...
)`](#sdl_initsubsystem). Therefore, the two may be used
interchangeably. Though for readability of your code [`SDL_InitSubSystem(
... )`](#sdl_initsubsystem) might be preferred.

The file I/O (for example: `SDL_RWFromFile( ... )`) and threading
(`SDL_CreateThread( ... )`) subsystems are initialized by default. Message
boxes (`SDL_ShowSimpleMessageBox( ... )`) also attempt to work without
initializing the video subsystem, in hopes of being useful in showing an error
dialog when SDL\_Init fails. You must specifically initialize other subsystems
if you use them in your application.

Logging (such as `SDL_Log( ... )`) works without initialization, too.

Expected parameters include:

- `flags` which may be any be imported with the [`:init`](https://metacpan.org/pod/SDL2%3A%3AEnum#init) tag and may be OR'd together

Subsystem initialization is ref-counted, you must call [`SDL_QuitSubSystem(
... )`](#sdl_quitsubsystem) for each [`SDL_InitSubSystem( ...
)`](#sdl_initsubsystem) to correctly shutdown a subsystem manually
(or call [`SDL_Quit( )`](#sdl_quit) to force shutdown). If a
subsystem is already loaded then this call will increase the ref-count and
return.

Returns `0` on success or a negative error code on failure; call
`SDL_GetError( )` for more information.

## `SDL_InitSubSystem( ... )`

Compatibility function to initialize the SDL library.

In SDL2, this function and [`SDL_Init( ... )`](#sdl_init) are
interchangeable.

        SDL_InitSubSystem( SDL_INIT_TIMER | SDL_INIT_VIDEO | SDL_INIT_EVENTS );

Expected parameters include:

- `flags` which may be any be imported with the [`:init`](https://metacpan.org/pod/SDL2%3A%3AEnum#init) tag and may be OR'd together.

Returns `0` on success or a negative error code on failure; call
`SDL_GetError( )` for more information.

## `SDL_QuitSubSystem( ... )`

Shut down specific SDL subsystems.

        SDL_QuitSubSystem( SDL_INIT_VIDEO );

If you start a subsystem using a call to that subsystem's init function (for
example `SDL_VideoInit( )`) instead of [`SDL_Init( ... )`](#sdl_init) or [`SDL_InitSubSystem( ... )`](#sdl_initsubsystem), [`SDL_QuitSubSystem( ... )`](#sdl_quitsubsystem) and [`SDL_WasInit( ... )`](#sdl_wasinit) will not work. You will need to
use that subsystem's quit function (`SDL_VideoQuit( )` directly instead. But
generally, you should not be using those functions directly anyhow; use [`SDL_Init( ... )`](#sdl_init) instead.

You still need to call [`SDL_Quit( )`](#sdl_quit) even if you close
all open subsystems with [`SDL_QuitSubSystem( ... )`](#sdl_quitsubsystem).

Expected parameters include:

- `flags` which may be any be imported with the [`:init`](https://metacpan.org/pod/SDL2%3A%3AEnum#init) tag and may be OR'd together.

## `SDL_WasInit( ... )`

Get a mask of the specified subsystems which are currently initialized.

        SDL_Init( SDL_INIT_VIDEO | SDL_INIT_AUDIO );
        warn SDL_WasInit( SDL_INIT_TIMER ); # false
        warn SDL_WasInit( SDL_INIT_VIDEO ); # true (32 == SDL_INIT_VIDEO)
        my $mask = SDL_WasInit( );
        warn 'video init!'  if ($mask & SDL_INIT_VIDEO); # yep
        warn 'video timer!' if ($mask & SDL_INIT_TIMER); # nope

Expected parameters include:

- `flags` which may be any be imported with the [`:init`](https://metacpan.org/pod/SDL2%3A%3AEnum#init) tag and may be OR'd together.

If `flags` is `0`, it returns a mask of all initialized subsystems, otherwise
it returns the initialization status of the specified subsystems.

The return value does not include `SDL_INIT_NOPARACHUTE`.

## `SDL_Quit( )`

Clean up all initialized subsystems.

        SDL_Quit( );

You should call this function even if you have already shutdown each
initialized subsystem with `SDL_QuitSubSystem( )`. It is safe to call this
function even in the case of errors in initialization.

If you start a subsystem using a call to that subsystem's init function (for
example `SDL_VideoInit( )`) instead of [`SDL_Init( ... )`](#sdl_init) or [`SDL_InitSubSystem( ... )`](#sdl_initsubsystem), then
you must use that subsystem's quit function (`SDL_VideoQuit( )`) to shut it
down before calling `SDL_Quit( )`. But generally, you should not be using
those functions directly anyhow; use [`SDL_Init( ... )`](#sdl_init) instead.

You can use this function in an `END { ... }` block to ensure that it is run
when your application is shutdown.

# Defined Values and Enumerations

Defined values may be imported by name or with given tag.

## `SDL_INIT_*`

These are the flags which may be passed to `SDL_Init( ... )`.  You should
specify the subsystems which you will be using in your application. These may
be imported with the `:init` or `:default` tag.

- `SDL_INIT_TIMER`
- `SDL_INIT_AUDIO`
- `SDL_INIT_VIDEO` - `SDL_INIT_VIDEO` implies `SDL_INIT_EVENTS`
- `SDL_INIT_JOYSTICK` - `SDL_INIT_JOYSTICK` implies `SDL_INIT_EVENTS`
- `SDL_INIT_HAPTIC`
- `SDL_INIT_GAMECONTROLLER` - `SDL_INIT_GAMECONTROLLER` implies `SDL_INIT_JOYSTICK`
- `SDL_INIT_EVENTS`
- `SDL_INIT_SENSOR`
- `SDL_INIT_NOPARACHUTE` - compatibility; this flag is ignored
- `SDL_INIT_EVERYTHING`

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
