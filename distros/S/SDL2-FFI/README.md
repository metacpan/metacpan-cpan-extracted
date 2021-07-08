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

SDL2 is an FFI::Platypus-backed wrapper around the **S**imple **D**irectMedia
**L**ayer - a cross-platform development library designed to provide low level
access to audio, keyboard, mouse, joystick, and graphics hardware.

# Initialization and Shutdown

The functions in this category are used to set up SDL for use and generally
have global effects in your program. These functions may be imported with the
`:init` or `:default` tag.

## `SDL_Init( ... )`

Initialize the SDL library. This must be called before using most other SDL
functions.

        SDL_Init( SDL_INIT_TIMER | SDL_INIT_VIDEO | SDL_INIT_EVENTS );

`SDL_Init( ... )` simply forwards to calling [`SDL_InitSubSystem( ...
)`](#sdl_initsubsystem). Therefore, the two may be used
interchangeably. Though for readability of your code [`SDL_InitSubSystem(
... )`](#sdl_initsubsystem) might be preferred.

The file I/O (for example: [`SDL_RWFromFile( ... )`](#sdl_rwfromfile)) and threading ([`SDL_CreateThread( ... )`](#sdl_createthread)) subsystems are initialized by default. Message boxes ( [`SDL_ShowSimpleMessageBox( ... )`](#sdl_showsimplemessagebox) )
also attempt to work without initializing the video subsystem, in hopes of
being useful in showing an error dialog when SDL\_Init fails. You must
specifically initialize other subsystems if you use them in your application.

Logging (such as [`SDL_Log( ... )`](#sdl_log) ) works without
initialization, too.

Expected parameters include:

- `flags` which may be any be imported with the [`:init`](https://metacpan.org/pod/SDL2#init) tag and may be OR'd together

Subsystem initialization is ref-counted, you must call [`SDL_QuitSubSystem(
... )`](#sdl_quitsubsystem) for each [`SDL_InitSubSystem( ...
)`](#sdl_initsubsystem) to correctly shutdown a subsystem manually
(or call [`SDL_Quit( )`](#sdl_quit) to force shutdown). If a
subsystem is already loaded then this call will increase the ref-count and
return.

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_InitSubSystem( ... )`

Compatibility function to initialize the SDL library.

In SDL2, this function and [`SDL_Init( ... )`](#sdl_init) are
interchangeable.

        SDL_InitSubSystem( SDL_INIT_TIMER | SDL_INIT_VIDEO | SDL_INIT_EVENTS );

Expected parameters include:

- `flags` which may be any be imported with the [`:init`](https://metacpan.org/pod/SDL2#init) tag and may be OR'd together.

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_Quit( )`

Clean up all initialized subsystems.

        SDL_Quit( );

You should call this function even if you have already shutdown each
initialized subsystem with [`SDL_QuitSubSystem( )`](#sdl_quitsubsystem). It is safe to call this function even in the case of errors in
initialization.

If you start a subsystem using a call to that subsystem's init function (for
example [`SDL_VideoInit( )`](#sdl_videoinit)) instead of [`SDL_Init( ... )`](#sdl_init) or [`SDL_InitSubSystem( ...
)`](#sdl_initsubsystem), then you must use that subsystem's quit
function ([`SDL_VideoQuit( )`](#sdl_videoquit)) to shut it down
before calling `SDL_Quit( )`. But generally, you should not be using those
functions directly anyhow; use [`SDL_Init( ... )`](#sdl_init)
instead.

You can use this function in an `END { ... }` block to ensure that it is run
when your application is shutdown.

## `SDL_QuitSubSystem( ... )`

Shut down specific SDL subsystems.

        SDL_QuitSubSystem( SDL_INIT_VIDEO );

If you start a subsystem using a call to that subsystem's init function (for
example [`SDL_VideoInit( )` ](#sdl_videoinit)) instead of [`SDL_Init( ... )`](#sdl_init) or [`SDL_InitSubSystem( ...
)`](#sdl_initsubsystem), [`SDL_QuitSubSystem( ...
)`](#sdl_quitsubsystem) and [`SDL_WasInit( ...
)`](#sdl_wasinit) will not work. You will need to use that
subsystem's quit function ( [`SDL_VideoQuit( )`](#sdl_videoquit)
directly instead. But generally, you should not be using those functions
directly anyhow; use [`SDL_Init( ... )`](#sdl_init) instead.

You still need to call [`SDL_Quit( )`](#sdl_quit) even if you close
all open subsystems with [`SDL_QuitSubSystem( ... )`](#sdl_quitsubsystem).

Expected parameters include:

- `flags` which may be any be imported with the [`:init`](https://metacpan.org/pod/SDL2#init) tag and may be OR'd together.

## `SDL_WasInit( ... )`

Get a mask of the specified subsystems which are currently initialized.

        SDL_Init( SDL_INIT_VIDEO | SDL_INIT_AUDIO );
        warn SDL_WasInit( SDL_INIT_TIMER ); # false
        warn SDL_WasInit( SDL_INIT_VIDEO ); # true (32 == SDL_INIT_VIDEO)
        my $mask = SDL_WasInit( );
        warn 'video init!'  if ($mask & SDL_INIT_VIDEO); # yep
        warn 'video timer!' if ($mask & SDL_INIT_TIMER); # nope

Expected parameters include:

- `flags` which may be any be imported with the [`:init`](https://metacpan.org/pod/SDL2#init) tag and may be OR'd together.

If `flags` is `0`, it returns a mask of all initialized subsystems, otherwise
it returns the initialization status of the specified subsystems.

The return value does not include `SDL_INIT_NOPARACHUTE`.

# Configuration Variables

This category contains functions to set and get configuration hints, as well as
listing each of them alphabetically.

The convention for naming hints is `SDL_HINT_X`, where `SDL_X` is the
environment variable that can be used to override the default.

In general these hints are just that - they may or may not be supported or
applicable on any given platform, but they provide a way for an application or
user to give the library a hint as to how they would like the library to work.

## `SDL_SetHintWithPriority( ... )`

Set a hint with a specific priority.

        SDL_SetHintWithPriority( SDL_EVENT_LOGGING, 2, SDL_HINT_OVERRIDE );

The priority controls the behavior when setting a hint that already has a
value. Hints will replace existing hints of their priority and lower.
Environment variables are considered to have override priority.

Expected parameters include:

- `name`

    the hint to set

- `value`

    the value of the hint variable

- `priority`

    the priority level for the hint

Returns a true if the hint was set, untrue otherwise.

## `SDL_SetHint( ... )`

Set a hint with normal priority.

        SDL_SetHint( SDL_HINT_XINPUT_ENABLED, 1 );

Hints will not be set if there is an existing override hint or environment
variable that takes precedence. You can use SDL\_SetHintWithPriority( ) to set
the hint with override priority instead.

Expected parameters:

- `name`

    the hint to set

- `value`

    the value of the hint variable

Returns a true value if the hint was set, untrue otherwise.

## `SDL_GetHint( ... )`

Get the value of a hint.

        SDL_GetHint( SDL_HINT_XINPUT_ENABLED );

Expected parameters:

- `name`

    the hint to query

Returns the string value of a hint or an undefined value if the hint isn't set.

## `SDL_GetHintBoolean( ... )`

Get the boolean value of a hint variable.

        SDL_GetHintBoolean( SDL_HINT_XINPUT_ENABLED, 0);

Expected parameters:

- `name`

    the name of the hint to get the boolean value from

- `default_value`

    the value to return if the hint does not exist

Returns the boolean value of a hint or the provided default value if the hint
does not exist.

## `SDL_AddHintCallback( ... )`

Add a function to watch a particular hint.

        my $cb = SDL_AddHintCallback(
                SDL_HINT_XINPUT_ENABLED,
                sub {
                        my ($userdata, $name, $oldvalue, $newvalue) = @_;
                        ...;
                },
                { time => time( ), clicks => 3 }
        );

Expected parameters:

- `name`

    the hint to watch

- `callback`

    a code reference that will be called when the hint value changes

- `userdata`

    a pointer to pass to the callback function

Returns a pointer to a [FFI::Platypus::Closure](https://metacpan.org/pod/FFI%3A%3APlatypus%3A%3AClosure) which you may pass to [`SDL_DelHintCallback( ... )`](#sdl_delhintcallback).

## `SDL_DelHintCallback( ... )`

Remove a callback watching a particular hint.

        SDL_AddHintCallback(
                SDL_HINT_XINPUT_ENABLED,
                $cb,
                { time => time( ), clicks => 3 }
        );

Expected parameters:

- `name`

    the hint to watch

- `callback`

    [FFI::Platypus::Closure](https://metacpan.org/pod/FFI%3A%3APlatypus%3A%3AClosure) object returned by [`SDL_AddHintCallback( ...
    )`](#sdl_addhintcallback)

- `userdata`

    a pointer to pass to the callback function

## `SDL_ClearHints( )`

Clear all hints.

        SDL_ClearHints( );

This function is automatically called during [`SDL_Quit( )`](#sdl_quit).

# Error Handling

Functions in this category provide simple error message routines for SDL. [`SDL_GetError( )`](#sdl_geterror) can be called for almost all SDL
functions to determine what problems are occurring. Check the wiki page of each
specific SDL function to see whether [`SDL_GetError( )`](#sdl_geterror) is meaningful for them or not.

The SDL error messages are in English.

## `SDL_SetError( ... )`

Set the SDL error message for the current thread.

Calling this function will replace any previous error message that was set.

This function always returns `-1`, since SDL frequently uses `-1` to signify
an failing result, leading to this idiom:

        if ($error_code) {
                return SDL_SetError( 'This operation has failed: %d', $error_code );
        }

Expected parameters:

- `fmt`

    a `printf( )`-style message format string

- `@params`

    additional parameters matching % tokens in the `fmt` string, if any

## `SDL_GetError( )`

Retrieve a message about the last error that occurred on the current thread.

        warn SDL_GetError( );

It is possible for multiple errors to occur before calling `SDL_GetError( )`.
Only the last error is returned.

The message is only applicable when an SDL function has signaled an error. You
must check the return values of SDL function calls to determine when to
appropriately call `SDL_GetError( )`. You should **not** use the results of
`SDL_GetError( )` to decide if an error has occurred! Sometimes SDL will set
an error string even when reporting success.

SDL will **not** clear the error string for successful API calls. You **must**
check return values for failure cases before you can assume the error string
applies.

Error strings are set per-thread, so an error set in a different thread will
not interfere with the current thread's operation.

The returned string is internally allocated and must not be freed by the
application.

Returns a message with information about the specific error that occurred, or
an empty string if there hasn't been an error message set since the last call
to [`SDL_ClearError( )`](#sdl_clearerror). The message is only
applicable when an SDL function has signaled an error. You must check the
return values of SDL function calls to determine when to appropriately call
`SDL_GetError( )`.

## `SDL_GetErrorMsg( ... )`

Get the last error message that was set for the current thread.

        my $x;
        warn SDL_GetErrorMsg($x, 300);

This allows the caller to copy the error string into a provided buffer, but
otherwise operates exactly the same as [`SDL_GetError( )`](#sdl_geterror).

- `errstr`

    A buffer to fill with the last error message that was set for the current
    thread

- `maxlen`

    The size of the buffer pointed to by the errstr parameter

Returns the pointer passed in as the `errstr` parameter.

## `SDL_ClearError( )`

Clear any previous error message for this thread.

# Log Handling

Simple log messages with categories and priorities.

By default, logs are quiet but if you're debugging SDL you might want:

        SDL_LogSetAllPriority( SDL_LOG_PRIORITY_WARN );

Here's where the messages go on different platforms:

        Windows         debug output stream
        Android         log output
        Others          standard error output (STDERR)

Messages longer than the maximum size (4096 bytes) will be truncated.

## `SDL_LogSetAllPriority( ... )`

Set the priority of all log categories.

        SDL_LogSetAllPriority( SDL_LOG_PRIORITY_WARN );

Expected parameters:

- `priority`

    The SDL\_LogPriority to assign. These may be imported with the [`:logpriority`](#logpriority) tag.

## `SDL_LogSetPriority( ... )`

Set the priority of all log categories.

        SDL_LogSetPriority( SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_WARN );

Expected parameters:

- `category`

    The category to assign a priority to. These may be imported with the [`:logcategory`](#logcategory) tag.

- `priority`

    The SDL\_LogPriority to assign. These may be imported with the [`:logpriority`](#logpriority) tag.

## `SDL_LogGetPriority( ... )`

Get the priority of a particular log category.

        SDL_LogGetPriority( SDL_LOG_CATEGORY_ERROR );

Expected parameters:

- `category`

    The SDL\_LogCategory to query. These may be imported with the [`:logcategory`](#logcategory) tag.

## `SDL_LogGetPriority( ... )`

Get the priority of a particular log category.

        SDL_LogGetPriority( SDL_LOG_CATEGORY_ERROR );

Expected parameters:

- `category`

    The SDL\_LogCategory to query. These may be imported with the [`:logcategory`](#logcategory) tag.

## `SDL_LogResetPriorities( )`

Reset all priorities to default.

        SDL_LogResetPriorities( );

This is called by [`SDL_Quit( )`](#sdl_quit).

## `SDL_Log( ... )`

Log a message with `SDL_LOG_CATEGORY_APPLICATION` and
`SDL_LOG_PRIORITY_INFO`.

        SDL_Log( 'HTTP Status: %s', $http->status );

Expected parameters:

- `fmt`

    A `sprintf( )` style message format string.

- `...`

    Any additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogVerbose( ... )`

Log a message with `SDL_LOG_PRIORITY_VERBOSE`.

        SDL_LogVerbose( 'Current time: %s [%ds exec]', +localtime( ), time - $^T );

Expected parameters:

- `category`

    The category of the message.

- `fmt`

    A `sprintf( )` style message format string.

- `...`

    Additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogDebug( ... )`

Log a message with `SDL_LOG_PRIORITY_DEBUG`.

        SDL_LogDebug( 'Current time: %s [%ds exec]', +localtime( ), time - $^T );

Expected parameters:

- `category`

    The category of the message.

- `fmt`

    A `sprintf( )` style message format string.

- `...`

    Additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogInfo( ... )`

Log a message with `SDL_LOG_PRIORITY_INFO`.

        SDL_LogInfo( 'Current time: %s [%ds exec]', +localtime( ), time - $^T );

Expected parameters:

- `category`

    The category of the message.

- `fmt`

    A `sprintf( )` style message format string.

- `...`

    Additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogWarn( ... )`

Log a message with `SDL_LOG_PRIORITY_WARN`.

        SDL_LogWarn( 'Current time: %s [%ds exec]', +localtime( ), time - $^T );

Expected parameters:

- `category`

    The category of the message.

- `fmt`

    A `sprintf( )` style message format string.

- `...`

    Additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogError( ... )`

Log a message with `SDL_LOG_PRIORITY_ERROR`.

        SDL_LogError( 'Current time: %s [%ds exec]', +localtime( ), time - $^T );

Expected parameters:

- `category`

    The category of the message.

- `fmt`

    A `sprintf( )` style message format string.

- `...`

    Additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogCritical( ... )`

Log a message with `SDL_LOG_PRIORITY_CRITICAL`.

        SDL_LogCritical( 'Current time: %s [%ds exec]', +localtime( ), time - $^T );

Expected parameters:

- `category`

    The category of the message.

- `fmt`

    A `sprintf( )` style message format string.

- `...`

    Additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogMessage( ... )`

Log a message with the specified category and priority.

        SDL_LogMessage( SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_CRITICAL,
                                        'Current time: %s [%ds exec]', +localtime( ), time - $^T );

Expected parameters:

- `category`

    The category of the message.

- `priority`

    The priority of the message.

- `fmt`

    A `sprintf( )` style message format string.

- `...`

    Additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogSetOutputFunction( ... )`

Replace the default log output function with one of your own.

        my $cb = SDL_LogSetOutputFunction( sub { ... }, {} );

Expected parameters:

- `callback`

    A coderef to call instead of the default callback.

    This coderef should expect the following parameters:

    - `userdata`

        What was passed as `userdata` to `SDL_LogSetOutputFunction( )`.

    - `category`

        The category of the message.

    - `priority`

        The priority of the message.

    - `message`

        The message being output.

- `userdata`

    Data passed to the `callback`.

# Querying SDL Version

These functions are used to collect or display information about the version of
SDL that is currently being used by the program or that it was compiled
against.

The version consists of three segments (`X.Y.Z`)

- X - Major Version, which increments with massive changes, additions, and enhancements
- Y - Minor Version, which increments with backwards-compatible changes to the major revision
- Z - Patchlevel, which increments with fixes to the minor revision

Example: The first version of SDL 2 was 2.0.0

The version may also be reported as a 4-digit numeric value where the thousands
place represents the major version, the hundreds place represents the minor
version, and the tens and ones places represent the patchlevel (update
version).

Example: The first version number of SDL 2 was 2000

## `SDL_GetVersion( ... )`

Get the version of SDL that is linked against your program.

        my $ver = SDL2::Version->new;
        SDL_GetVersion( $ver );

This function may be called safely at any time, even before [`SDL_Init(
)`](#sdl_init).

Expected parameters include:

- `version` - An SDL2::Version object which will be filled with the proper values

# Display and Window Management

This category contains functions for handling display and window actions.

These functions may be imported with the `:video` tag.

## `SDL_GetNumVideoDrivers( )`

        my $num = SDL_GetNumVideoDrivers( );

Get the number of video drivers compiled into SDL.

Returns a number >= 1 on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_GetVideoDriver( ... )`

Get the name of a built in video driver.

    CORE::say SDL_GetVideoDriver($_) for 0 .. SDL_GetNumVideoDrivers( ) - 1;

The video drivers are presented in the order in which they are normally checked
during initialization.

Expected parameters include:

- `index` - the index of a video driver

Returns the name of the video driver with the given `index`.

## `SDL_VideoInit( ... )`

Initialize the video subsystem, optionally specifying a video driver.

        SDL_VideoInit( 'x11' );

This function initializes the video subsystem, setting up a connection to the
window manager, etc, and determines the available display modes and pixel
formats, but does not initialize a window or graphics mode.

If you use this function and you haven't used the SDL\_INIT\_VIDEO flag with
either SDL\_Init( ) or SDL\_InitSubSystem( ), you should call SDL\_VideoQuit( )
before calling SDL\_Quit( ).

It is safe to call this function multiple times. SDL\_VideoInit( ) will call
SDL\_VideoQuit( ) itself if the video subsystem has already been initialized.

You can use SDL\_GetNumVideoDrivers( ) and SDL\_GetVideoDriver( ) to find a
specific \`driver\_name\`.

Expected parameters include:

- `driver_name` - the name of a video driver to initialize, or undef for the default driver

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_VideoQuit( )`

Shut down the video subsystem, if initialized with [`SDL_VideoInit(
)`](#sdl_videoinit).

        SDL_VideoQuit( );

This function closes all windows, and restores the original video mode.

## `SDL_GetCurrentVideoDriver( )`

Get the name of the currently initialized video driver.

        my $driver = SDL_GetCurrentVideoDriver( );

Returns the name of the current video driver or NULL if no driver has been
initialized.

## `SDL_GetNumVideoDisplays( )`

Get the number of available video displays.

        my $screens = SDL_GetNumVideoDisplays( );

Returns a number >= 1 or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_GetDisplayName( ... )`

Get the name of a display in UTF-8 encoding.

        my $screen = SDL_GetDisplayName( 0 );

Expected parameters include:

- `displayIndex` - the index of display from which the name should be queried

Returns the name of a display or undefined for an invalid display index or
failure; call [`SDL_GetError( )`](#sdl_geterror) for more
information.

## `SDL_GetDisplayBounds( ... )`

Get the desktop area represented by a display.

        my $rect = SDL_GetDisplayBounds( 0 );

The primary display (`displayIndex == 0`) is always located at 0,0.

Expected parameters include:

- `displayIndex` - the index of the display to query

Returns the SDL2::Rect structure filled in with the display bounds on success
or a negative error code on failure; call [`SDL_GetError(
)`](#sdl_geterror) for more information.

## `SDL_GetDisplayUsableBounds( ... )`

Get the usable desktop area represented by a display.

        my $rect = SDL_GetDisplayUsableBounds( 0 );

The primary display (`displayIndex == 0`) is always located at 0,0.

This is the same area as [`SDL_GetDisplayBounds( ...
)`](#sdl_getdisplaybounds) reports, but with portions reserved by
the system removed. For example, on Apple's macOS, this subtracts the area
occupied by the menu bar and dock.

Setting a window to be fullscreen generally bypasses these unusable areas, so
these are good guidelines for the maximum space available to a non-fullscreen
window.

Expected parameters include:

- `displayIndex` - the index of the display to query

Returns the SDL2::Rect structure filled in with the display bounds on success
or a negative error code on failure; call [`SDL_GetError(
)`](#sdl_geterror) for more information. This function also returns
`-1` if the parameter `displayIndex` is out of range.

## `SDL_GetDisplayDPI( ... )`

Get the dots/pixels-per-inch for a display.

        my ( $ddpi, $hdpi, $vdpi ) = SDL_GetDisplayDPI( 0 );

Diagonal, horizontal and vertical DPI can all be optionally returned if the
appropriate parameter is non-NULL.

A failure of this function usually means that either no DPI information is
available or the `displayIndex` is out of range.

Expected parameters include:

- `displayIndex` - the index of the display from which DPI information should be queried

Returns `[ddpi, hdpi, vdip]` on success or a negative error code on failure;
call [`SDL_GetError( )`](#sdl_geterror) for more information.

`ddpi` is the diagonal DPI of the display, `hdpi` is the horizontal DPI of
the display, `vdpi` is the vertical DPI of the display.

## `SDL_GetDisplayOrientation( ... )`

Get the orientation of a display.

        my $orientation = SDL_GetDisplayOrientation( 0 );

Expected parameters include:

- `displayIndex` - the index of the display to query

Returns a value which may be imported with `:displayOrientation` or
`SDL_ORIENTATION_UNKNOWN` if it isn't available.

## `SDL_GetNumDisplayModes( ... )`

Get the number of available display modes.

        my $modes = SDL_GetNumDisplayModes( 0 );

The `displayIndex` needs to be in the range from `0` to
`SDL_GetNumVideoDisplays( ) - 1`.

Expected parameters include:

- `displayIndex` - the index of the display to query

Returns a number >= 1 on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_GetDisplayMode( ... )`

Get information about a specific display mode.

        my $mode = SDL_GetDisplayMode( 0, 0 );

The display modes are sorted in this priority:

- width - largest to smallest
- height - largest to smallest
- bits per pixel - more colors to fewer colors
- packed pixel layout - largest to smallest
- refresh rate - highest to lowest

Expected parameters include:

- `displayIndex` - the index of the display to query
- `modeIndex` - the index of the display mode to query

Returns an [SDL2::DisplayMode](https://metacpan.org/pod/SDL2%3A%3ADisplayMode) structure filled in with the mode at
`modeIndex` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_GetDesktopDisplayMode( ... )`

Get information about the desktop's display mode.

        my $mode = SDL_GetDesktopDisplayMode( 0 );

There's a difference between this function and [`SDL_GetCurrentDisplayMode(
... )`](#sdl_getcurrentdisplaymode) when SDL runs fullscreen and has
changed the resolution. In that case this function will return the previous
native display mode, and not the current display mode.

Expected parameters include:

- `displayIndex` - the index of the display to query

Returns an [SDL2::DisplayMode](https://metacpan.org/pod/SDL2%3A%3ADisplayMode) structure filled in with the current display
mode on success or a negative error code on failure; call [`SDL_GetError(
)`](#sdl_geterror) for more information.

## `SDL_GetCurrentDisplayMode( ... )`

        my $mode = SDL_GetCurrentDisplayMode( 0 );

There's a difference between this function and [`SDL_GetDesktopDisplayMode(
... )`](#sdl_getdesktopdisplaymode) when SDL runs fullscreen and has
changed the resolution. In that case this function will return the current
display mode, and not the previous native display mode.

Expected parameters include:

- `displayIndex` - the index of the display to query

Returns an [SDL2::DisplayMode](https://metacpan.org/pod/SDL2%3A%3ADisplayMode) structure filled in with the current display
mode on success or a negative error code on failure; call [`SDL_GetError(
)`](#sdl_geterror) for more information.

## `SDL_GetClosestDisplayMode( ... )`

Get the closes match to the requested display mode.

        $mode = SDL_GetClosestDisplayMode( 0, $mode );

The available display modes are scanned and he closest mode matching the
requested mode is returned. The mode format and refresh rate default to the
desktop mode if they are set to 0. The modes are scanned with size being first
priority, format being second priority, and finally checking the refresh rate.
If all the available modes are too small, then an undefined value is returned.

Expected parameters include:

- `displayIndex` - index of the display to query
- `mode` - an [SDL2::DisplayMode](https://metacpan.org/pod/SDL2%3A%3ADisplayMode) structure containing the desired display mode
- `closest` - an [SDL2::DisplayMode](https://metacpan.org/pod/SDL2%3A%3ADisplayMode) structure filled in with the closest match of the available display modes

Returns the passed in value `closest` or an undefined value if no matching
video mode was available; call [`SDL_GetError( )`](#sdl_geterror)
for more information.

## `SDL_GetWindowDisplayIndex( ... )`

Get the index of the display associated with a window.

        my $index = SDL_GetWindowDisplayIndex( $window );

Expected parameters include:

- `window`	- the window to query

Returns the index of the display containing the center of the window on success
or a negative error code on failure; call  [`SDL_GetError(
)`](#sdl_geterror) for more information.

## `SDL_SetWindowDisplayMode( ... )`

Set the display mode to use when a window is visible at fullscreen.

        my $ok = !SDL_SetWindowDisplayMode( $window, $mode );

This only affects the display mode used when the window is fullscreen. To
change the window size when the window is not fullscreen, use [`SDL_SetWindowSize( ... )`](#sdl_setwindowsize).

## `SDL_GetWindowDisplayMode( ... )`

Query the display mode to use when a window is visible at fullscreen.

        my $mode = SDL_GetWindowDisplayMode( $window );

Expected parameters include:

- `window` - the window to query

Returns a [SDL2::DisplayMode](https://metacpan.org/pod/SDL2%3A%3ADisplayMode) structure on success or a negative error code on
failure; call [`SDL_GetError( )`](#sdl_geterror) for more
information.

## `SDL_GetWindowPixelFormat( ... )`

Get the pixel format associated with the window.

        my $format = SDL_GetWindowPixelFormat( $window );

Expected parameters include:

- `window` - the window to query

Returns the pixel format of the window on success or `SDL_PIXELFORMAT_UNKNOWN`
on failure; call [`SDL_GetError( )`](#sdl_geterror) for more
information.

## `SDL_CreateWindow( ... )`

Create a window with the specified position, dimensions, and flags.

    my $window = SDL_CreateWindow( 'Example',
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        1280, 720,
        SDL_WINDOW_SHOWN
    );

`flags` may be any of the following OR'd together:

- `SDL_WINDOW_FULLSCREEN` - fullscreen window
- `SDL_WINDOW_FULLSCREEN_DESKTOP` - fullscreen window at desktop resolution
- `SDL_WINDOW_OPENGL` - window usable with an OpenGL context
- `SDL_WINDOW_VULKAN` - window usable with a Vulkan instance
- `SDL_WINDOW_METAL` - window usable with a Metal instance
- `SDL_WINDOW_HIDDEN` - window is not visible
- `SDL_WINDOW_BORDERLESS` - no window decoration
- `SDL_WINDOW_RESIZABLE` - window can be resized
- `SDL_WINDOW_MINIMIZED` - window is minimized
- `SDL_WINDOW_MAXIMIZED` - window is maximized
- `SDL_WINDOW_INPUT_GRABBED` - window has grabbed input focus
- `SDL_WINDOW_ALLOW_HIGHDPI` - window should be created in high-DPI mode if supported (>= SDL 2.0.1)

`SDL_WINDOW_SHOWN` is ignored by `SDL_CreateWindow( ... )`. The SDL\_Window is
implicitly shown if `SDL_WINDOW_HIDDEN` is not set. `SDL_WINDOW_SHOWN` may be
queried later using [`SDL_GetWindowFlags( ... )`](#sdl_getwindowflags).

On Apple's macOS, you **must** set the NSHighResolutionCapable Info.plist
property to YES, otherwise you will not receive a High-DPI OpenGL canvas.

If the window is created with the `SDL_WINDOW_ALLOW_HIGHDPI` flag, its size in
pixels may differ from its size in screen coordinates on platforms with
high-DPI support (e.g. iOS and macOS). Use [`SDL_GetWindowSize( ...
)`](#sdl_getwindowsize) to query the client area's size in screen
coordinates, and [`SDL_GL_GetDrawableSize( )`](#sdl_gl_getdrawablesize) or [`SDL_GetRendererOutputSize( )`](#sdl_getrendereroutputsize)
to query the drawable size in pixels.

If the window is set fullscreen, the width and height parameters `w` and `h`
will not be used. However, invalid size parameters (e.g. too large) may still
fail. Window size is actually limited to 16384 x 16384 for all platforms at
window creation.

If the window is created with any of the `SDL_WINDOW_OPENGL` or
`SDL_WINDOW_VULKAN` flags, then the corresponding LoadLibrary function
(SDL\_GL\_LoadLibrary or SDL\_Vulkan\_LoadLibrary) is called and the corresponding
UnloadLibrary function is called by [`SDL_DestroyWindow( ...
)`](#sdl_destroywindow).

If `SDL_WINDOW_VULKAN` is specified and there isn't a working Vulkan driver,
`SDL_CreateWindow( ... )` will fail because [`SDL_Vulkan_LoadLibrary(
)`](#sdl_vulkan_loadlibrary) will fail.

If `SDL_WINDOW_METAL` is specified on an OS that does not support Metal,
`SDL_CreateWindow( ... )` will fail.

On non-Apple devices, SDL requires you to either not link to the Vulkan loader
or link to a dynamic library version. This limitation may be removed in a
future version of SDL.

Expected parameters include:

- `title` - the title of the window, in UTF-8 encoding
- `x` - the x position of the window, `SDL_WINDOWPOS_CENTERED`, or `SDL_WINDOWPOS_UNDEFINED`
- `y` - the y position of the window, `SDL_WINDOWPOS_CENTERED`, or `SDL_WINDOWPOS_UNDEFINED`
- `w` - the width of the window, in screen coordinates
- `h` - the height of the window, in screen coordinates
- `flags` - 0, or one or more `SDL_WindowFlags` OR'd together

Returns the window that was created or an undefined value on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_CreateWindowFrom( ... )`

Create an SDL window from an existing native window.

        my $window = SDL_CreateWindowFrom( $data );

In some cases (e.g. OpenGL) and on some platforms (e.g. Microsoft Windows) the
hint `SDL_HINT_VIDEO_WINDOW_SHARE_PIXEL_FORMAT` needs to be configured before
using `SDL_CreateWindowFrom( ... )`.

Expected parameters include:

- `data` - driver-dependant window creation data, typically your native window

Returns the window that was created or an undefined value on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_GetWindowID( ... )`

Get the numeric ID of a window.

        my $id = SDL_GetWindowID( $window );

The numeric ID is what [SDL2::WindowEvent](https://metacpan.org/pod/SDL2%3A%3AWindowEvent) references, and is necessary to map
these events to specific [SDL2::Window](https://metacpan.org/pod/SDL2%3A%3AWindow) objects.

Expected parameters include:

- `window` - the window to query

Returns the ID of the window on success or `0` on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_GetWindowFromID( ... )`

Get a window from a stored ID.

        my $window = SDL_GetWindowFromID( 2 );

The numeric ID is what [SDL2::WindowEvent](https://metacpan.org/pod/SDL2%3A%3AWindowEvent) references, and is necessary to map
these events to specific [SDL2::Window](https://metacpan.org/pod/SDL2%3A%3AWindow) objects.

Expected parameters include:

- `id` - the ID of the window

Returns the window associated with `id` or an undefined value if it doesn't
exist; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_GetWindowFlags( ... )`

Get the window flags.

        my $id = SDL_GetWindowFlags( $window );

The numeric ID is what [SDL2::WindowEvent](https://metacpan.org/pod/SDL2%3A%3AWindowEvent) references, and is necessary to map
these events to specific [SDL2::Window](https://metacpan.org/pod/SDL2%3A%3AWindow) objects.

Expected parameters include:

- `window` - the window to query

Returns a mask of the SDL\_WindowFlags associated with `window`.

## `SDL_SetWindowTitle( ... )`

Set the title of a window.

        SDL_SetWindowTitle( $window, 'Untitle file *' );

This string is expected to be in UTF-8 encoding.

Expected parameters include:

- `window` - the window to change
- `title` - the desired window title in UTF-8 format

## `SDL_GetWindowTitle( ... )`

Get the title of a window.

        my $title = SDL_GetWindowTitle( $window );

Expected parameters include:

- `window` - the window to query

Returns the title of the window in UTF-8 format or `""` (an empty string) if
there is no title.

## `SDL_SetWindowIcon( ... )`

Set the icon for a window.

        SDL_SetWindowIcon( $window, $icon );

Expected parameters include:

- `window` - the window to change
- `icon` - an [SDL2::Surface](https://metacpan.org/pod/SDL2%3A%3ASurface) structure containing the icon for the window

## `SDL_SetWindowData( ... )`

Associate an arbitrary named pointer with a window.

        my $prev = SDL_SetWindowData( $window, 'test', $data );

Expected parameters include:

- `window` - the window to change
- `name` - the name of the pointer
- `userdata` - the associated pointer

Returns the previous value associated with `name`.

## `SDL_GetWindowData( ... )`

Retrieve the data pointer associated with a window.

        my $data = SDL_SetWindowData( $window, 'test' );

Expected parameters include:

- `window` - the window to query
- `name` - the name of the pointer

Returns the value associated with `name`.

## `SDL_SetWindowPosition( ... )`

Set the position of a window.

        SDL_SetWindowPosition( $window, 100, 100 );

The window coordinate origin is the upper left of the display.

Expected parameters include:

- `window` - the window to reposition
- `x` - the x coordinate of the window in screen coordinates, or `SDL_WINDOWPOS_CENTERED` or `SDL_WINDOWPOS_UNDEFINED`
- `y` - the y coordinate of the window in screen coordinates, or `SDL_WINDOWPOS_CENTERED` or `SDL_WINDOWPOS_UNDEFINED`

## `SDL_GetWindowPosition( ... )`

Get the position of a window.

        my ($x, $y) = SDL_GetWindowPosition( $window );

Expected parameters include:

- `window` - the window to query

Returns the `x` and `y` positions of the window, in screen coordinates,
either of which may be undefined.

## `SDL_SetWindowSize( ... )`

Set the size of a window's client area.

        SDL_SetWindowSize( $window, 100, 100 );

The window size in screen coordinates may differ from the size in pixels, if
the window was created with `SDL_WINDOW_ALLOW_HIGHDPI` on a platform with
high-dpi support (e.g. iOS or macOS). Use [`SDL_GL_GetDrawableSize( ...
)`](https://metacpan.org/pod/SDL_GL_GetDrawableSize%28%20...%20%29) or [`SDL_GetRendererOutputSize( ...
)`](#sdl_getrendereroutputsize) to get the real client area size in
pixels.

Fullscreen windows automatically match the size of the display mode, and you
should use [`SDL_SetWindowDisplayMode( ... )`](#sdl_setwindowdisplaymode) to change their size.

Expected parameters include:

- `window` - the window to change
- `w` - the width of the window in pixels, in screen coordinates, must be > 0
- `h` - the height of the window in pixels, in screen coordinates, must be > 0

## `SDL_GetWindowSize( ... )`

Get the position of a window.

        my ($w, $h) = SDL_GetWindowSize( $window );

The window size in screen coordinates may differ from the size in pixels, if
the window was created with `SDL_WINDOW_ALLOW_HIGHDPI` on a platform with
high-dpi support (e.g. iOS or macOS). Use [`SDL_GL_GetDrawableSize( ...
)`](https://metacpan.org/pod/SDL_GL_GetDrawableSize%28%20...%20%29), [`SDL_Vulkan_GetDrawableSize( ...
)`](#sdl_vulkan_getdrawablesize), or [`SDL_GetRendererOutputSize( ... )`](#sdl_getrendereroutputsize) to
get the real client area size in pixels.

Expected parameters include:

- `window` - the window to query the width and height from

Returns the `width` and `height` of the window, in screen coordinates, either
of which may be undefined.

## `SDL_GetWindowBordersSize( ... )`

Get the size of a window's borders (decorations) around the client area.

        my ($top, $left, $bottom, $right) = SDL_GetWindowBorderSize( $window );

Expected parameters include:

- `window` - the window to query the size values of the border (decorations) from

Returns the `top`, `left`, `bottom`, and `right` size values, any of which
may be undefined.

Note: If this function fails (returns -1), the size values will be initialized
to `0, 0, 0, 0`, as if the window in question was borderless.

Note: This function may fail on systems where the window has not yet been
decorated by the display server (for example, immediately after calling [`SDL_CreateWindow( ...  )`](#sdl_createwindow) ). It is
recommended that you wait at least until the window has been presented and
composited, so that the window system has a chance to decorate the window and
provide the border dimensions to SDL.

This function also returns `-1` if getting the information is not supported.

## `SDL_SetWindowMinimumSize( ... )`

Set the minimum size of a window's client area.

        SDL_SetWindowMinimumSize( $window, 100, 100 );

Expected parameters include:

- `window` - the window to change
- `w` - the minimum width of the window in pixels
- `h` - the minimum height of the window in pixels

## `SDL_GetWindowMinimumSize( ... )`

Get the minimum size of a window's client area.

        my ($w, $h) = SDL_GetWindowMinimumSize( $window );

Expected parameters include:

- `window` - the window to query the minimum width and minimum height from

Returns the minimum `width` and minimum `height` of the window, either of
which may be undefined.

## `SDL_SetWindowMaximumSize( ... )`

Set the maximum size of a window's client area.

        SDL_SetWindowMaximumSize( $window, 100, 100 );

Expected parameters include:

- `window` - the window to change
- `w` - the maximum width of the window in pixels
- `h` - the maximum height of the window in pixels

## `SDL_GetWindowMaximumSize( ... )`

Get the maximum size of a window's client area.

        my ($w, $h) = SDL_GetWindowMaximumSize( $window );

Expected parameters include:

- `window` - the window to query the maximum width and maximum height from

Returns the maximum `width` and maximum `height` of the window, either of
which may be undefined.

## `SDL_SetWindowBordered( ... )`

Set the border state of a window.

        SDL_SetWindowBordered( $window, 1 );

This will add or remove the window's `SDL_WINDOW_BORDERLESS` flag and add or
remove the border from the actual window. This is a no-op if the window's
border already matches the requested state.

You can't change the border state of a fullscreen window.

Expected parameters include:

- `window` - the window of which to change the border state
- `bordered` - false value to remove border, true value to add border

## `SDL_SetWindowResizable( ... )`

Set the user-resizable state of a window.

        SDL_SetWindowResizable( $window, 1 );

This will add or remove the window's `SDL_WINDOW_RESIZABLE` flag and
allow/disallow user resizing of the window. This is a no-op if the window's
resizable state already matches the requested state.

You can't change the resizable state of a fullscreen window.

Expected parameters include:

- `window` - the window of which to change the border state
- `bordered` - true value to allow resizing, false value to disallow

## `SDL_ShowWindow( ... )`

Show a window.

        SDL_ShowWindow( $window );

Expected parameters include:

- `window` - the window to show

## `SDL_HideWindow( ... )`

Hide a window.

        SDL_HideWindow( $window );

Expected parameters include:

- `window` - the window to hide

## `SDL_RaiseWindow( ... )`

Raise a window above other windows and set the input focus.

        SDL_RaiseWindow( $window );

Expected parameters include:

- `window` - the window to raise

## `SDL_MaximizeWindow( ... )`

Make a window as large as possible.

        SDL_MaximizeWindow( $window );

Expected parameters include:

- `window` - the window to maximize

## `SDL_MinimizeWindow( ... )`

Minimize a window to an iconic representation.

        SDL_MinimizeWindow( $window );

Expected parameters include:

- `window` - the window to minimize

## `SDL_RestoreWindow( ... )`

Restore the size and position of a minimized or maximized window.

        SDL_RestoreWindow( $window );

Expected parameters include:

- `window` - the window to restore

## `SDL_SetWindowFullscreen( ... )`

Set a window's fullscreen state.

        SDL_SetWindowFullscreen( $window, SDL_WINDOW_FULLSCREEN );

Expected parameters include:

- `window` - the window to change
- `flags` - `SDL_WINDOW_FULLSCREEN`, `SDL_WINDOW_FULLSCREEN_DESKTOP` or 0

Returns  0 on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_GetWindowSurface( ... )`

Get the SDL surface associated with the window.

        my $surface = SDL_GetWindowSurface( $window );

A new surface will be created with the optimal format for the window, if
necessary. This surface will be freed when the window is destroyed. Do not free
this surface.

This surface will be invalidated if the window is resized. After resizing a
window this function must be called again to return a valid surface.

You may not combine this with 3D or the rendering API on this window.

This function is affected by `SDL_HINT_FRAMEBUFFER_ACCELERATION`.

Expected parameters include:

- `window` - the window to query

Returns the surface associated with the window, or an undefined on failure;
call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_UpdateWindowSurface( ... )`

Copy the window surface to the screen.

        my $ok = !SDL_UpdateWindowSurface( $window );

This is the function you use to reflect any changes to the surface on the
screen.

Expected parameters include:

- `window` - the window to query

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_UpdateWindowSurfaceRects( ... )`

Copy areas of the window surface to the screen.

        SDL_UpdateWindowSurfaceRects( $window, @recs );

This is the function you use to reflect changes to portions of the surface on
the screen.

Expected parameters include:

- `window` - the window to update
- `rects` - an array of [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structures representing areas of the surface to copy

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_SetWindowGrab( ... )`

Set a window's input grab mode.

        SDL_SetWindowGrab( $window, 1 );

When input is grabbed the mouse is confined to the window.

If the caller enables a grab while another window is currently grabbed, the
other window loses its grab in favor of the caller's window.

Expected parameters include:

- `window` - the window for which the input grab mode should be set
- `grabbed` - a true value to grab input or a false value to release input

## `SDL_SetWindowKeyboardGrab( ... )`

Set a window's keyboard grab mode.

        SDL_SetWindowKeyboardGrab( $window, 1 );

If the caller enables a grab while another window is currently grabbed, the
other window loses its grab in favor of the caller's window.

Expected parameters include:

- `window` - The window for which the keyboard grab mode should be set.
- `grabbed` - This is true to grab keyboard, and false to release.

## `SDL_SetWindowMouseGrab( ... )`

Set a window's mouse grab mode.

        SDL_SetWindowMouseGrab( $window, 1 );

Expected parameters include:

- `window` - The window for which the mouse grab mode should be set.
- `grabbed` - This is true to grab mouse, and false to release.

If the caller enables a grab while another window is currently grabbed, the
other window loses its grab in favor of the caller's window.

## `SDL_GetWindowGrab( ... )`

Get a window's input grab mode.

        my $grabbing = SDL_GetWindowGrab( $window );

Expected parameters include:

- `window` - the window to query

Returns true if input is grabbed, false otherwise.

## `SDL_GetWindowKeyboardGrab( ... )`

Get a window's keyboard grab mode.

        my $keyboard = SDL_GetWindowKeyboardGrab( $window );

Expected parameters include:

- `window` - the window to query

Returns true if keyboard is grabbed, and false otherwise.

## `SDL_GetWindowMouseGrab( ... )`

Get a window's mouse grab mode.

        my $mouse = SDL_GetWindowMouseGrab( $window );

Expected parameters include:

- `window` - the window to query

This returns true if mouse is grabbed, and false otherwise.

## `SDL_GetGrabbedWindow( )`

Get the window that currently has an input grab enabled.

        my $window = SDL_GetGrabbedWindow( );

Returns the window if input is grabbed or undefined otherwise.

## `SDL_SetWindowBrightness( ... )`

Set the brightness (gamma multiplier) for a given window's display.

        my $ok = !SDL_SetWindowBrightness( $window, 2 );

Despite the name and signature, this method sets the brightness of the entire
display, not an individual window. A window is considered to be owned by the
display that contains the window's center pixel. (The index of this display can
be retrieved using [`SDL_GetWindowDisplayIndex( ...
)`](#sdl_getwindowdisplayindex).) The brightness set will not follow
the window if it is moved to another display.

Many platforms will refuse to set the display brightness in modern times. You
are better off using a shader to adjust gamma during rendering, or something
similar.

Expected parameters includes:

- `window` - the window used to select the display whose brightness will be changed
- `brightness` - the brightness (gamma multiplier) value to set where 0.0 is completely dark and 1.0 is normal brightness

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetWindowBrightness( ... )`

Get the brightness (gamma multiplier) for a given window's display.

        my $gamma = SDL_GetWindowBrightness( $window );

Despite the name and signature, this method retrieves the brightness of the
entire display, not an individual window. A window is considered to be owned by
the display that contains the window's center pixel. (The index of this display
can be retrieved using [`SDL_GetWindowDisplayIndex( ...
)`](#sdl_getwindowdisplayindex).)

Expected parameters include:

- `window` - the window used to select the display whose brightness will be queried

Returns the brightness for the display where 0.0 is completely dark and `1.0`
is normal brightness.

## `SDL_SetWindowOpacity( ... )`

Set the opacity for a window.

        SDL_SetWindowOpacity( $window, .5 );

The parameter `opacity` will be clamped internally between `0.0`
(transparent) and `1.0` (opaque).

This function also returns `-1` if setting the opacity isn't supported.

Expected parameters include:

- `window` - the window which will be made transparent or opaque
- `opacity` - the opacity value (0.0 - transparent, 1.0 - opaque)

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetWindowOpacity( ... )`

Get the opacity of a window.

        my $opacity = SDL_GetWindowOpacity( $window );

If transparency isn't supported on this platform, opacity will be reported as
1.0 without error.

The parameter `opacity` is ignored if it is undefined.

This function also returns `-1` if an invalid window was provided.

Expected parameters include:

- `window` - the window to get the current opacity value from

Returns the current opacity on success or a negative error code on failure;
call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_SetWindowModalFor( ... )`

Set the window as a modal for another window.

        my $ok = !SDL_SetWindowModalFor( $winodw, $parent );

Expected parameters include:

- `modal_window` - the window that should be set modal
- `parent_window` - the parent window for the modal window

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_SetWindowInputFocus( ... )`

Explicitly set input focus to the window.

        SDL_SetWindowInputFocus( $window );

You almost certainly want [`SDL_RaiseWindow( ... )`](#sdl_raisewindow) instead of this function. Use this with caution, as you might give focus
to a window that is completely obscured by other windows.

Expected parameters include:

- `window` - the window that should get the input focus

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_SetWindowGammaRamp( ... )`

Set the gamma ramp for the display that owns a given window.

        my $ok = !SDL_SetWindowGammaRamp( $window, \@red, \@green, \@blue );

Set the gamma translation table for the red, green, and blue channels of the
video hardware. Each table is an array of 256 16-bit quantities, representing a
mapping between the input and output for that channel. The input is the index
into the array, and the output is the 16-bit gamma value at that index, scaled
to the output color precision. Despite the name and signature, this method sets
the gamma ramp of the entire display, not an individual window. A window is
considered to be owned by the display that contains the window's center pixel.
(The index of this display can be retrieved using [`SDL_GetWindowDisplayIndex( ... )`](#sdl_getwindowdisplayindex).)
The gamma ramp set will not follow the window if it is moved to another
display.

Expected parameters include:

- `window` - the window used to select the display whose gamma ramp will be changed
- `red` - a 256 element array of 16-bit quantities representing the translation table for the red channel, or NULL
- `green` - a 256 element array of 16-bit quantities representing the translation table for the green channel, or NULL
- `blue` - a 256 element array of 16-bit quantities representing the translation table for the blue channel, or NULL

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetWindowGammaRamp( ... )`

Get the gamma ramp for a given window's display.

        my ($red, $green, $blue) = SDL_GetWindowGammaRamp( $window );

Despite the name and signature, this method retrieves the gamma ramp of the
entire display, not an individual window. A window is considered to be owned by
the display that contains the window's center pixel. (The index of this display
can be retrieved using [`SDL_GetWindowDisplayIndex( ...
)`](#sdl_getwindowdisplayindex).)

Expected parameters include:

- `window` - the window used to select the display whose gamma ramp will be queried

Returns three 256 element arrays of 16-bit quantities filled in with the
translation table for the red, gree, and blue channels on success or a negative
error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( )
for more information.

## `SDL_SetWindowHitTest( ... )`

Provide a callback that decides if a window region has special properties.

        SDL_SetWindowHitTest( $window, sub ($win, $point, $data) {
        warn sprintf 'Click at x:%d y:%d', $point->x, $point->y;
        ...;
        });

Normally, windows are dragged and resized by decorations provided by the system
window manager (a title bar, borders, etc), but for some apps, it makes sense
to drag them from somewhere else inside the window itself; for example, one
might have a borderless window that wants to be draggable from any part, or
simulate its own title bar, etc.

This function lets the app provide a callback that designates pieces of a given
window as special. This callback is run during event processing if we need to
tell the OS to treat a region of the window specially; the use of this callback
is known as "hit testing."

Mouse input may not be delivered to your application if it is within a special
area; the OS will often apply that input to moving the window or resizing the
window and not deliver it to the application.

Specifying undef for a callback disables hit-testing. Hit-testing is disabled
by default.

Platforms that don't support this functionality will return `-1`
unconditionally, even if you're attempting to disable hit-testing.

Your callback may fire at any time, and its firing does not indicate any
specific behavior (for example, on Windows, this certainly might fire when the
OS is deciding whether to drag your window, but it fires for lots of other
reasons, too, some unrelated to anything you probably care about **and when the
mouse isn't actually at the location it is testing**). Since this can fire at
any time, you should try to keep your callback efficient, devoid of
allocations, etc.

Expected parameters include:

- `window` - the window to set hit-testing on
- `callback` - the function to call when doing a hit-test
- `callback_data` - an app-defined void pointer passed to `callback`

Returns `0` on success or `-1` on error (including unsupported); call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_FlashWindow( ... )`

Request a window to give a signal, e.g. a visual signal, to demand attention
from the user.

        SDL_FlashWindow( $window, 10 );

Expected parameters include:

- `window` - the window to request the flashing for
- `flash_count` - number of times the window gets flashed on systems that support flashing the window multiple times, like Windows, else it is ignored

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_DestroyWindow( ... )`

Destroy a window.

        SDL_DestoryWindow( $window );

If `window` is undefined, this function will return immediately after setting
the SDL error message to "Invalid window". See [`SDL_GetError(
)`](#sdl_geterror)( ).

Expected parameters include:

- `window` - the window to destroy

## `SDL_IsScreenSaverEnabled( ... )`

Check whether the screensaver is currently enabled.

        my $enabled = SDL_IsScreenSaverEnabled( );

The screensaver is disabled by default since SDL 2.0.2. Before SDL 2.0.2 the
screensaver was enabled by default.

The default can also be changed using `SDL_HINT_VIDEO_ALLOW_SCREENSAVER`.

Returns true if the screensaver is enabled, false if it is disabled.

## `SDL_EnableScreenSaver( ... )`

Allow the screen to be blanked by a screen saver.

        SDL_EnableScreenSaver( );

## `SDL_DisableScreenSaver( ... )`

Prevent the screen from being blanked by a screen saver.

        SDL_DisableScreenSaver( );

If you disable the screensaver, it is automatically re-enabled when SDL quits.

# OpenGL Support Functions

These may be imported with the `:opengl` tag.

## `SDL_GL_LoadLibrary( ... )`

Dynamically load an OpenGL library.

        my $ok = SDL_GL_LoadLibrary( );

This should be done after initializing the video driver, but before creating
any OpenGL windows. If no OpenGL library is loaded, the default library will be
loaded upon creation of the first OpenGL window.

If you do this, you need to retrieve all of the GL functions used in your
program from the dynamic library using [`SDL_GL_GetProcAddress(
)`](#sdl_gl_getprocaddress).

Expected parameters include:

- `path` - the platform dependent OpenGL library name, or undef to open the default OpenGL library

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GL_GetProcAddress( ... )`

Get an OpenGL function by name.

        my $ptr = SDL_GL_GetProcAddress( 'glGenBuffers' );
        ...; # TODO
        # TODO: In the future, this should return an XSUB loaded with FFI.

If the GL library is loaded at runtime with [`SDL_GL_LoadLibrary( ...
)`](#sdl_gl_loadlibrary), then all GL functions must be retrieved
this way. Usually this is used to retrieve function pointers to OpenGL
extensions.

There are some quirks to looking up OpenGL functions that require some extra
care from the application. If you code carefully, you can handle these quirks
without any platform-specific code, though:

- On Windows, function pointers are specific to the current GL context;
this means you need to have created a GL context and made it current before
calling SDL\_GL\_GetProcAddress( ). If you recreate your context or create a
second context, you should assume that any existing function pointers
aren't valid to use with it. This is (currently) a Windows-specific
limitation, and in practice lots of drivers don't suffer this limitation,
but it is still the way the wgl API is documented to work and you should
expect crashes if you don't respect it. Store a copy of the function
pointers that comes and goes with context lifespan.
- On X11, function pointers returned by this function are valid for any
context, and can even be looked up before a context is created at all. This
means that, for at least some common OpenGL implementations, if you look up
a function that doesn't exist, you'll get a non-NULL result that is \_NOT\_
safe to call. You must always make sure the function is actually available
for a given GL context before calling it, by checking for the existence of
the appropriate extension with [`SDL_GL_ExtensionSupported( ... )`](https://metacpan.org/pod/SDL_GL_ExtensionSupported%28%20...%20%29), or verifying
that the version of OpenGL you're using offers the function as core
functionality.
- Some OpenGL drivers, on all platforms, **will** return undef if a function
isn't supported, but you can't count on this behavior. Check for extensions
you use, and if you get an undef anyway, act as if that extension wasn't
available. This is probably a bug in the driver, but you can code
defensively for this scenario anyhow.
- Just because you're on Linux/Unix, don't assume you'll be using X11.
Next-gen display servers are waiting to replace it, and may or may not make
the same promises about function pointers.
- OpenGL function pointers must be declared `APIENTRY` as in the example
code. This will ensure the proper calling convention is followed on
platforms where this matters (Win32) thereby avoiding stack corruption.

Expected parameters include:

- `proc` - the name of an OpenGL function

Returns a pointer to the named OpenGL function. The returned pointer should be
cast to the appropriate function signature.

## `SDL_GL_UnloadLibrary( )`

Unload the OpenGL library previously loaded by [`SDL_GL_LoadLibrary( ...
)`](#sdl_gl_loadlibrary).

## `SDL_GL_ExtensionSupported( ... )`

Check if an OpenGL extension is supported for the current context.

        my $ok = SDL_GL_ExtensionSupported( 'GL_ARB_texture_rectangle' );

This function operates on the current GL context; you must have created a
context and it must be current before calling this function. Do not assume that
all contexts you create will have the same set of extensions available, or that
recreating an existing context will offer the same extensions again.

While it's probably not a massive overhead, this function is not an O(1)
operation. Check the extensions you care about after creating the GL context
and save that information somewhere instead of calling the function every time
you need to know.

Expected parameters include:

- `extension` - the name of the extension to check

Returns true if the extension is supported, false otherwise.

## `SDL_GL_ResetAttributes( )`

Reset all previously set OpenGL context attributes to their default values.

        SDL_GL_ResetAttributes( );

## `SDL_GL_SetAttribute( ... )`

Set an OpenGL window attribute before window creation.

        SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 5);
        SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 5);
        SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 5);
        SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);
        SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

This function sets the OpenGL attribute `attr` to `value`. The requested
attributes should be set before creating an OpenGL window. You should use [`SDL_GL_GetAttribute( ... )`](#sdl_gl_getattribute) to check the
values after creating the OpenGL context, since the values obtained can differ
from the requested ones.

Expected parameters include:

- `attr` - an SDL\_GLattr enum value specifying the OpenGL attribute to set
- `value` - the desired value for the attribute

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GL_GetAttribute( ... )`

Get the actual value for an attribute from the current context.

        my $value = SDL_GL_GetAttribute(SDL_GL_DOUBLEBUFFER);

Expected parameters include:

- `attr` - an SDL\_GLattr enum value specifying the OpenGL attribute to get

Returns the value on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GL_CreateContext( ... )`

Create an OpenGL context for an OpenGL window, and make it current.

        # Window mode MUST include SDL_WINDOW_OPENGL for use with OpenGL.
        my $window = SDL_CreateWindow(
        'SDL2/OpenGL Demo', 0, 0, 640, 480,
        SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE);

        # Create an OpenGL context associated with the window
        my $glcontext = SDL_GL_CreateContext( $window );

        # now you can make GL calls.
        glClearColor( 0, 0, 0 ,1 );
        glClear( GL_COLOR_BUFFER_BIT );
        SDL_GL_SwapWindow( $window );

        # Once finished with OpenGL functions, the SDL_GLContext can be deleted.
        SDL_GL_DeleteContext( $glcontext );

Windows users new to OpenGL should note that, for historical reasons, GL
functions added after OpenGL version 1.1 are not available by default. Those
functions must be loaded at run-time, either with an OpenGL extension-handling
library or with [`SDL_GL_GetProcAddress( ... )`](#sdl_gl_getprocaddress) and its related functions.

SDL2::GLContext is opaque to the application.

Expected parameters include:

- `window` - the window to associate with the context

Returns the OpenGL context associated with `window` or undef on error; call
[`SDL_GetError( )`](#sdl_geterror)( ) for more details.

## `SDL_GL_MakeCurrent( ... )`

Set up an OpenGL context for rendering into an OpenGL window.

        SDL_GL_MakeCurrent( $window, $gl );

The context must have been created with a compatible window.

Expected parameters include:

- `window` - the window to associate with the context
- `context` - the OpenGL context to associate with the window

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GL_GetCurrentWindow( )`

Get the currently active OpenGL window.

        my $window = SDL_GL_GetCurrentWindow( );

Returns the currently active OpenGL window on success or undef on failure; call
[`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GL_GetCurrentContext( )`

Get the currently active OpenGL context.

        my $gl = SDL_GL_GetCurrentContext( );

Returns the currently active OpenGL context or NULL on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GL_GetDrawableSize( ... )`

Get the size of a window's underlying drawable in pixels.

        my ($w, $h) = SDL_GL_GetDrawableSize( $window );

This returns info useful for calling `glViewport( ... )`.

This may differ from [`SDL_GetWindowSize( ... )`](#sdl_getwindowsize) if we're rendering to a high-DPI drawable, i.e. the window was created
with `SDL_WINDOW_ALLOW_HIGHDPI` on a platform with high-DPI support (Apple
calls this "Retina"), and not disabled by the
`SDL_HINT_VIDEO_HIGHDPI_DISABLED` hint.

Expected parameters include:

- `window` - the window from which the drawable size should be queried

Returns the width and height in pixels, either of which may be undefined.

## `SDL_GL_SetSwapInterval( ... )`

Set the swap interval for the current OpenGL context.

        my $ok = !SDL_GL_SetSwapInterval( 1 );

Some systems allow specifying `-1` for the interval, to enable adaptive vsync.
Adaptive vsync works the same as vsync, but if you've already missed the
vertical retrace for a given frame, it swaps buffers immediately, which might
be less jarring for the user during occasional framerate drops. If application
requests adaptive vsync and the system does not support it, this function will
fail and return `-1`. In such a case, you should probably retry the call with
`1` for the interval.

Adaptive vsync is implemented for some glX drivers with
`GLX_EXT_swap_control_tear`:
[https://www.opengl.org/registry/specs/EXT/glx\_swap\_control\_tear.txt](https://www.opengl.org/registry/specs/EXT/glx_swap_control_tear.txt) and for
some Windows drivers with `WGL_EXT_swap_control_tear`:
[https://www.opengl.org/registry/specs/EXT/wgl\_swap\_control\_tear.txt](https://www.opengl.org/registry/specs/EXT/wgl_swap_control_tear.txt)

Read more on the Khronos wiki:
[https://www.khronos.org/opengl/wiki/Swap\_Interval#Adaptive\_Vsync](https://www.khronos.org/opengl/wiki/Swap_Interval#Adaptive_Vsync)

Expected parameters include:

- `interval` - 0 for immediate updates, 1 for updates synchronized with the vertical retrace, -1 for adaptive vsync

Returns `0` on success or `-1` if setting the swap interval is not supported;
call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GL_GetSwapInterval( )`

Get the swap interval for the current OpenGL context.

        my $interval = SDL_GL_GetSwapInterval( );

If the system can't determine the swap interval, or there isn't a valid current
context, this function will return 0 as a safe default.

Returns `0` if there is no vertical retrace synchronization, `1` if the
buffer swap is synchronized with the vertical retrace, and `-1` if late swaps
happen immediately instead of waiting for the next retrace; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GL_SwapWindow( ... )`

Update a window with OpenGL rendering.

        SDL_GL_SwapWindow( $window );

This is used with double-buffered OpenGL contexts, which are the default.

On macOS, make sure you bind 0 to the draw framebuffer before swapping the
window, otherwise nothing will happen. If you aren't using `glBindFramebuffer(
)`, this is the default and you won't have to do anything extra.

Expected parameters include:

- `window` - the window to change

## `SDL_GL_DeleteContext( ... )`

Delete an OpenGL context.

        SDL_GL_DeleteContext( $context );

Expected parameters include:

- `context` - the OpenGL context to be deleted

## 2D Accelerated Rendering

This category contains functions for 2D accelerated rendering. You may import
these functions with the `:render` tag.

This API supports the following features:

- single pixel points
- single pixel lines
- filled rectangles
- texture images

All of these may be drawn in opaque, blended, or additive modes.

The texture images can have an additional color tint or alpha modulation
applied to them, and may also be stretched with linear interpolation, rotated
or flipped/mirrored.

For advanced functionality like particle effects or actual 3D you should use
SDL's OpenGL/Direct3D support or one of the many available 3D engines.

This API is not designed to be used from multiple threads, see [SDL issue
\#986](https://github.com/libsdl-org/SDL/issues/986) for details.

## `SDL_GetNumRenderDrivers( )`

Get the number of 2D rendering drivers available for the current display.

        my $drivers = SDL_GetNumRenderDrivers( );

A render driver is a set of code that handles rendering and texture management
on a particular display. Normally there is only one, but some drivers may have
several available with different capabilities.

There may be none if SDL was compiled without render support.

Returns a number >= 0 on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetRenderDriverInfo( ... )`

Get info about a specific 2D rendering driver for the current display.

        my $info = !SDL_GetRendererDriverInfo( );

Expected parameters include:

- `index` - the index of the driver to query information about

Returns an [SDL2::RendererInfo](https://metacpan.org/pod/SDL2%3A%3ARendererInfo) structure on success or a negative error code
on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more
information.

## `SDL_CreateWindowAndRenderer( ... )`

Create a window and default renderer.

        my ($window, $renderer) = SDL_CreateWindowAndRenderer(640, 480, 0);

Expected parameters include:

- `width` - the width of the window
- `height` - the height of the window
- `window_flags` - the flags used to create the window (see [`SDL_CreateWindow( ... )`](#sdl_createwindow))

Returns a [SDL2::Window](https://metacpan.org/pod/SDL2%3A%3AWindow) and [SDL2::Renderer](https://metacpan.org/pod/SDL2%3A%3ARenderer) objects on success, or -1 on
error; call [`SDL_GetError( )`](#sdl_geterror)( ) for more
information.

## `SDL_CreateRenderer( ... )`

Create a 2D rendering context for a window.

        my $renderer = SDL_CreateRenderer( $window, -1, 0);

Expected parameters include:

- `window` - the window where rendering is displayed
- `index` - the index of the rendering driver to initialize, or `-1` to initialize the first one supporting the requested flags
- `flags` - `0`, or one or more `SDL_RendererFlags` OR'd together

Returns a valid rendering context or undefined if there was an error; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_CreateSoftwareRenderer( ... )`

Create a 2D software rendering context for a surface.

        my $renderer = SDL_CreateSoftwareRenderer( $surface );

Two other API which can be used to create SDL\_Renderer:

[`SDL_CreateRenderer( ... )`](#sdl_createrenderer) and [`SDL_CreateWindowAndRenderer( ... )`](#sdl_createwindowandrenderer). These can **also** create a software renderer, but they are intended to be
used with an [SDL2::Window](https://metacpan.org/pod/SDL2%3A%3AWindow) as the final destination and not an
[SDL2::Surface](https://metacpan.org/pod/SDL2%3A%3ASurface).

Expected parameters include:

- `surface` - the [SDL2::Surface](https://metacpan.org/pod/SDL2%3A%3ASurface) structure representing the surface where rendering is done

Returns a valid rendering context or undef if there was an error; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetRenderer( ... )`

Get the renderer associated with a window.

        my $renderer = SDL_GetRenderer( $window );

Expected parameters include:

- `window` - the window to query

Returns the rendering context on success or undef on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetRendererInfo( ... )`

Get information about a rendering context.

        my $info = !SDL_GetRendererInfo( $renderer );

Expected parameters include:

- `renderer` - the rendering context

Returns an [SDL2::RendererInfo](https://metacpan.org/pod/SDL2%3A%3ARendererInfo) structure on success or a negative error code
on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more
information.

## `SDL_GetRendererOutputSize( ... )`

Get the output size in pixels of a rendering context.

        my ($w, $h) = SDL_GetRendererOutputSize( $renderer );

Due to high-dpi displays, you might end up with a rendering context that has
more pixels than the window that contains it, so use this instead of [`SDL_GetWindowSize( ... )`](#sdl_getwindowsize) to decide how much
drawing area you have.

Expected parameters include:

- `renderer` - the rendering context

Returns the width and height on success or a negative error code on failure;
call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_CreateTexture( ... )`

Create a texture for a rendering context.

    my $texture = SDL_CreateTexture( $renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, 1024, 768);

You can set the texture scaling method by setting
`SDL_HINT_RENDER_SCALE_QUALITY` before creating the texture.

Expected parameters include:

- `renderer` - the rendering context
- `format` - one of the enumerated values in `:pixelFormatEnum`
- `access` - one of the enumerated values in `:textureAccess`
- `w` - the width of the texture in pixels
- `h` - the height of the texture in pixels

Returns a pointer to the created texture or undefined if no rendering context
was active, the format was unsupported, or the width or height were out of
range; call [`SDL_GetError( )`](#sdl_geterror)( ) for more
information.

## `SDL_CreateTextureFromSurface( ... )`

Create a texture from an existing surface.

        use Config;
        my ($rmask, $gmask, $bmask, $amask) =
        $Config{byteorder} == 4321 ? (0xff000000,0x00ff0000,0x0000ff00,0x000000ff) :
                                                         (0x000000ff,0x0000ff00,0x00ff0000,0xff000000);
        my $surface = SDL_CreateRGBSurface( 0, 640, 480, 32, $rmask, $gmask, $bmask, $amask );
        my $texture = SDL_CreateTextureFromSurface( $renderer, $surface );

The surface is not modified or freed by this function.

The SDL\_TextureAccess hint for the created texture is
`SDL_TEXTUREACCESS_STATIC`.

The pixel format of the created texture may be different from the pixel format
of the surface. Use [`SDL_QueryTexture( ... )`](#sdl_querytexture) to query the pixel format of the texture.

Expected parameters include:

- `renderer` - the rendering context
- `surface` - the [SDL2::Surface](https://metacpan.org/pod/SDL2%3A%3ASurface) structure containing pixel data used to fill the texture

Returns the created texture or undef on failure; call [`SDL_GetError(
)`](#sdl_geterror)( ) for more information.

## `SDL_QueryTexture( ... )`

Query the attributes of a texture.

        my ( $format, $access, $w, $h ) = SDL_QueryTexture( $texture );

Expected parameters include:

- `texture` - the texture to query

Returns the following on success...

- `format` - a pointer filled in with the raw format of the texture; the
actual format may differ, but pixel transfers will use this
format (one of the [`:pixelFormatEnum`](#pixelformatenum) values)
- `access` - a pointer filled in with the actual access to the texture (one of the [`:textureAccess`](#textureaccess) values)
- `w` - a pointer filled in with the width of the texture in pixels
- `h` - a pointer filled in with the height of the texture in pixels

...or a negative error code on failure; call [`SDL_GetError(
)`](#sdl_geterror)( ) for more information.

## `SDL_SetTextureColorMod( ... )`

Set an additional color value multiplied into render copy operations.

        my $ok = !SDL_SetTextureColorMod( $texture, 64, 64, 64 );

When this texture is rendered, during the copy operation each source color
channel is modulated by the appropriate color value according to the following
formula:

        srcC = srcC * (color / 255)

Color modulation is not always supported by the renderer; it will return `-1`
if color modulation is not supported.

Expected parameters include:

- `texture` - the texture to update
- `r` - the red color value multiplied into copy operations
- `g` - the green color value multiplied into copy operations
- `b` - the blue color value multiplied into copy operations

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetTextureColorMod( ... )`

Get the additional color value multiplied into render copy operations.

        my ( $r, $g, $b ) = SDL_GetTextureColorMod( $texture );

Expected parameters include:

- `texture` - the texture to query

Returns the current red, green, and blue color values on success or a negative
error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( )
for more information.

## `SDL_SetTextureAlphaMod( ... )`

Set an additional alpha value multiplied into render copy operations.

        SDL_SetTextureAlphaMod( $texture, 100 );

When this texture is rendered, during the copy operation the source alpha

value is modulated by this alpha value according to the following formula:

        srcA = srcA * (alpha / 255)

Alpha modulation is not always supported by the renderer; it will return `-1`
if alpha modulation is not supported.

Expected parameters include:

- `texture` - the texture to update
- `alpha` - the source alpha value multiplied into copy operations

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetTextureAlphaMod( ... )`

Get the additional alpha value multiplied into render copy operations.

        my $alpha = SDL_GetTextureAlphaMod( $texture );

Expected parameters include:

- `texture` - the texture to query

Returns the current alpha value on success or a negative error code on failure;
call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_SetTextureBlendMode( ... )`

Set the blend mode for a texture, used by [`SDL_RenderCopy( ...
)`](#sdl_rendercopy).

If the blend mode is not supported, the closest supported mode is chosen and
this function returns `-1`.

Expected parameters include:

- `texture` - the texture to update
- `blendMode` - the [`:blendMode`](#blendmode) to use for texture blending

Returns 0 on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetTextureBlendMode( ... )`

Get the blend mode used for texture copy operations.

        SDL_GetTextureBlendMode( $texture, SDL_BLENDMODE_ADD );

Expected parameters include:

- `texture` - the texture to query

Returns the current `:blendMode` on success or a negative error code on
failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more
information.

## `SDL_SetTextureScaleMode( ... )`

Set the scale mode used for texture scale operations.

        SDL_SetTextureScaleMode( $texture, $scaleMode );

If the scale mode is not supported, the closest supported mode is chosen.

Expected parameters include:

- `texture` - The texture to update.
- `scaleMode` - the SDL\_ScaleMode to use for texture scaling.

Returns `0` on success, or `-1` if the texture is not valid.

## `SDL_GetTextureScaleMode( ... )`

Get the scale mode used for texture scale operations.

        my $ok = SDL_GetTextureScaleMode( $texture );

Expected parameters include:

- `texture` - the texture to query.

Returns the current scale mode on success, or `-1` if the texture is not
valid.

## `SDL_UpdateTexture( ... )`

Update the given texture rectangle with new pixel data.

        my $rect = SDL2::Rect->new( { x => 0, y => ..., w => $surface->w, h => $surface->h } );
        SDL_UpdateTexture( $texture, $rect, $surface->pixels, $surface->pitch );

The pixel data must be in the pixel format of the texture. Use [`SDL_QueryTexture( ... )`](#sdl_querytexture) to query the pixel
format of the texture.

This is a fairly slow function, intended for use with static textures that do
not change often.

If the texture is intended to be updated often, it is preferred to create the
texture as streaming and use the locking functions referenced below. While this
function will work with streaming textures, for optimization reasons you may
not get the pixels back if you lock the texture afterward.

Expected parameters include:

- `texture` - the texture to update
- `rect` - an [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure representing the area to update, or undef to update the entire texture
- `pixels` - the raw pixel data in the format of the texture
- `pitch` - the number of bytes in a row of pixel data, including padding between lines

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_UpdateYUVTexture( ... )`

Update a rectangle within a planar YV12 or IYUV texture with new pixel data.

        SDL_UpdateYUVTexture( $texture, $rect, $yPlane, $yPitch, $uPlane, $uPitch, $vPlane, $vPitch );

You can use [`SDL_UpdateTexture( ... )`](#sdl_updatetexture) as
long as your pixel data is a contiguous block of Y and U/V planes in the proper
order, but this function is available if your pixel data is not contiguous.

Expected parameters include:

- `texture` - the texture to update
- `rect` - a pointer to the rectangle of pixels to update, or undef to update the entire texture
- `Yplane` - the raw pixel data for the Y plane
- `Ypitch` - the number of bytes between rows of pixel data for the Y plane
- `Uplane` - the raw pixel data for the U plane
- `Upitch` - the number of bytes between rows of pixel data for the U plane
- `Vplane` - the raw pixel data for the V plane
- `Vpitch` - the number of bytes between rows of pixel data for the V plane

Returns `0` on success or -1 if the texture is not valid; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_UpdateNVTexture( ... )`

Update a rectangle within a planar NV12 or NV21 texture with new pixels.

        SDL_UpdateNVTexture( $texture, $rect, $yPlane, $yPitch, $uPlane, $uPitch );

You can use [`SDL_UpdateTexture( ... )`](#sdl_updatetexture) as
long as your pixel data is a contiguous block of NV12/21 planes in the proper
order, but this function is available if your pixel data is not contiguous.

Expected parameters include:

- `texture` - the texture to update
- `rect` - a pointer to the rectangle of pixels to update, or undef to update the entire texture.
- `Yplane` - the raw pixel data for the Y plane.
- `Ypitch` - the number of bytes between rows of pixel data for the Y plane.
- `UVplane` - the raw pixel data for the UV plane.
- `UVpitch` - the number of bytes between rows of pixel data for the UV plane.

Returns `0` on success, or `-1` if the texture is not valid.

## `SDL_LockTexture( ... )`

Lock a portion of the texture for **write-only** pixel access.

        SDL_LockTexture( $texture, $rect, $pixels, $pitch );

As an optimization, the pixels made available for editing don't necessarily
contain the old texture data. This is a write-only operation, and if you need
to keep a copy of the texture data you should do that at the application level.

You must use [`SDL_UpdateTexture( ... )`](#sdl_updatetexture) to
unlock the pixels and apply any changes.

Expected parameters include:

- `texture` - the texture to lock for access, which was created with `SDL_TEXTUREACCESS_STREAMING`
- `rect` - an [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure representing the area to lock for access; undef to lock the entire texture
- `pixels` - this is filled in with a pointer to the locked pixels, appropriately offset by the locked area
- `pitch` - this is filled in with the pitch of the locked pixels; the pitch is the length of one row in bytes

Returns 0 on success or a negative error code if the texture is not valid or
was not created with \`SDL\_TEXTUREACCESS\_STREAMING\`; call [`SDL_GetError(
)`](#sdl_geterror)( ) for more information.

## `SDL_LockTextureToSurface( ... )`

Lock a portion of the texture for **write-only** pixel access, and expose it as
a SDL surface.

        my $surface = SDL_LockTextureSurface( $texture, $rect );

Besides providing an [SDL2::Surface](https://metacpan.org/pod/SDL2%3A%3ASurface) instead of raw pixel data, this function
operates like [SDL2::LockTexture](https://metacpan.org/pod/SDL2%3A%3ALockTexture).

As an optimization, the pixels made available for editing don't necessarily
contain the old texture data. This is a write-only operation, and if you need
to keep a copy of the texture data you should do that at the application level.

You must use [`SDL_UnlockTexture( ... )`](#sdl_unlocktexture) to
unlock the pixels and apply any changes.

The returned surface is freed internally after calling [`SDL_UnlockTexture(
... )`](#sdl_unlocktexture) or [`SDL_DestroyTexture( ...
)`](#sdl_destroytexture). The caller should not free it.

Expected parameters include:

- `texture` - the texture to lock for access, which was created with `SDL_TEXTUREACCESS_STREAMING`
- `rect` - a pointer to the rectangle to lock for access. If the rect is undef, the entire texture will be locked

Returns the [SDL2::Surface](https://metacpan.org/pod/SDL2%3A%3ASurface) structure on success, or `-1` if the texture is
not valid or was not created with `SDL_TEXTUREACCESS_STREAMING`.

## `SDL_UnlockTexture( ... )`

Unlock a texture, uploading the changes to video memory, if needed.

        SDL_UnlockTexture( $texture );

**Warning**: Please note that [`SDL_LockTexture( ... )`](#sdl_locktexture) is intended to be write-only; it will not guarantee the previous
contents of the texture will be provided. You must fully initialize any area of
a texture that you lock before unlocking it, as the pixels might otherwise be
uninitialized memory.

Which is to say: locking and immediately unlocking a texture can result in
corrupted textures, depending on the renderer in use.

Expected parameters include:

- `texture` - a texture locked by [`SDL_LockTexture( ... )`](#sdl_locktexture)

## `SDL_RenderTargetSupported( ... )`

Determine whether a renderer supports the use of render targets.

        my $bool = SDL_RenderTargetSupported( $renderer );

Expected parameters include:

- `renderer` - the renderer that will be checked

Returns true if supported or false if not.

## `SDL_SetRenderTarget( ... )`

Set a texture as the current rendering target.

        SDL_SetRenderTarget( $renderer, $texture );

Before using this function, you should check the `SDL_RENDERER_TARGETTEXTURE`
bit in the flags of [SDL2::RendererInfo](https://metacpan.org/pod/SDL2%3A%3ARendererInfo) to see if render targets are
supported.

The default render target is the window for which the renderer was created. To
stop rendering to a texture and render to the window again, call this function
with a undefined `texture`.

Expected parameters include:

- `renderer` - the rendering context
- `texture` - the targeted texture, which must be created with the `SDL_TEXTUREACCESS_TARGET` flag, or undef to render to the window instead of a texture.

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetRenderTarget( ... )`

Get the current render target.

        my $texture = SDL_GetRenderTarget( $renderer );

The default render target is the window for which the renderer was created, and
is reported an undefined value here.

Expected parameters include:

- `renderer` - the rendering context

Returns the current render target or undef for the default render target.

## `SDL_RenderSetLogicalSize( ... )`

Set a device independent resolution for rendering.

        SDL_RenderSetLogicalSize( $renderer, 100, 100 );

This function uses the viewport and scaling functionality to allow a fixed
logical resolution for rendering, regardless of the actual output resolution.
If the actual output resolution doesn't have the same aspect ratio the output
rendering will be centered within the output display.

If the output display is a window, mouse and touch events in the window will be
filtered and scaled so they seem to arrive within the logical resolution.

If this function results in scaling or subpixel drawing by the rendering
backend, it will be handled using the appropriate quality hints.

Expected parameters include:

- `renderer` - the renderer for which resolution should be set
- `w` - the width of the logical resolution
- `h` - the height of the logical resolution

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderGetLogicalSize( ... )`

Get device independent resolution for rendering.

        my ($w, $h) = SDL_RenderGetLogicalSize( $renderer );

This may return `0` for `w` and `h` if the [SDL2::Renderer](https://metacpan.org/pod/SDL2%3A%3ARenderer) has never had
its logical size set by [`SDL_RenderSetLogicalSize( ...
)`](#sdl_rendersetlogicalsize) and never had a render target set.

Expected parameters include:

- `renderer` - a rendering context

Returns the width and height.

## `SDL_RenderSetIntegerScale( ... )`

Set whether to force integer scales for resolution-independent rendering.

        SDL_RenderSetIntegerScale( $renderer, 1 );

This function restricts the logical viewport to integer values - that is, when
a resolution is between two multiples of a logical size, the viewport size is
rounded down to the lower multiple.

Expected parameters include:

- `renderer` - the renderer for which integer scaling should be set
- `enable` - enable or disable the integer scaling for rendering

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderGetIntegerScale( ... )`

Get whether integer scales are forced for resolution-independent rendering.

        SDL_RenderGetIntegerScale( $renderer );

Expected parameters include:

- `renderer` - the renderer from which integer scaling should be queried

Returns true if integer scales are forced or false if not and on failure; call
[`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderSetViewport( ... )`

Set the drawing area for rendering on the current target.

        SDL_RenderSetViewport( $renderer, $rect );

When the window is resized, the viewport is reset to fill the entire new window
size.

Expected parameters include:

- `renderer` - the rendering context
- `rect` - the [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure representing the drawing area, or undef to set the viewport to the entire target

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderGetViewport( ... )`

Get the drawing area for the current target.

        my $rect = SDL_RenderGetViewport( $renderer );

Expected parameters include:

- `renderer` - the rendering context

Returns an [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure filled in with the current drawing area.

## `SDL_RenderSetClipRect( ... )`

Set the clip rectangle for rendering on the specified target.

        SDL_RenderSetClipRect( $renderer, $rect );

Expected parameters include:

- `renderer` - the rendering context for which clip rectangle should be set
- `rect` - an [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure representing the clip area, relative to the viewport, or undef to disable clipping

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderGetClipRect( ... )`

Get the clip rectangle for the current target.

        my $rect = SDL_RenderGetClipRect( $renderer );

Expected parameters include:

- `renderer` - the rendering context from which clip rectangle should be queried

Returns an [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure filled in with the current clipping area or
an empty rectangle if clipping is disabled.

## `SDL_RenderIsClipEnabled( ... )`

Get whether clipping is enabled on the given renderer.

        my $tf = SDL_RenderIsClipEnabled( $renderer );

Expected parameters include:

- `renderer` - the renderer from which clip state should be queried

Returns true if clipping is enabled or false if not; call [`SDL_GetError(
)`](#sdl_geterror)( ) for more information.

## `SDL_RenderSetScale( ... )`

Set the drawing scale for rendering on the current target.

        SDL_RenderSetScale( $renderer, .5, 1 );

The drawing coordinates are scaled by the x/y scaling factors before they are
used by the renderer. This allows resolution independent drawing with a single
coordinate system.

If this results in scaling or subpixel drawing by the rendering backend, it
will be handled using the appropriate quality hints. For best results use
integer scaling factors.

Expected parameters include:

- `renderer` - a rendering context
- `scaleX` - the horizontal scaling factor
- `scaleY` - the vertical scaling factor

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderGetScale( ... )`

Get the drawing scale for the current target.

        my ($scaleX, $scaleY) = SDL_RenderGetScale( $renderer );

Expected parameters include:

- `renderer` - the renderer from which drawing scale should be queried

Returns the horizonal and vertical scaling factors.

## `SDL_SetRenderDrawColor( ... )`

Set the color used for drawing operations (Rect, Line and Clear).

        SDL_SetRenderDrawColor( $renderer, 0, 0, 128, SDL_ALPHA_OPAQUE );

Set the color for drawing or filling rectangles, lines, and points, and for [`SDL_RenderClear( ... )`](#sdl_renderclear).

Expected parameters include:

- `renderer` - the rendering context
- `r` - the red value used to draw on the rendering target
- `g` - the green value used to draw on the rendering target
- `b` - the blue value used to draw on the rendering target
- `a` - the alpha value used to draw on the rendering target; usually `SDL_ALPHA_OPAQUE` (255). Use `SDL_SetRenderDrawBlendMode` to specify how the alpha channel is used

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetRenderDrawColor( ... )`

Get the color used for drawing operations (Rect, Line and Clear).

        my ($r, $g, $b, $a) = SDL_GetRenderDrawColor( $renderer );

Expected parameters include:

- `renderer` - the rendering context

Returns red, green, blue, and alpha values on success or a negative error code
on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more
information.

## `SDL_SetRenderDrawBlendMode( ... )`

Set the blend mode used for drawing operations (Fill and Line).

        SDL_SetRenderDrawBlendMode( $renderer, SDL_BLENDMODE_BLEND );

If the blend mode is not supported, the closest supported mode is chosen.

Expected parameters include:

- `renderer` - the rendering context
- `blendMode` - the [`:blendMode`](#blendmode) to use for blending

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetRenderDrawBlendMode( ... )`

Get the blend mode used for drawing operations.

        my $blendMode = SDL_GetRenderDrawBlendMode( $rendering );

Expected parameters include:

- `renderer` - the rendering context

Returns the current `:blendMode` on success or a negative error code on
failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more
information.

## `SDL_RenderClear( ... )`

Clear the current rendering target with the drawing color.

        SDL_RenderClear( $renderer );

This function clears the entire rendering target, ignoring the viewport and the
clip rectangle.

- `renderer` - the rendering context

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderDrawPoint( ... )`

Draw a point on the current rendering target.

        SDL_RenderDrawPoint( $renderer, 100, 100 );

`SDL_RenderDrawPoint( ... )` draws a single point. If you want to draw
multiple, use [`SDL_RenderDrawPoints( ... )`](#sdl_renderdrawpoints) instead.

Expected parameters include:

- `renderer` - the rendering context
- `x` - the x coordinate of the point
- `y` - the y coordinate of the point

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderDrawPoints( ... )`

Draw multiple points on the current rendering target.

        my @points = map { SDL2::Point->new( {x => int rand, y => int rand } ) } 1..1024;
        SDL_RenderDrawPoints( $renderer, @points );

- `renderer` - the rendering context
- `points` - an array of [SDL2::Point](https://metacpan.org/pod/SDL2%3A%3APoint) structures that represent the points to draw

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderDrawLine( ... )`

Draw a line on the current rendering target.

        SDL_RenderDrawLine( $renderer, 300, 240, 340, 240 );

`SDL_RenderDrawLine( ... )` draws the line to include both end points. If you
want to draw multiple, connecting lines use [`SDL_RenderDrawLines( ...
)`](#sdl_renderdrawlines) instead.

Expected parameters include:

- `renderer` - the rendering context
- `x1` - the x coordinate of the start point
- `y1` - the y coordinate of the start point
- `x2` - the x coordinate of the end point
- `y2` - the y coordinate of the end point

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderDrawLines( ... )`

Draw a series of connected lines on the current rendering target.

        SDL_RenderDrawLines( $renderer, @points);

Expected parameters include:

- `renderer` - the rendering context
- `points` - an array of [SDL2::Point](https://metacpan.org/pod/SDL2%3A%3APoint) structures representing points along the lines

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderDrawRect( ... )`

Draw a rectangle on the current rendering target.

        SDL_RenderDrawRect( $renderer, SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ) );

Expected parameters include:

- `renderer` - the rendering context
- `rect` - an [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure representing the rectangle to draw

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderDrawRects( ... )`

Draw some number of rectangles on the current rendering target.

        SDL_RenderDrawRects( $renderer,
                SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ),
        SDL2::Rect->new( { x => 75,  y => 75,  w => 50,  h => 50 } )
    );

Expected parameters include:

- `renderer` - the rendering context
- `rects` - an array of SDL2::Rect structures representing the rectangles to be drawn

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderFillRect( ... )`

Fill a rectangle on the current rendering target with the drawing color.

        SDL_RenderFillRect( $renderer, SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ) );

The current drawing color is set by [`SDL_SetRenderDrawColor( ...
)`](#sdl_setrenderdrawcolor), and the color's alpha value is ignored
unless blending is enabled with the appropriate call to [`SDL_SetRenderDrawBlendMode( ... )`](#sdl_setrenderdrawblendmode).

Expected parameters include:

- `renderer` - the rendering context
- `rect` - the [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure representing the rectangle to fill

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderFillRects( ... )`

Fill some number of rectangles on the current rendering target with the drawing
color.

        SDL_RenderFillRects( $renderer,
                SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ),
        SDL2::Rect->new( { x => 75,  y => 75,  w => 50,  h => 50 } )
    );

Expected parameters include:

- `renderer` - the rendering context
- `rects` - an array of [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structures representing the rectangles to be filled

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderCopy( ... )`

Copy a portion of the texture to the current rendering target.

        SDL_RenderCopy( $renderer, $blueShapes, $srcR, $destR );

The texture is blended with the destination based on its blend mode set with
[`SDL_SetTextureBlendMode( ... )`](#sdl_settextureblendmode).

The texture color is affected based on its color modulation set by [`SDL_SetTextureColorMod( ... )`](#sdl_settexturecolormod).

The texture alpha is affected based on its alpha modulation set by [`SDL_SetTextureAlphaMod( ... )`](#sdl_settexturealphamod).

Expected parameters include:

- `renderer` - the rendering context
- `texture` - the source texture
- `srcrect` - the source [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure
- `dstrect` - the destination [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure; the texture will be stretched to fill the given rectangle

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderCopyEx( ... )`

Copy a portion of the texture to the current rendering, with optional rotation
and flipping.

Copy a portion of the texture to the current rendering target, optionally
rotating it by angle around the given center and also flipping it top-bottom
and/or left-right.

The texture is blended with the destination based on its blend mode set with
[`SDL_SetTextureBlendMode( ... )`](#sdl_settextureblendmode).

The texture color is affected based on its color modulation set by [`SDL_SetTextureColorMod( ... )`](#sdl_settexturecolormod).

The texture alpha is affected based on its alpha modulation set by [`SDL_SetTextureAlphaMod( ... )`](#sdl_settexturealphamod).

Expected parameters include:

- `renderer` - the rendering context
- `texture` - the source texture
- `srcrect` - the source [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure
- `dstrect` - the destination SDL\_Rect structure
- `angle` - an angle in degrees that indicates the rotation that will be applied to dstrect, rotating it in a clockwise direction
- `center` - a pointer to a point indicating the point around which dstrect will be rotated (if NULL, rotation will be done around `dstrect.w / 2`, `dstrect.h / 2`)
- `flip` - a [:rendererFlip](https://metacpan.org/pod/%3ArendererFlip) value stating which flipping actions should be performed on the texture

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderDrawPointF( ... )`

Draw a point on the current rendering target at subpixel precision.

        SDL_RenderDrawPointF( $renderer, 25.5, 100.25 );

Expected parameters include:

- `renderer` - The renderer which should draw a point.
- `x` - The x coordinate of the point.
- `y` - The y coordinate of the point.

Returns `0` on success, or `-1` on error

## `SDL_RenderDrawPointsF( ... )`

Draw multiple points on the current rendering target at subpixel precision.

        my @points = map { SDL2::Point->new( {x => int rand, y => int rand } ) } 1..1024;
        SDL_RenderDrawPointsF( $renderer, @points );

Expected parameters include:

- `renderer` - The renderer which should draw multiple points
- `points` - The points to draw

Returns `0` on success, or `-1` on error; call [`SDL_GetError(
)`](#sdl_geterror)( ) for more information.

## `SDL_RenderDrawLineF( ... )`

Draw a line on the current rendering target at subpixel precision.

        SDL_RenderDrawLineF( $renderer, 100, 100, 250, 100);

Expected parameters include:

- `renderer` - The renderer which should draw a line.
- `x1` - The x coordinate of the start point.
- `y1` - The y coordinate of the start point.
- `x2` - The x coordinate of the end point.
- `y2` - The y coordinate of the end point.

Returns `0` on success, or `-1` on error.

## `SDL_RenderDrawLinesF( ... )`

Draw a series of connected lines on the current rendering target at subpixel
precision.

        SDL_RenderDrawLines( $renderer, @points);

Expected parameters include:

- `renderer` - The renderer which should draw multiple lines.
- `points` - The points along the lines

Return `0` on success, or `-1` on error.

## `SDL_RenderDrawRectF( ... )`

Draw a rectangle on the current rendering target at subpixel precision.

        SDL_RenderDrawRectF( $renderer, $point);

Expected parameters include:

- `renderer` - The renderer which should draw a rectangle.
- `rect` - A pointer to the destination rectangle

Returns `0` on success, or `-1` on error

## `SDL_RenderDrawRectsF( ... )`

Draw some number of rectangles on the current rendering target at subpixel
precision.

        SDL_RenderDrawRectsF( $renderer,
                SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ),
        SDL2::Rect->new( { x => 75,  y => 75,  w => 50,  h => 50 } )
    );

Expected parameters include:

- `renderer` - The renderer which should draw multiple rectangles.
- `rects` - A pointer to an array of destination rectangles.

Returns `0` on success, or `-1` on error.

## `SDL_RenderFillRectF( ... )`

Fill a rectangle on the current rendering target with the drawing color at
subpixel precision.

        SDL_RenderFillRectF( $renderer,
        SDL2::Rect->new( { x => 75,  y => 75,  w => 50,  h => 50 } )
    );

Expected parameters include:

- `renderer` - The renderer which should fill a rectangle.
- `rect` - A pointer to the destination rectangle

Returns `0` on success, or `-1` on error.

## `SDL_RenderFillRectsF( ... )`

Fill some number of rectangles on the current rendering target with the drawing
color at subpixel precision.

        SDL_RenderFillRectsF( $renderer,
                SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ),
        SDL2::Rect->new( { x => 75,  y => 75,  w => 50,  h => 50 } )
    );

Expected parameters include:

- `renderer` - The renderer which should fill multiple rectangles.
- `rects` - A pointer to an array of destination rectangles.

Returns `0` on success, or `-1` on error.

## `SDL_RenderCopyF( ... )`

Copy a portion of the texture to the current rendering target at subpixel
precision.

Expected parameters include:

- `renderer` - The renderer which should copy parts of a texture
- `texture` - The source texture
- `srcrect` - A pointer to the source rectangle
- `dstrect` - A pointer to the destination rectangle

Returns `0` on success, or `-1` on error.

## `SDL_RenderCopyExF( ... )`

Copy a portion of the source texture to the current rendering target, with
rotation and flipping, at subpixel precision.

- `renderer` - The renderer which should copy parts of a texture
- `texture` - The source texture
- `srcrect` - A pointer to the source rectangle
- `dstrect` - A pointer to the destination rectangle
- `angle` - An angle in degrees that indicates the rotation that will be applied to dstrect, rotating it in a clockwise direction
- `center` - A pointer to a point indicating the point around which dstrect will be rotated (if NULL, rotation will be done around `dstrect.w/2`, `dstrect.h/2`)
- `flip` - A `:rendererFlip` value stating which flipping actions should be performed on the texture

Returns `0` on success, or `-1` on error

## `SDL_RenderReadPixels( ... )`

Read pixels from the current rendering target to an array of pixels.

        SDL_RenderReadPixels(
        $renderer,
        SDL2::Rect->new( { x => 0, y => 0, w => 640, h => 480 } ),
        SDL_PIXELFORMAT_RGB888,
        $surface->pixels, $surface->pitch
    );

**WARNING**: This is a very slow operation, and should not be used frequently.

`pitch` specifies the number of bytes between rows in the destination
`pixels` data. This allows you to write to a subrectangle or have padded rows
in the destination. Generally, `pitch` should equal the number of pixels per
row in the \`pixels\` data times the number of bytes per pixel, but it might
contain additional padding (for example, 24bit RGB Windows Bitmap data pads all
rows to multiples of 4 bytes).

Expected parameters include:

- `renderer` - the rendering context
- `rect` - an [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure representing the area to read
- `format` - an `:pixelFormatEnum` value of the desired format of the pixel data, or `0` to use the format of the rendering target
- `pixels` - pointer to the pixel data to copy into
- `pitch` - the pitch of the `pixels` parameter

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderPresent( ... )`

Update the screen with any rendering performed since the previous call.

        SDL_RenderPresent( $renderer );

SDL's rendering functions operate on a backbuffer; that is, calling a rendering
function such as [`SDL_RenderDrawLine( ... )`](#sdl_renderdrawline) does not directly put a line on the screen, but rather updates the
backbuffer. As such, you compose your entire scene and \*present\* the composed
backbuffer to the screen as a complete picture.

Therefore, when using SDL's rendering API, one does all drawing intended for
the frame, and then calls this function once per frame to present the final
drawing to the user.

The backbuffer should be considered invalidated after each present; do not
assume that previous contents will exist between frames. You are strongly
encouraged to call [`SDL_RenderClear( ... )`](#sdl_renderclear)
to initialize the backbuffer before starting each new frame's drawing, even if
you plan to overwrite every pixel.

Expected parameters include:

- `renderer` - the rendering context

## `SDL_DestroyTexture( ... )`

Destroy the specified texture.

        SDL_DestroyTexture( $texture );

Passing undef or an otherwise invalid texture will set the SDL error message to
"Invalid texture".

Expected parameters include:

- `texture` - the texture to destroy

## `SDL_DestroyRenderer( ... )`

Destroy the rendering context for a window and free associated textures.

        SDL_DestroyRenderer( $renderer );

Expected parameters include:

- `renderer` - the rendering context

## `SDL_RenderFlush( ... )`

Force the rendering context to flush any pending commands to the underlying
rendering API.

        SDL_RenderFlush( $renderer );

You do not need to (and in fact, shouldn't) call this function unless you are
planning to call into OpenGL/Direct3D/Metal/whatever directly in addition to
using an SDL\_Renderer.

This is for a very-specific case: if you are using SDL's render API, you asked
for a specific renderer backend (OpenGL, Direct3D, etc), you set
`SDL_HINT_RENDER_BATCHING` to "`1`", and you plan to make OpenGL/D3D/whatever
calls in addition to SDL render API calls. If all of this applies, you should
call [`SDL_RenderFlush( ... )`](#sdl_renderflush) between calls
to SDL's render API and the low-level API you're using in cooperation.

In all other cases, you can ignore this function. This is only here to get
maximum performance out of a specific situation. In all other cases, SDL will
do the right thing, perhaps at a performance loss.

This function is first available in SDL 2.0.10, and is not needed in 2.0.9 and
earlier, as earlier versions did not queue rendering commands at all, instead
flushing them to the OS immediately.

Expected parameters include:

- `renderer` - the rendering context

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GL_BindTexture( ... )`

Bind an OpenGL/ES/ES2 texture to the current context.

        my ($texw, $texh) = SDL_GL_BindTexture( $texture );

This is for use with OpenGL instructions when rendering OpenGL primitives
directly.

If not NULL, the returned width and height values suitable for the provided
texture. In most cases, both will be `1.0`, however, on systems that support
the GL\_ARB\_texture\_rectangle extension, these values will actually be the pixel
width and height used to create the texture, so this factor needs to be taken
into account when providing texture coordinates to OpenGL.

You need a renderer to create an [SDL2::Texture](https://metacpan.org/pod/SDL2%3A%3ATexture), therefore you can only use
this function with an implicit OpenGL context from [`SDL_CreateRenderer(
... )`](#sdl_createrenderer), not with your own OpenGL context. If
you need control over your OpenGL context, you need to write your own
texture-loading methods.

Also note that SDL may upload RGB textures as BGR (or vice-versa), and re-order
the color channels in the shaders phase, so the uploaded texture may have
swapped color channels.

Expected parameters include:

- `texture` - the texture to bind to the current OpenGL/ES/ES2 context

Returns the texture's with and height on success, or -1 if the operation is not
supported; call [`SDL_GetError( )`](#sdl_geterror)( ) for more
information.

## `SDL_GL_UnbindTexture( ... )`

Unbind an OpenGL/ES/ES2 texture from the current context.

        SDL_GL_UnbindTexture( $texture );

See [`SDL_GL_BindTexture( ... )`](#sdl_gl_bindtexture) for
examples on how to use these functions.

Expected parameters include:

- `texture` - the texture to unbind from the current OpenGL/ES/ES2 context

Returns `0` on success, or `-1` if the operation is not supported.

## `SDL_RenderGetMetalLayer( ... )`

Get the CAMetalLayer associated with the given Metal renderer.

        my $opaque = SDL_RenderGetMetalLayer( $renderer );

This function returns `void *`, so SDL doesn't have to include Metal's
headers, but it can be safely cast to a `CAMetalLayer *`.

Expected parameters include:

- `renderer` - the renderer to query

Returns `CAMetalLayer*` on success, or undef if the renderer isn't a Metal
renderer.

## `SDL_RenderGetMetalCommandEncoder( ... )`

Get the Metal command encoder for the current frame

        $opaque = SDL_RenderGetMetalCommandEncoder( $renderer );

This function returns `void *`, so SDL doesn't have to include Metal's
headers, but it can be safely cast to an
`id<MTLRenderCommandEncoder>`.

Expected parameters include:

- `renderer` - the renderer to query

Returns `id<MTLRenderCommandEncoder>` on success, or undef if the
renderer isn't a Metal renderer.

## `SDL_ComposeCustomBlendMode( ... )`

Compose a custom blend mode for renderers.

The functions SDL\_SetRenderDrawBlendMode and SDL\_SetTextureBlendMode accept the
SDL\_BlendMode returned by this function if the renderer supports it.

A blend mode controls how the pixels from a drawing operation (source) get
combined with the pixels from the render target (destination). First, the
components of the source and destination pixels get multiplied with their blend
factors. Then, the blend operation takes the two products and calculates the
result that will get stored in the render target.

Expressed in pseudocode, it would look like this:

        my $dstRGB = colorOperation( $srcRGB * $srcColorFactor, $dstRGB * $dstColorFactor );
        my $dstA   = alphaOperation( $srcA * $srcAlphaFactor, $dstA * $dstAlphaFactor );

Where the functions `colorOperation(src, dst)` and `alphaOperation(src, dst)`
can return one of the following:

- `src + dst`
- `src - dst`
- `dst - src`
- `min(src, dst)`
- `max(src, dst)`

The red, green, and blue components are always multiplied with the first,
second, and third components of the SDL\_BlendFactor, respectively. The fourth
component is not used.

The alpha component is always multiplied with the fourth component of the [`:blendFactor`](#blendfactor). The other components are not used in the
alpha calculation.

Support for these blend modes varies for each renderer. To check if a specific
[`:blendMode`](#blendmode) is supported, create a renderer and pass it
to either `SDL_SetRenderDrawBlendMode` or `SDL_SetTextureBlendMode`. They
will return with an error if the blend mode is not supported.

This list describes the support of custom blend modes for each renderer in SDL
2.0.6. All renderers support the four blend modes listed in the [`:blendMode`](#blendmode) enumeration.

- **direct3d** - Supports `SDL_BLENDOPERATION_ADD` with all factors.
- **direct3d11** - Supports all operations with all factors. However, some factors produce unexpected results with `SDL_BLENDOPERATION_MINIMUM` and `SDL_BLENDOPERATION_MAXIMUM`.
- **opengl** - Supports the `SDL_BLENDOPERATION_ADD` operation with all factors. OpenGL versions 1.1, 1.2, and 1.3 do not work correctly with SDL 2.0.6.
- **opengles** - Supports the `SDL_BLENDOPERATION_ADD` operation with all factors. Color and alpha factors need to be the same. OpenGL ES 1 implementation specific: May also support `SDL_BLENDOPERATION_SUBTRACT` and `SDL_BLENDOPERATION_REV_SUBTRACT`. May support color and alpha operations being different from each other. May support color and alpha factors being different from each other.
- **opengles2** - Supports the `SDL_BLENDOPERATION_ADD`, `SDL_BLENDOPERATION_SUBTRACT`, `SDL_BLENDOPERATION_REV_SUBTRACT` operations with all factors.
- **psp** - No custom blend mode support.
- **software** - No custom blend mode support.

Some renderers do not provide an alpha component for the default render target.
The `SDL_BLENDFACTOR_DST_ALPHA` and `SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA`
factors do not have an effect in this case.

Expected parameters include:

- `srcColorFactor` -the `:blendFactor` applied to the red, green, and blue components of the source pixels
- `dstColorFactor` - the `:blendFactor` applied to the red, green, and blue components of the destination pixels
- `colorOperation` - the `:blendOperation` used to combine the red, green, and blue components of the source and destination pixels
- `srcAlphaFactor` - the `:blendFactor` applied to the alpha component of the source pixels
- `dstAlphaFactor` - the `:blendFactor` applied to the alpha component of the destination pixels
- `alphaOperation` - the `:blendOperation` used to combine the alpha component of the source and destination pixels

Returns a `:blendMode` that represents the chosen factors and operations.

# Time Management Routines

This section contains functions for handling the SDL time management routines.
They may be imported with the `:timer` tag.

## `SDL_GetTicks( )`

Get the number of milliseconds since SDL library initialization.

        my $time = SDL_GetTicks( );

This value wraps if the program runs for more than `~49` days.

Returns an unsigned 32-bit value representing the number of milliseconds since
the SDL library initialized.

## `SDL_GetPerformanceCounter( )`

Get the current value of the high resolution counter.

        my $high_timer = SDL_GetPerformanceCounter( );

This function is typically used for profiling.

The counter values are only meaningful relative to each other. Differences
between values can be converted to times by using [`SDL_GetPerformanceFrequency( )`](#sdl_getperformancefrequency).

Returns the current counter value.

## `SDL_GetPerformanceFrequency( ... )`

Get the count per second of the high resolution counter.

        my $hz = SDL_GetPerformanceFrequency( );

Returns a platform-specific count per second.

## `SDL_Delay( ... )`

Wait a specified number of milliseconds before returning.

        SDL_Delay( 1000 );

This function waits a specified number of milliseconds before returning. It
waits at least the specified time, but possibly longer due to OS scheduling.

Expected parameters include:

- `ms` - the number of milliseconds to delay

## `SDL_AddTimer( ... )`

Call a callback function at a future time.

    my $id = SDL_AddTimer( 1000, sub ( $interval, $data ) { warn 'ping!'; $interval; } );

If you use this function, you must pass `SDL_INIT_TIMER` to [`SDL_Init(
... )`](#sdl_init).

The callback function is passed the current timer interval and returns the next
timer interval. If the returned value is the same as the one passed in, the
periodic alarm continues, otherwise a new alarm is scheduled. If the callback
returns `0`, the periodic alarm is cancelled.

The callback is run on a separate thread.

Timers take into account the amount of time it took to execute the callback.
For example, if the callback took 250 ms to execute and returned 1000 (ms), the
timer would only wait another 750 ms before its next iteration.

Timing may be inexact due to OS scheduling. Be sure to note the current time
with [`SDL_GetTicks( )`](#sdl_getticks) or  [`SDL_GetPerformanceCounter( )`](#sdl_getperformancecounter) in case
your callback needs to adjust for variances.

Expected parameters include:

- `interval` - the timer delay, in milliseconds, passed to `callback`
- `callback` - the `CODE` reference to call when the specified `interval` elapses
- `param` - a pointer that is passed to `callback`

Returns a timer ID or `0` if an error occurs; call [`SDL_GetError(
)`](#sdl_geterror)( ) for more information.

## `SDL_RemoveTimer( ... )`

        SDL_RemoveTimer( $id );

Remove a timer created with [`SDL_AddTimer( ... )`](#sdl_addtimer).

Expected parameters include:

- `id` - the ID of the timer to remove

Returns true if the timer is removed or false if the timer wasn't found.

# Raw Audio Mixing

These methods provide access to the raw audio mixing buffer for the SDL
library. They may be imported with the `:audio` tag.

## `SDL_GetNumAudioDrivers( )`

Returns a list of built in audio drivers, in the order that they were normally
initialized by default.

## `SDL_GetAudioDriver( ... )`

Returns an audio driver by name.

        my $driver = SDL_GetAudioDriver( 1 );

Expected parameters include:

- `index` - The zero-based index of the desired audio driver

## `SDL_AudioInit( ... )`

Audio system initialization.

        SDL_AudioInit( 'pulseaudio' );

This method is used internally, and should not be used unless you have a
specific need to specify the audio driver you want to use. You should normally
use [`SDL_Init( ... )`](#sdl_init).

Returns `0` on success.

## `SDL_AudioQuit( )`

Cleaning up initialized audio system.

        SDL_AudioQuit( );

This method is used internally, and should not be used unless you have a
specific need to close the selected audio driver. You should normally use [`SDL_Quit( )`](#sdl_quit).

## `SDL_GetCurrentAudioDriver( )`

Get the name of the current audio driver.

        my $driver = SDL_GetCurrentAudioDriver( );

The returned string points to internal static memory and thus never becomes
invalid, even if you quit the audio subsystem and initialize a new driver
(although such a case would return a different static string from another call
to this function, of course). As such, you should not modify or free the
returned string.

Returns the name of the current audio driver or undef if no driver has been
initialized.

## `SDL_OpenAudio( ... )`

This function is a legacy means of opening the audio device.

    my $obtained = SDL_OpenAudio(
        SDL2::AudioSpec->new( { freq => 48000, channels => 2, format => AUDIO_F32 } ) );

This function remains for compatibility with SDL 1.2, but also because it's
slightly easier to use than the new functions in SDL 2.0. The new, more
powerful, and preferred way to do this is [`SDL_OpenAudioDevice( ...
)`](#sdl_openaudiodevice) .

This function is roughly equivalent to:

        SDL_OpenAudioDevice( (), 0, $desired, SDL_AUDIO_ALLOW_ANY_CHANGE );

With two notable exceptions:

- - If `obtained` is undefined, we use `desired` (and allow no changes), which
means desired will be modified to have the correct values for silence,
etc, and SDL will convert any differences between your app's specific
request and the hardware behind the scenes.
- - The return value is always success or failure, and not a device ID, which
means you can only have one device open at a time with this function.

    * \param desired an SDL_AudioSpec structure representing the desired output
    *                format. Please refer to the SDL_OpenAudioDevice documentation
    *                for details on how to prepare this structure.
    * \param obtained an SDL_AudioSpec structure filled in with the actual
    *                 parameters, or NULL.
    * \returns This function opens the audio device with the desired parameters,
    *          and returns 0 if successful, placing the actual hardware
    *          parameters in the structure pointed to by `obtained`.
    *
    *          If `obtained` is NULL, the audio data passed to the callback
    *          function will be guaranteed to be in the requested format, and
    *          will be automatically converted to the actual hardware audio
    *          format if necessary. If `obtained` is NULL, `desired` will
    *          have fields modified.
    *
    *          This function returns a negative error code on failure to open the
    *          audio device or failure to set up the audio thread; call
    *          SDL_GetError() for more information.

# Constants/Imports

This list of constants may be imported by name or with their related tags.
Here, we've organized them by their import tag.

## `:init`

These are the flags which may be passed to [`SDL_Init( ... )`](#sdl_init). You should specify the subsystems which you will be using in your
application.

- `SDL_INIT_TIMER` - Timer subsystem.
- `SDL_INIT_AUDIO` -Audio subsystem.
- `SDL_INIT_VIDEO` - Video subsystem. Automatically initializes the events subsystem.
- `SDL_INIT_JOYSTICK` - Joystick subsystem. Automatically initializes the events subsystem.
- `SDL_INIT_HAPTIC` - Haptic (force feedback) subsystem.
- `SDL_INIT_GAMECONTROLLER` - Controller subsystem. Automatically initializes the joystick subsystem.
- `SDL_INIT_EVENTS` - Events subsystem.
- `SDL_INIT_EVERYTHING` - All of the above subsystems.
- `SDL_INIT_SENSOR`
- `SDL_INIT_NOPARACHUTE` - Compatibility; this flag is ignored.

## `:hints`

- `SDL_HINT_DEFAULT` - low priority, used for default values
- `SDL_HINT_NORMAL` - medium priority
- `SDL_HINT_OVERRIDE` - high priority

## SDL\_Hint

These enum values can be passed to [Configuration Variable](https://metacpan.org/pod/SDL2#Configuration-Variables) related functions.

- `SDL_HINT_ACCELEROMETER_AS_JOYSTICK`

    A hint that specifies whether the Android / iOS built-in accelerometer should
    be listed as a joystick device, rather than listing actual joysticks only.

    Values:

        0   list only real joysticks and accept input from them
        1   list real joysticks along with the accelorometer as if it were a 3 axis joystick (the default)

    Example:

        # This disables the use of gyroscopes as axis device
        SDL_SetHint(SDL_HINT_ACCELEROMETER_AS_JOYSTICK, "0");

- `SDL_HINT_ANDROID_APK_EXPANSION_MAIN_FILE_VERSION`

    A hint that specifies the Android APK expansion main file version.

    Values:

        X   the Android APK expansion main file version (should be a string number like "1", "2" etc.)

    This hint must be set together with the hint
    `SDL_HINT_ANDROID_APK_EXPANSION_PATCH_FILE_VERSION`.

    If both hints were set then `SDL_RWFromFile( )` will look into expansion files
    after a given relative path was not found in the internal storage and assets.

    By default this hint is not set and the APK expansion files are not searched.

- `SDL_HINT_ANDROID_APK_EXPANSION_PATCH_FILE_VERSION`

    A hint that specifies the Android APK expansion patch file version.

    Values:

        X   the Android APK expansion patch file version (should be a string number like "1", "2" etc.)

    This hint must be set together with the hint
    `SDL_HINT_ANDROID_APK_EXPANSION_MAIN_FILE_VERSION`.

    If both hints were set then `SDL_RWFromFile( )` will look into expansion files
    after a given relative path was not found in the internal storage and assets.

    By default this hint is not set and the APK expansion files are not searched.

- `SDL_HINT_ANDROID_SEPARATE_MOUSE_AND_TOUCH`

    A hint that specifies a variable to control whether mouse and touch events are
    to be treated together or separately.

    Values:

        0   mouse events will be handled as touch events and touch will raise fake mouse events (default)
        1   mouse events will be handled separately from pure touch events

    By default mouse events will be handled as touch events and touch will raise
    fake mouse events.

    The value of this hint is used at runtime, so it can be changed at any time.

- `SDL_HINT_APPLE_TV_CONTROLLER_UI_EVENTS`

    A hint that specifies whether controllers used with the Apple TV generate UI
    events.

    Values:

        0   controller input does not gnerate UI events (default)
        1   controller input generates UI events

    When UI events are generated by controller input, the app will be backgrounded
    when the Apple TV remote's menu button is pressed, and when the pause or B
    buttons on gamepads are pressed.

    More information about properly making use of controllers for the Apple TV can
    be found here:
    https://developer.apple.com/tvos/human-interface-guidelines/remote-and-controllers/

- `SDL_HINT_APPLE_TV_REMOTE_ALLOW_ROTATION`

    A hint that specifies whether the Apple TV remote's joystick axes will
    automatically match the rotation of the remote.

    Values:

        0   remote orientation does not affect joystick axes (default)
        1   joystick axes are based on the orientation of the remote

- `SDL_HINT_BMP_SAVE_LEGACY_FORMAT`

    A hint that specifies whether SDL should not use version 4 of the bitmap header
    when saving BMPs.

    Values:

        0   version 4 of the bitmap header will be used when saving BMPs (default)
        1   version 4 of the bitmap header will not be used when saving BMPs

    The bitmap header version 4 is required for proper alpha channel support and
    SDL will use it when required. Should this not be desired, this hint can force
    the use of the 40 byte header version which is supported everywhere.

    If the hint is not set then surfaces with a colorkey or an alpha channel are
    saved to a 32-bit BMP file with an alpha mask. SDL will use the bitmap header
    version 4 and set the alpha mask accordingly. This is the default behavior
    since SDL 2.0.5.

    If the hint is set then surfaces with a colorkey or an alpha channel are saved
    to a 32-bit BMP file without an alpha mask. The alpha channel data will be in
    the file, but applications are going to ignore it. This was the default
    behavior before SDL 2.0.5.

- `SDL_HINT_EMSCRIPTEN_ASYNCIFY`

    A hint that specifies if SDL should give back control to the browser
    automatically when running with asyncify.

    Values:

        0   disable emscripten_sleep calls (if you give back browser control manually or use asyncify for other purposes)
        1   enable emscripten_sleep calls (default)

    This hint only applies to the Emscripten platform.

- `SDL_HINT_EMSCRIPTEN_KEYBOARD_ELEMENT`

    A hint that specifies a value to override the binding element for keyboard
    inputs for Emscripten builds.

    Values:

        #window     the JavaScript window object (default)
        #document   the JavaScript document object
        #screen     the JavaScript window.screen object
        #canvas     the default WebGL canvas element

    Any other string without a leading # sign applies to the element on the page
    with that ID.

    This hint only applies to the Emscripten platform.

- `SDL_HINT_FRAMEBUFFER_ACCELERATION`

    A hint that specifies how 3D acceleration is used with [SDL\_GetWindowSurface(
    ... )](https://metacpan.org/pod/SDL2#SDL_GetWindowSurface).

    Values:

        0   disable 3D acceleration
        1   enable 3D acceleration, using the default renderer
        X   enable 3D acceleration, using X where X is one of the valid rendering drivers. (e.g. "direct3d", "opengl", etc.)

    By default SDL tries to make a best guess whether to use acceleration or not on
    each platform.

    SDL can try to accelerate the screen surface returned by
    [SDL\_GetWindowSurface( ... )](https://metacpan.org/pod/SDL2#SDL_GetWindowSurface) by using
    streaming textures with a 3D rendering engine. This variable controls whether
    and how this is done.

- `SDL_HINT_GAMECONTROLLERCONFIG`

    A variable that lets you provide a file with extra gamecontroller db entries.

    This hint must be set before calling `SDL_Init(SDL_INIT_GAMECONTROLLER)`.

    You can update mappings after the system is initialized with
    `SDL_GameControllerMappingForGUID( )` and `SDL_GameControllerAddMapping( )`.

- `SDL_HINT_GRAB_KEYBOARD`

    A variable setting the double click time, in milliseconds.

- `SDL_HINT_IDLE_TIMER_DISABLED`

    A hint that specifies a variable controlling whether the idle timer is disabled
    on iOS.

    Values:

        0   enable idle timer (default)
        1   disable idle timer

    When an iOS application does not receive touches for some time, the screen is
    dimmed automatically. For games where the accelerometer is the only input this
    is problematic. This functionality can be disabled by setting this hint.

    As of SDL 2.0.4, `SDL_EnableScreenSaver( )` and `SDL_DisableScreenSaver( )`
    accomplish the same thing on iOS. They should be preferred over this hint.

- `SDL_HINT_IME_INTERNAL_EDITING`

    A variable to control whether we trap the Android back button to handle it
    manually. This is necessary for the right mouse button to work on some Android
    devices, or to be able to trap the back button for use in your code reliably.
    If set to true, the back button will show up as an `SDL_KEYDOWN` /
    `SDL_KEYUP` pair with a keycode of `SDL_SCANCODE_AC_BACK`.

    The variable can be set to the following values:

        0   Back button will be handled as usual for system. (default)
        1   Back button will be trapped, allowing you to handle the key press
            manually. (This will also let right mouse click work on systems
            where the right mouse button functions as back.)

    The value of this hint is used at runtime, so it can be changed at any time.

- `SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS`

    A variable controlling whether the HIDAPI joystick drivers should be used.

    This variable can be set to the following values:

        0   HIDAPI drivers are not used
        1   HIDAPI drivers are used (default)

    This variable is the default for all drivers, but can be overridden by the
    hints for specific drivers below.

- `SDL_HINT_MAC_BACKGROUND_APP`

    A hint that specifies if the SDL app should not be forced to become a
    foreground process on Mac OS X.

    Values:

        0   force the SDL app to become a foreground process (default)
        1   do not force the SDL app to become a foreground process

    This hint only applies to Mac OSX.

- `SDL_HINT_MAC_CTRL_CLICK_EMULATE_RIGHT_CLICK`

    A hint that specifies whether ctrl+click should generate a right-click event on
    Mac.

    Values:

        0   disable emulating right click (default)
        1   enable emulating right click

- `SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH`

    A hint that specifies if mouse click events are sent when clicking to focus an
    SDL window.

    Values:

        0   no mouse click events are sent when clicking to focus (default)
        1   mouse click events are sent when clicking to focus

- `SDL_HINT_MOUSE_RELATIVE_MODE_WARP`

    A hint that specifies whether relative mouse mode is implemented using mouse
    warping.

    Values:

        0   relative mouse mode uses the raw input (default)
        1   relative mouse mode uses mouse warping

- `SDL_HINT_NO_SIGNAL_HANDLERS`

    A hint that specifies not to catch the `SIGINT` or `SIGTERM` signals.

    Values:

        0   SDL will install a SIGINT and SIGTERM handler, and when it
            catches a signal, convert it into an SDL_QUIT event
        1   SDL will not install a signal handler at all

- `SDL_HINT_ORIENTATIONS`

    A variable controlling which orientations are allowed on iOS/Android.

    In some circumstances it is necessary to be able to explicitly control which UI
    orientations are allowed.

    This variable is a space delimited list of the following values:

    - `LandscapeLeft`
    - `LandscapeRight`
    - `Portrait`
    - `PortraitUpsideDown`

- `SDL_HINT_RENDER_DIRECT3D11_DEBUG`

    A variable controlling whether to enable Direct3D 11+'s Debug Layer.

    This variable does not have any effect on the Direct3D 9 based renderer.

    This variable can be set to the following values:

        0   Disable Debug Layer use (default)
        1   Enable Debug Layer use

- `SDL_HINT_RENDER_DIRECT3D_THREADSAFE`

    A variable controlling whether the Direct3D device is initialized for
    thread-safe operations.

    This variable can be set to the following values:

        0   Thread-safety is not enabled (faster; default)
        1   Thread-safety is enabled

- `SDL_HINT_RENDER_DRIVER`

    A variable specifying which render driver to use.

    If the application doesn't pick a specific renderer to use, this variable
    specifies the name of the preferred renderer. If the preferred renderer can't
    be initialized, the normal default renderer is used.

    This variable is case insensitive and can be set to the following values:

    - `direct3d`
    - `opengl`
    - `opengles2`
    - `opengles`
    - `metal`
    - `software`

    The default varies by platform, but it's the first one in the list that is
    available on the current platform.

- `SDL_HINT_RENDER_OPENGL_SHADERS`

    A variable controlling whether the OpenGL render driver uses shaders if they
    are available.

    This variable can be set to the following values:

        0   Disable shaders
        1   Enable shaders (default)

- `SDL_HINT_RENDER_SCALE_QUALITY`

    A variable controlling the scaling quality

    This variable can be set to the following values:     0 or nearest    Nearest
    pixel sampling (default)     1 or linear     Linear filtering (supported by
    OpenGL and Direct3D)     2 or best       Currently this is the same as linear

- `SDL_HINT_RENDER_VSYNC`

    A variable controlling whether updates to the SDL screen surface should be
    synchronized with the vertical refresh, to avoid tearing.

    This variable can be set to the following values:

        0   Disable vsync
        1   Enable vsync

    By default SDL does not sync screen surface updates with vertical refresh.

- `SDL_HINT_RPI_VIDEO_LAYER`

    Tell SDL which Dispmanx layer to use on a Raspberry PI

    Also known as Z-order. The variable can take a negative or positive value.

    The default is `10000`.

- `SDL_HINT_THREAD_STACK_SIZE`

    A string specifying SDL's threads stack size in bytes or `0` for the backend's
    default size

    Use this hint in case you need to set SDL's threads stack size to other than
    the default. This is specially useful if you build SDL against a non glibc libc
    library (such as musl) which provides a relatively small default thread stack
    size (a few kilobytes versus the default 8MB glibc uses). Support for this hint
    is currently available only in the pthread, Windows, and PSP backend.

    Instead of this hint, in 2.0.9 and later, you can use
    `SDL_CreateThreadWithStackSize( )`. This hint only works with the classic
    `SDL_CreateThread( )`.

- `SDL_HINT_TIMER_RESOLUTION`

    A variable that controls the timer resolution, in milliseconds.

    he higher resolution the timer, the more frequently the CPU services timer
    interrupts, and the more precise delays are, but this takes up power and CPU
    time.  This hint is only used on Windows.

    See this blog post for more information:
    [http://randomascii.wordpress.com/2013/07/08/windows-timer-resolution-megawatts-wasted/](http://randomascii.wordpress.com/2013/07/08/windows-timer-resolution-megawatts-wasted/)

    If this variable is set to `0`, the system timer resolution is not set.

    The default value is `1`. This hint may be set at any time.

- `SDL_HINT_VIDEO_ALLOW_SCREENSAVER`

    A variable controlling whether the screensaver is enabled.

    This variable can be set to the following values:

        0   Disable screensaver
        1   Enable screensaver

    By default SDL will disable the screensaver.

- `SDL_HINT_VIDEO_HIGHDPI_DISABLED`

    If set to `1`, then do not allow high-DPI windows. ("Retina" on Mac and iOS)

- `SDL_HINT_VIDEO_MAC_FULLSCREEN_SPACES`

    A variable that dictates policy for fullscreen Spaces on Mac OS X.

    This hint only applies to Mac OS X.

    The variable can be set to the following values:

        0   Disable Spaces support (FULLSCREEN_DESKTOP won't use them and
            SDL_WINDOW_RESIZABLE windows won't offer the "fullscreen"
            button on their titlebars).
        1   Enable Spaces support (FULLSCREEN_DESKTOP will use them and
            SDL_WINDOW_RESIZABLE windows will offer the "fullscreen"
            button on their titlebars).

    The default value is `1`. Spaces are disabled regardless of this hint if the
    OS isn't at least Mac OS X Lion (10.7). This hint must be set before any
    windows are created.

- `SDL_HINT_VIDEO_MINIMIZE_ON_FOCUS_LOSS`

    Minimize your `SDL_Window` if it loses key focus when in fullscreen mode.
    Defaults to false.

    Warning: Before SDL 2.0.14, this defaulted to true! In 2.0.14, we're seeing if
    "true" causes more problems than it solves in modern times.

- `SDL_HINT_VIDEO_WIN_D3DCOMPILER`

    A variable specifying which shader compiler to preload when using the Chrome
    ANGLE binaries

    SDL has EGL and OpenGL ES2 support on Windows via the ANGLE project. It can use
    two different sets of binaries, those compiled by the user from source or those
    provided by the Chrome browser. In the later case, these binaries require that
    SDL loads a DLL providing the shader compiler.

    This variable can be set to the following values:

    - `d3dcompiler_46.dll`

        default, best for Vista or later.

    - `d3dcompiler_43.dll`

        for XP support.

    - `none`

        do not load any library, useful if you compiled ANGLE from source and included
        the compiler in your binaries.

- `SDL_HINT_VIDEO_WINDOW_SHARE_PIXEL_FORMAT`

    A variable that is the address of another `SDL_Window*` (as a hex string
    formatted with `%p`).

    If this hint is set before `SDL_CreateWindowFrom( )` and the `SDL_Window*` it
    is set to has `SDL_WINDOW_OPENGL` set (and running on WGL only, currently),
    then two things will occur on the newly created `SDL_Window`:

    - 1. Its pixel format will be set to the same pixel format as this `SDL_Window`. This is needed for example when sharing an OpenGL context across multiple windows.
    - 2. The flag SDL\_WINDOW\_OPENGL will be set on the new window so it can be used for OpenGL rendering.

    This variable can be set to the address (as a string `%p`) of the
    `SDL_Window*` that new windows created with [`SDL_CreateWindowFrom( ...
    )`](#sdl_createwindowfrom)should share a pixel format with.

- `SDL_HINT_VIDEO_X11_NET_WM_PING`

    A variable controlling whether the X11 \_NET\_WM\_PING protocol should be
    supported.

    This variable can be set to the following values:

        0    Disable _NET_WM_PING
        1   Enable _NET_WM_PING

    By default SDL will use \_NET\_WM\_PING, but for applications that know they will
    not always be able to respond to ping requests in a timely manner they can turn
    it off to avoid the window manager thinking the app is hung. The hint is
    checked in CreateWindow.

- `SDL_HINT_VIDEO_X11_XINERAMA`

    A variable controlling whether the X11 Xinerama extension should be used.

    This variable can be set to the following values:

        0   Disable Xinerama
        1   Enable Xinerama

    By default SDL will use Xinerama if it is available.

- `SDL_HINT_VIDEO_X11_XRANDR`

    A variable controlling whether the X11 XRandR extension should be used.

    This variable can be set to the following values:

        0   Disable XRandR
        1   Enable XRandR

    By default SDL will not use XRandR because of window manager issues.

- `SDL_HINT_VIDEO_X11_XVIDMODE`

    A variable controlling whether the X11 VidMode extension should be used.

    This variable can be set to the following values:

        0   Disable XVidMode
        1   Enable XVidMode

    By default SDL will use XVidMode if it is available.

- `SDL_HINT_WINDOW_FRAME_USABLE_WHILE_CURSOR_HIDDEN`

    A variable controlling whether the window frame and title bar are interactive
    when the cursor is hidden.

    This variable can be set to the following values:

        0   The window frame is not interactive when the cursor is hidden (no move, resize, etc)
        1   The window frame is interactive when the cursor is hidden

    By default SDL will allow interaction with the window frame when the cursor is
    hidden.

- `SDL_HINT_WINDOWS_DISABLE_THREAD_NAMING`

    Tell SDL not to name threads on Windows with the 0x406D1388 Exception. The
    0x406D1388 Exception is a trick used to inform Visual Studio of a thread's
    name, but it tends to cause problems with other debuggers, and the .NET
    runtime. Note that SDL 2.0.6 and later will still use the (safer)
    SetThreadDescription API, introduced in the Windows 10 Creators Update, if
    available.

    The variable can be set to the following values:

        0   SDL will raise the 0x406D1388 Exception to name threads.
            This is the default behavior of SDL <= 2.0.4.
        1   SDL will not raise this exception, and threads will be unnamed. (default)
            This is necessary with .NET languages or debuggers that aren't Visual Studio.

- `SDL_HINT_WINDOWS_INTRESOURCE_ICON`

    A variable to specify custom icon resource id from RC file on Windows platform.

- `SDL_HINT_WINDOWS_INTRESOURCE_ICON_SMALL`

    A variable to specify custom icon resource id from RC file on Windows platform.

- `SDL_HINT_WINDOWS_ENABLE_MESSAGELOOP`

    A variable controlling whether the windows message loop is processed by SDL .

    This variable can be set to the following values:

        0   The window message loop is not run
        1   The window message loop is processed in SDL_PumpEvents( )

    By default SDL will process the windows message loop.

- `SDL_HINT_WINDOWS_NO_CLOSE_ON_ALT_F4`

    Tell SDL not to generate window-close events for Alt+F4 on Windows.

    The variable can be set to the following values:

        0   SDL will generate a window-close event when it sees Alt+F4.
        1   SDL will only do normal key handling for Alt+F4.

- `SDL_HINT_WINRT_HANDLE_BACK_BUTTON`

    Allows back-button-press events on Windows Phone to be marked as handled.

    Windows Phone devices typically feature a Back button.  When pressed, the OS
    will emit back-button-press events, which apps are expected to handle in an
    appropriate manner.  If apps do not explicitly mark these events as 'Handled',
    then the OS will invoke its default behavior for unhandled back-button-press
    events, which on Windows Phone 8 and 8.1 is to terminate the app (and attempt
    to switch to the previous app, or to the device's home screen).

    Setting the `SDL_HINT_WINRT_HANDLE_BACK_BUTTON` hint to "1" will cause SDL to
    mark back-button-press events as Handled, if and when one is sent to the app.

    Internally, Windows Phone sends back button events as parameters to special
    back-button-press callback functions.  Apps that need to respond to
    back-button-press events are expected to register one or more callback
    functions for such, shortly after being launched (during the app's
    initialization phase).  After the back button is pressed, the OS will invoke
    these callbacks.  If the app's callback(s) do not explicitly mark the event as
    handled by the time they return, or if the app never registers one of these
    callback, the OS will consider the event un-handled, and it will apply its
    default back button behavior (terminate the app).

    SDL registers its own back-button-press callback with the Windows Phone OS.
    This callback will emit a pair of SDL key-press events (`SDL_KEYDOWN` and
    `SDL_KEYUP`), each with a scancode of SDL\_SCANCODE\_AC\_BACK, after which it
    will check the contents of the hint, `SDL_HINT_WINRT_HANDLE_BACK_BUTTON`. If
    the hint's value is set to `1`, the back button event's Handled property will
    get set to a `true` value. If the hint's value is set to something else, or if
    it is unset, SDL will leave the event's Handled property alone. (By default,
    the OS sets this property to 'false', to note.)

    SDL apps can either set `SDL_HINT_WINRT_HANDLE_BACK_BUTTON` well before a back
    button is pressed, or can set it in direct-response to a back button being
    pressed.

    In order to get notified when a back button is pressed, SDL apps should
    register a callback function with `SDL_AddEventWatch( )`, and have it listen
    for `SDL_KEYDOWN` events that have a scancode of `SDL_SCANCODE_AC_BACK`.
    (Alternatively, `SDL_KEYUP` events can be listened-for. Listening for either
    event type is suitable.)  Any value of `SDL_HINT_WINRT_HANDLE_BACK_BUTTON` set
    by such a callback, will be applied to the OS' current back-button-press event.

    More details on back button behavior in Windows Phone apps can be found at the
    following page, on Microsoft's developer site:
    [http://msdn.microsoft.com/en-us/library/windowsphone/develop/jj247550(v=vs.105).aspx](http://msdn.microsoft.com/en-us/library/windowsphone/develop/jj247550\(v=vs.105\).aspx)

- `SDL_HINT_WINRT_PRIVACY_POLICY_LABEL`

    Label text for a WinRT app's privacy policy link.

    Network-enabled WinRT apps must include a privacy policy. On Windows 8, 8.1,
    and RT, Microsoft mandates that this policy be available via the Windows
    Settings charm. SDL provides code to add a link there, with its label text
    being set via the optional hint, `SDL_HINT_WINRT_PRIVACY_POLICY_LABEL`.

    Please note that a privacy policy's contents are not set via this hint.  A
    separate hint, `SDL_HINT_WINRT_PRIVACY_POLICY_URL`, is used to link to the
    actual text of the policy.

    The contents of this hint should be encoded as a UTF8 string.

    The default value is "Privacy Policy". This hint should only be set during app
    initialization, preferably before any calls to [`SDL_Init( ...
    )`](#sdl_init).

    For additional information on linking to a privacy policy, see the
    documentation for `SDL_HINT_WINRT_PRIVACY_POLICY_URL`.

- `SDL_HINT_WINRT_PRIVACY_POLICY_URL`

    A URL to a WinRT app's privacy policy.

    All network-enabled WinRT apps must make a privacy policy available to its
    users.  On Windows 8, 8.1, and RT, Microsoft mandates that this policy be be
    available in the Windows Settings charm, as accessed from within the app. SDL
    provides code to add a URL-based link there, which can point to the app's
    privacy policy.

    To setup a URL to an app's privacy policy, set
    `SDL_HINT_WINRT_PRIVACY_POLICY_URL` before calling any [`SDL_Init( ...
    )`](#sdl_init) functions.  The contents of the hint should be a
    valid URL.  For example, [http://www.example.com](http://www.example.com).

    The default value is an empty string (``), which will prevent SDL from adding
    a privacy policy link to the Settings charm. This hint should only be set
    during app init.

    The label text of an app's "Privacy Policy" link may be customized via another
    hint, `SDL_HINT_WINRT_PRIVACY_POLICY_LABEL`.

    Please note that on Windows Phone, Microsoft does not provide standard UI for
    displaying a privacy policy link, and as such,
    SDL\_HINT\_WINRT\_PRIVACY\_POLICY\_URL will not get used on that platform.
    Network-enabled phone apps should display their privacy policy through some
    other, in-app means.

- `SDL_HINT_XINPUT_ENABLED`

    A variable that lets you disable the detection and use of Xinput gamepad
    devices

    The variable can be set to the following values:

        0   Disable XInput detection (only uses direct input)
        1   Enable XInput detection (default)

- `SDL_HINT_XINPUT_USE_OLD_JOYSTICK_MAPPING`

    A variable that causes SDL to use the old axis and button mapping for XInput
    devices.

    This hint is for backwards compatibility only and will be removed in SDL 2.1

    The default value is `0`.  This hint must be set before [`SDL_Init( ...
    )`](#sdl_init)

- `SDL_HINT_QTWAYLAND_WINDOW_FLAGS`

    Flags to set on QtWayland windows to integrate with the native window manager.

    On QtWayland platforms, this hint controls the flags to set on the windows. For
    example, on Sailfish OS, `OverridesSystemGestures` disables swipe gestures.

    This variable is a space-separated list of the following values (empty = no
    flags):

    - `OverridesSystemGestures`
    - `StaysOnTop`
    - `BypassWindowManager`

- `SDL_HINT_QTWAYLAND_CONTENT_ORIENTATION`

    A variable describing the content orientation on QtWayland-based platforms.

    On QtWayland platforms, windows are rotated client-side to allow for custom
    transitions. In order to correctly position overlays (e.g. volume bar) and
    gestures (e.g. events view, close/minimize gestures), the system needs to know
    in which orientation the application is currently drawing its contents.

    This does not cause the window to be rotated or resized, the application needs
    to take care of drawing the content in the right orientation (the framebuffer
    is always in portrait mode).

    This variable can be one of the following values:

    - `primary` (default)
    - `portrait`
    - `landscape`
    - `inverted-portrait`
    - `inverted-landscape`

- `SDL_HINT_RENDER_LOGICAL_SIZE_MODE`

    A variable controlling the scaling policy for `SDL_RenderSetLogicalSize`.

    This variable can be set to the following values:

    - `0` or `letterbox`

        Uses letterbox/sidebars to fit the entire rendering on screen.

    - `1` or `overscan`

        Will zoom the rendering so it fills the entire screen, allowing edges to be
        drawn offscreen.

    By default letterbox is used.

- `SDL_HINT_VIDEO_EXTERNAL_CONTEXT`

    A variable controlling whether the graphics context is externally managed.

    This variable can be set to the following values:

        0   SDL will manage graphics contexts that are attached to windows.
        1   Disable graphics context management on windows.

    By default SDL will manage OpenGL contexts in certain situations. For example,
    on Android the context will be automatically saved and restored when pausing
    the application. Additionally, some platforms will assume usage of OpenGL if
    Vulkan isn't used. Setting this to `1` will prevent this behavior, which is
    desirable when the application manages the graphics context, such as an
    externally managed OpenGL context or attaching a Vulkan surface to the window.

- <SDL\_HINT\_VIDEO\_X11\_WINDOW\_VISUALID>

    A variable forcing the visual ID chosen for new X11 windows.

- `SDL_HINT_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR`

    A variable controlling whether the X11 \_NET\_WM\_BYPASS\_COMPOSITOR hint should be
    used.

    This variable can be set to the following values:

        0   Disable _NET_WM_BYPASS_COMPOSITOR
        1   Enable _NET_WM_BYPASS_COMPOSITOR

    By default SDL will use \_NET\_WM\_BYPASS\_COMPOSITOR.

- `SDL_HINT_VIDEO_X11_FORCE_EGL`

    A variable controlling whether X11 should use GLX or EGL by default

    This variable can be set to the following values:

        0   Use GLX
        1   Use EGL

    By default SDL will use GLX when both are present.

- `SDL_HINT_MOUSE_DOUBLE_CLICK_TIME`

    A variable setting the double click time, in milliseconds.

- `SDL_HINT_MOUSE_DOUBLE_CLICK_RADIUS`

    A variable setting the double click radius, in pixels.

- `SDL_HINT_MOUSE_NORMAL_SPEED_SCALE`

    A variable setting the speed scale for mouse motion, in floating point, when
    the mouse is not in relative mode.

- `SDL_HINT_MOUSE_RELATIVE_SPEED_SCALE`

    A variable setting the scale for mouse motion, in floating point, when the
    mouse is in relative mode.

- `SDL_HINT_MOUSE_RELATIVE_SCALING`

    A variable controlling whether relative mouse motion is affected by renderer
    scaling

    This variable can be set to the following values:

        0   Relative motion is unaffected by DPI or renderer's logical size
        1   Relative motion is scaled according to DPI scaling and logical size

    By default relative mouse deltas are affected by DPI and renderer scaling.

- `SDL_HINT_TOUCH_MOUSE_EVENTS`

    A variable controlling whether touch events should generate synthetic mouse
    events

    This variable can be set to the following values:

        0   Touch events will not generate mouse events
        1   Touch events will generate mouse events

    By default SDL will generate mouse events for touch events.

- `SDL_HINT_MOUSE_TOUCH_EVENTS`

    A variable controlling whether mouse events should generate synthetic touch
    events

    This variable can be set to the following values:

        0   Mouse events will not generate touch events (default for desktop platforms)
        1   Mouse events will generate touch events (default for mobile platforms, such as Android and iOS)

- `SDL_HINT_IOS_HIDE_HOME_INDICATOR`

    A variable controlling whether the home indicator bar on iPhone X should be
    hidden.

    This variable can be set to the following values:

        0   The indicator bar is not hidden (default for windowed applications)
        1   The indicator bar is hidden and is shown when the screen is touched (useful for movie playback applications)
        2   The indicator bar is dim and the first swipe makes it visible and the second swipe performs the "home" action (default for fullscreen applications)

- `SDL_HINT_TV_REMOTE_AS_JOYSTICK`

    A variable controlling whether the Android / tvOS remotes should be listed as
    joystick devices, instead of sending keyboard events.

    This variable can be set to the following values:

        0   Remotes send enter/escape/arrow key events
        1   Remotes are available as 2 axis, 2 button joysticks (the default).

- `SDL_HINT_GAMECONTROLLERTYPE`

    A variable that overrides the automatic controller type detection

    The variable should be comma separated entries, in the form: VID/PID=type

    The VID and PID should be hexadecimal with exactly 4 digits, e.g. `0x00fd`

    The type should be one of:

    - `Xbox360`
    - `XboxOne`
    - `PS3`
    - `PS4`
    - `PS5`
    - `SwitchPro`

        This hint affects what driver is used, and must be set before calling
        `SDL_Init(SDL_INIT_GAMECONTROLLER)`.

    - `SDL_HINT_GAMECONTROLLERCONFIG_FILE`

        A variable that lets you provide a file with extra gamecontroller db entries.

        The file should contain lines of gamecontroller config data, see
        SDL\_gamecontroller.h

        This hint must be set before calling `SDL_Init(SDL_INIT_GAMECONTROLLER)`

        You can update mappings after the system is initialized with
        `SDL_GameControllerMappingForGUID( )` and `SDL_GameControllerAddMapping( )`.

    - `SDL_HINT_GAMECONTROLLER_IGNORE_DEVICES`

        A variable containing a list of devices to skip when scanning for game
        controllers.

        The format of the string is a comma separated list of USB VID/PID pairs in
        hexadecimal form, e.g.

            0xAAAA/0xBBBB,0xCCCC/0xDDDD

        The variable can also take the form of @file, in which case the named file will
        be loaded and interpreted as the value of the variable.

    - `SDL_HINT_GAMECONTROLLER_IGNORE_DEVICES_EXCEPT`

        If set, all devices will be skipped when scanning for game controllers except
        for the ones listed in this variable.

        The format of the string is a comma separated list of USB VID/PID pairs in
        hexadecimal form, e.g.

            0xAAAA/0xBBBB,0xCCCC/0xDDDD

        The variable can also take the form of @file, in which case the named file will
        be loaded and interpreted as the value of the variable.

    - `SDL_HINT_GAMECONTROLLER_USE_BUTTON_LABELS`

        If set, game controller face buttons report their values according to their
        labels instead of their positional layout.

        For example, on Nintendo Switch controllers, normally you'd get:

                (Y)
            (X)     (B)
                (A)

        but if this hint is set, you'll get:

                (X)
            (Y)     (A)
                (B)

        The variable can be set to the following values:

            0   Report the face buttons by position, as though they were on an Xbox controller.
            1   Report the face buttons by label instead of position

        The default value is `1`. This hint may be set at any time.

    - `SDL_HINT_JOYSTICK_HIDAPI`

        A variable controlling whether the HIDAPI joystick drivers should be used.

        This variable can be set to the following values:

            0   HIDAPI drivers are not used
            1   HIDAPI drivers are used (the default)

        This variable is the default for all drivers, but can be overridden by the
        hints for specific drivers below.

    - `SDL_HINT_JOYSTICK_HIDAPI_PS4`

        A variable controlling whether the HIDAPI driver for PS4 controllers should be
        used.

        This variable can be set to the following values:

            0   HIDAPI driver is not used
            1   HIDAPI driver is used

        The default is the value of `SDL_HINT_JOYSTICK_HIDAPI`

    - `SDL_HINT_JOYSTICK_HIDAPI_PS4_RUMBLE`

        A variable controlling whether extended input reports should be used for PS4
        controllers when using the HIDAPI driver.

        This variable can be set to the following values:

            0   extended reports are not enabled (default)
            1   extended reports

        Extended input reports allow rumble on Bluetooth PS4 controllers, but break
        DirectInput handling for applications that don't use SDL.

        Once extended reports are enabled, they can not be disabled without power
        cycling the controller.

        For compatibility with applications written for versions of SDL prior to the
        introduction of PS5 controller support, this value will also control the state
        of extended reports on PS5 controllers when the
        `SDL_HINT_JOYSTICK_HIDAPI_PS5_RUMBLE` hint is not explicitly set.

    - `SDL_HINT_JOYSTICK_HIDAPI_PS5`

        A variable controlling whether the HIDAPI driver for PS5 controllers should be
        used.

        This variable can be set to the following values:

            0   HIDAPI driver is not used
            1   HIDAPI driver is used

        The default is the value of `SDL_HINT_JOYSTICK_HIDAPI`.

    - `SDL_HINT_JOYSTICK_HIDAPI_PS5_RUMBLE`

        A variable controlling whether extended input reports should be used for PS5
        controllers when using the HIDAPI driver.

        This variable can be set to the following values:

            0   extended reports are not enabled (default)
            1   extended reports

        Extended input reports allow rumble on Bluetooth PS5 controllers, but break
        DirectInput handling for applications that don't use SDL.

        Once extended reports are enabled, they can not be disabled without power
        cycling the controller.

        For compatibility with applications written for versions of SDL prior to the
        introduction of PS5 controller support, this value defaults to the value of
        `SDL_HINT_JOYSTICK_HIDAPI_PS4_RUMBLE`.

    - `SDL_HINT_JOYSTICK_HIDAPI_PS5_PLAYER_LED`

        A variable controlling whether the player LEDs should be lit to indicate which
        player is associated with a PS5 controller.

        This variable can be set to the following values:

            0   player LEDs are not enabled
            1   player LEDs are enabled (default)

    - `SDL_HINT_JOYSTICK_HIDAPI_STADIA`

        A variable controlling whether the HIDAPI driver for Google Stadia controllers
        should be used.

        This variable can be set to the following values:

            0   HIDAPI driver is not used
            1   HIDAPI driver is used

        The default is the value of `SDL_HINT_JOYSTICK_HIDAPI`.

    - `SDL_HINT_JOYSTICK_HIDAPI_STEAM`

        A variable controlling whether the HIDAPI driver for Steam Controllers should
        be used.

        This variable can be set to the following values:

            0   HIDAPI driver is not used
            1   HIDAPI driver is used

        The default is the value of `SDL_HINT_JOYSTICK_HIDAPI`.

    - `SDL_HINT_JOYSTICK_HIDAPI_SWITCH`

        A variable controlling whether the HIDAPI driver for Nintendo Switch
        controllers should be used.

        This variable can be set to the following values:

            0   HIDAPI driver is not used
            1   HIDAPI driver is used

        The default is the value of `SDL_HINT_JOYSTICK_HIDAPI`.

    - `SDL_HINT_JOYSTICK_HIDAPI_SWITCH_HOME_LED`

        A variable controlling whether the Home button LED should be turned on when a
        Nintendo Switch controller is opened

        This variable can be set to the following values:

            0   home button LED is left off
            1   home button LED is turned on (default)

    - `SDL_HINT_JOYSTICK_HIDAPI_JOY_CONS`

        A variable controlling whether Switch Joy-Cons should be treated the same as
        Switch Pro Controllers when using the HIDAPI driver.

        This variable can be set to the following values:

            0   basic Joy-Con support with no analog input (default)
            1   Joy-Cons treated as half full Pro Controllers with analog inputs and sensors

        This does not combine Joy-Cons into a single controller. That's up to the user.

    - `SDL_HINT_JOYSTICK_HIDAPI_XBOX`

        A variable controlling whether the HIDAPI driver for XBox controllers should be
        used.

        This variable can be set to the following values:

            0   HIDAPI driver is not used
            1   HIDAPI driver is used

        The default is `0` on Windows, otherwise the value of
        `SDL_HINT_JOYSTICK_HIDAPI`.

    - `SDL_HINT_JOYSTICK_HIDAPI_CORRELATE_XINPUT`

        A variable controlling whether the HIDAPI driver for XBox controllers on
        Windows should pull correlated data from XInput.

        This variable can be set to the following values:

            0   HIDAPI Xbox driver will only use HIDAPI data
            1   HIDAPI Xbox driver will also pull data from XInput, providing better trigger axes, guide button
                presses, and rumble support

        The default is `1`.  This hint applies to any joysticks opened after setting
        the hint.

    - `SDL_HINT_JOYSTICK_HIDAPI_GAMECUBE`

        A variable controlling whether the HIDAPI driver for Nintendo GameCube
        controllers should be used.

        This variable can be set to the following values:

            0   HIDAPI driver is not used
            1   HIDAPI driver is used

        The default is the value of `SDL_HINT_JOYSTICK_HIDAPI`.

    - `SDL_HINT_ENABLE_STEAM_CONTROLLERS`

        A variable that controls whether Steam Controllers should be exposed using the
        SDL joystick and game controller APIs

        The variable can be set to the following values:

            0   Do not scan for Steam Controllers
            1   Scan for Steam Controllers (default)

        The default value is `1`.  This hint must be set before initializing the
        joystick subsystem.

    - `SDL_HINT_JOYSTICK_RAWINPUT`

        A variable controlling whether the RAWINPUT joystick drivers should be used for
        better handling XInput-capable devices.

        This variable can be set to the following values:

            0   RAWINPUT drivers are not used
            1   RAWINPUT drivers are used (default)

    - `SDL_HINT_JOYSTICK_THREAD`

        A variable controlling whether a separate thread should be used for handling
        joystick detection and raw input messages on Windows

        This variable can be set to the following values:

            0   A separate thread is not used (default)
            1   A separate thread is used for handling raw input messages

    - `SDL_HINT_LINUX_JOYSTICK_DEADZONES`

        A variable controlling whether joysticks on Linux adhere to their HID-defined
        deadzones or return unfiltered values.

        This variable can be set to the following values:

            0   Return unfiltered joystick axis values (default)
            1   Return axis values with deadzones taken into account

    - `SDL_HINT_ALLOW_TOPMOST`

        If set to `0` then never set the top most bit on a SDL Window, even if the
        video mode expects it. This is a debugging aid for developers and not expected
        to be used by end users. The default is `1`.

        This variable can be set to the following values:

            0   don't allow topmost
            1   allow topmost (default)

    - `SDL_HINT_THREAD_PRIORITY_POLICY`

        A string specifying additional information to use with
        `SDL_SetThreadPriority`.

        By default `SDL_SetThreadPriority` will make appropriate system changes in
        order to apply a thread priority. For example on systems using pthreads the
        scheduler policy is changed automatically to a policy that works well with a
        given priority. Code which has specific requirements can override SDL's default
        behavior with this hint.

        pthread hint values are `current`, `other`, `fifo` and `rr`. Currently no
        other platform hint values are defined but may be in the future.

        Note:

        On Linux, the kernel may send `SIGKILL` to realtime tasks which exceed the
        distro configured execution budget for rtkit. This budget can be queried
        through `RLIMIT_RTTIME` after calling `SDL_SetThreadPriority( )`.

    - `SDL_HINT_THREAD_FORCE_REALTIME_TIME_CRITICAL`

        Specifies whether `SDL_THREAD_PRIORITY_TIME_CRITICAL` should be treated as
        realtime.

        On some platforms, like Linux, a realtime priority thread may be subject to
        restrictions that require special handling by the application. This hint exists
        to let SDL know that the app is prepared to handle said restrictions.

        On Linux, SDL will apply the following configuration to any thread that becomes
        realtime:

        - The SCHED\_RESET\_ON\_FORK bit will be set on the scheduling policy,
        - An RLIMIT\_RTTIME budget will be configured to the rtkit specified limit.

            Exceeding this limit will result in the kernel sending `SIGKILL` to the app,

            Refer to the man pages for more information.

        This variable can be set to the following values:

            0   default platform specific behaviour
            1   Force SDL_THREAD_PRIORITY_TIME_CRITICAL to a realtime scheduling policy

    - `SDL_HINT_VIDEO_WINDOW_SHARE_PIXEL_FORMAT`

        A variable that is the address of another SDL\_Window\* (as a hex string
        formatted with `%p`).

        If this hint is set before `SDL_CreateWindowFrom( )` and the `SDL_Window*` it
        is set to has `SDL_WINDOW_OPENGL` set (and running on WGL only, currently),
        then two things will occur on the newly created `SDL_Window`:

        - 1. Its pixel format will be set to the same pixel format as this `SDL_Window`. This is needed for example when sharing an OpenGL context across multiple windows.
        - 2. The flag `SDL_WINDOW_OPENGL` will be set on the new window so it can be used for OpenGL rendering.

            This variable can be set to the following values:

            - The address (as a string `%p`) of the `SDL_Window*` that new windows created with [`SDL_CreateWindowFrom( ... )`](#sdl_createwindowfrom) should share a pixel format with.

        - `SDL_HINT_ANDROID_TRAP_BACK_BUTTON`

            A variable to control whether we trap the Android back button to handle it
            manually. This is necessary for the right mouse button to work on some Android
            devices, or to be able to trap the back button for use in your code reliably.
            If set to true, the back button will show up as an SDL\_KEYDOWN / SDL\_KEYUP pair
            with a keycode of `SDL_SCANCODE_AC_BACK`.

            The variable can be set to the following values:

            - `0`

                Back button will be handled as usual for system. (default)

            - `1`

                Back button will be trapped, allowing you to handle the key press manually.
                (This will also let right mouse click work on systems where the right mouse
                button functions as back.)

            The value of this hint is used at runtime, so it can be changed at any time.

    - `SDL_HINT_ANDROID_BLOCK_ON_PAUSE`

        A variable to control whether the event loop will block itself when the app is
        paused.

        The variable can be set to the following values:

        - `0`

            Non blocking.

        - `1`

            Blocking. (default)

        The value should be set before SDL is initialized.

- `SDL_HINT_ANDROID_BLOCK_ON_PAUSE_PAUSEAUDIO`

    A variable to control whether SDL will pause audio in background (Requires
    `SDL_ANDROID_BLOCK_ON_PAUSE` as "Non blocking")

    The variable can be set to the following values:

    - `0`

        Non paused.

    - `1`

        Paused. (default)

    The value should be set before SDL is initialized.

- `SDL_HINT_RETURN_KEY_HIDES_IME`

    A variable to control whether the return key on the soft keyboard should hide
    the soft keyboard on Android and iOS.

    The variable can be set to the following values:

    - `0`

        The return key will be handled as a key event. This is the behaviour of SDL <=
        2.0.3. (default)

    - `1`

        The return key will hide the keyboard.

    The value of this hint is used at runtime, so it can be changed at any time.

- `SDL_HINT_WINDOWS_FORCE_MUTEX_CRITICAL_SECTIONS`

    Force SDL to use Critical Sections for mutexes on Windows. On Windows 7 and
    newer, Slim Reader/Writer Locks are available. They offer better performance,
    allocate no kernel resources and use less memory. SDL will fall back to
    Critical Sections on older OS versions or if forced to by this hint.

    This also affects Condition Variables. When SRW mutexes are used, SDL will use
    Windows Condition Variables as well. Else, a generic SDL\_cond implementation
    will be used that works with all mutexes.

    This variable can be set to the following values:

    - `0`

        Use SRW Locks when available. If not, fall back to Critical Sections. (default)

    - `1`

        Force the use of Critical Sections in all cases.

- `SDL_HINT_WINDOWS_FORCE_SEMAPHORE_KERNEL`

    Force SDL to use Kernel Semaphores on Windows. Kernel Semaphores are
    inter-process and require a context switch on every interaction. On Windows 8
    and newer, the WaitOnAddress API is available. Using that and atomics to
    implement semaphores increases performance. SDL will fall back to Kernel
    Objects on older OS versions or if forced to by this hint.

    This variable can be set to the following values:

    - `0`

        Use Atomics and WaitOnAddress API when available. If not, fall back to Kernel
        Objects. (default)

    - `1`

        Force the use of Kernel Objects in all cases.

- `SDL_HINT_WINDOWS_USE_D3D9EX`

    Use the D3D9Ex API introduced in Windows Vista, instead of normal D3D9.
    Direct3D 9Ex contains changes to state management that can eliminate device
    loss errors during scenarios like Alt+Tab or UAC prompts. D3D9Ex may require
    some changes to your application to cope with the new behavior, so this is
    disabled by default.

    This hint must be set before initializing the video subsystem.

    For more information on Direct3D 9Ex, see:

    - [https://docs.microsoft.com/en-us/windows/win32/direct3darticles/graphics-apis-in-windows-vista#direct3d-9ex](https://docs.microsoft.com/en-us/windows/win32/direct3darticles/graphics-apis-in-windows-vista#direct3d-9ex)
    - [https://docs.microsoft.com/en-us/windows/win32/direct3darticles/direct3d-9ex-improvements](https://docs.microsoft.com/en-us/windows/win32/direct3darticles/direct3d-9ex-improvements)

    This variable can be set to the following values:

    - `0`

        Use the original Direct3D 9 API (default)

    - `1`

        Use the Direct3D 9Ex API on Vista and later (and fall back if D3D9Ex is
        unavailable)

- `SDL_HINT_VIDEO_DOUBLE_BUFFER`

    Tell the video driver that we only want a double buffer.

    By default, most lowlevel 2D APIs will use a triple buffer scheme that wastes
    no CPU time on waiting for vsync after issuing a flip, but introduces a frame
    of latency. On the other hand, using a double buffer scheme instead is
    recommended for cases where low latency is an important factor because we save
    a whole frame of latency. We do so by waiting for vsync immediately after
    issuing a flip, usually just after eglSwapBuffers call in the backend's
    \*\_SwapWindow function.

    Since it's driver-specific, it's only supported where possible and implemented.
    Currently supported the following drivers:

    - KMSDRM (kmsdrm)
    - Raspberry Pi (raspberrypi)

- `SDL_HINT_KMSDRM_REQUIRE_DRM_MASTER`

    Determines whether SDL enforces that DRM master is required in order to
    initialize the KMSDRM video backend.

    The DRM subsystem has a concept of a "DRM master" which is a DRM client that
    has the ability to set planes, set cursor, etc. When SDL is DRM master, it can
    draw to the screen using the SDL rendering APIs. Without DRM master, SDL is
    still able to process input and query attributes of attached displays, but it
    cannot change display state or draw to the screen directly.

    In some cases, it can be useful to have the KMSDRM backend even if it cannot be
    used for rendering. An app may want to use SDL for input processing while using
    another rendering API (such as an MMAL overlay on Raspberry Pi) or using its
    own code to render to DRM overlays that SDL doesn't support.

    This hint must be set before initializing the video subsystem.

    This variable can be set to the following values:

    - `0`

        SDL will allow usage of the KMSDRM backend without DRM master

    - `1`

        SDL Will require DRM master to use the KMSDRM backend (default)

- `SDL_HINT_OPENGL_ES_DRIVER`

    A variable controlling what driver to use for OpenGL ES contexts.

    On some platforms, currently Windows and X11, OpenGL drivers may support
    creating contexts with an OpenGL ES profile. By default SDL uses these
    profiles, when available, otherwise it attempts to load an OpenGL ES library,
    e.g. that provided by the ANGLE project. This variable controls whether SDL
    follows this default behaviour or will always load an OpenGL ES library.

    Circumstances where this is useful include

    - - Testing an app with a particular OpenGL ES implementation, e.g ANGLE, or emulator, e.g. those from ARM, Imagination or Qualcomm.
    - Resolving OpenGL ES function addresses at link time by linking with the OpenGL ES library instead of querying them at run time with `SDL_GL_GetProcAddress( )`.

    Caution: for an application to work with the default behaviour across different
    OpenGL drivers it must query the OpenGL ES function addresses at run time using
    `SDL_GL_GetProcAddress( )`.

    This variable is ignored on most platforms because OpenGL ES is native or not
    supported.

    This variable can be set to the following values:

    - `0`

        Use ES profile of OpenGL, if available. (Default when not set.)

    - `1`

        Load OpenGL ES library using the default library names.

- `SDL_HINT_AUDIO_RESAMPLING_MODE`

    A variable controlling speed/quality tradeoff of audio resampling.

    If available, SDL can use libsamplerate ( http://www.mega-nerd.com/SRC/ ) to
    handle audio resampling. There are different resampling modes available that
    produce different levels of quality, using more CPU.

    If this hint isn't specified to a valid setting, or libsamplerate isn't
    available, SDL will use the default, internal resampling algorithm.

    Note that this is currently only applicable to resampling audio that is being
    written to a device for playback or audio being read from a device for capture.
    SDL\_AudioCVT always uses the default resampler (although this might change for
    SDL 2.1).

    This hint is currently only checked at audio subsystem initialization.

    This variable can be set to the following values:

    - `0` or `default`

        Use SDL's internal resampling (Default when not set - low quality, fast)

    - `1` or `fast`

        Use fast, slightly higher quality resampling, if available

    - `2` or `medium`

        Use medium quality resampling, if available

    - `3` or `best`

        Use high quality resampling, if available

- `SDL_HINT_AUDIO_CATEGORY`

    A variable controlling the audio category on iOS and Mac OS X.

    This variable can be set to the following values:

    - `ambient`

        Use the AVAudioSessionCategoryAmbient audio category, will be muted by the
        phone mute switch (default)

    - `playback`

        Use the AVAudioSessionCategoryPlayback category

    For more information, see Apple's documentation:
    [https://developer.apple.com/library/content/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioSessionCategoriesandModes/AudioSessionCategoriesandModes.html](https://developer.apple.com/library/content/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioSessionCategoriesandModes/AudioSessionCategoriesandModes.html)

- `SDL_HINT_RENDER_BATCHING`

    A variable controlling whether the 2D render API is compatible or efficient.

    This variable can be set to the following values:

    - `0`

        Don't use batching to make rendering more efficient.

    - `1`

        Use batching, but might cause problems if app makes its own direct OpenGL
        calls.

    Up to SDL 2.0.9, the render API would draw immediately when requested. Now it
    batches up draw requests and sends them all to the GPU only when forced to
    (during SDL\_RenderPresent, when changing render targets, by updating a texture
    that the batch needs, etc). This is significantly more efficient, but it can
    cause problems for apps that expect to render on top of the render API's
    output. As such, SDL will disable batching if a specific render backend is
    requested (since this might indicate that the app is planning to use the
    underlying graphics API directly). This hint can be used to explicitly request
    batching in this instance. It is a contract that you will either never use the
    underlying graphics API directly, or if you do, you will call
    `SDL_RenderFlush( )` before you do so any current batch goes to the GPU before
    your work begins. Not following this contract will result in undefined
    behavior.

- `SDL_HINT_AUTO_UPDATE_JOYSTICKS`

    A variable controlling whether SDL updates joystick state when getting input
    events

    This variable can be set to the following values:

    - `0`

        You'll call `SDL_JoystickUpdate( )` manually

    - `1`

        SDL will automatically call `SDL_JoystickUpdate( )` (default)

    This hint can be toggled on and off at runtime.

- `SDL_HINT_AUTO_UPDATE_SENSORS`

    A variable controlling whether SDL updates sensor state when getting input
    events

    This variable can be set to the following values:

    - `0`

        You'll call `SDL_SensorUpdate ( )` manually

    - `1`

        SDL will automatically call `SDL_SensorUpdate( )` (default)

    This hint can be toggled on and off at runtime.

- `SDL_HINT_EVENT_LOGGING`

    A variable controlling whether SDL logs all events pushed onto its internal
    queue.

    This variable can be set to the following values:

    - `0`

        Don't log any events (default)

    - `1`

        Log all events except mouse and finger motion, which are pretty spammy.

    - `2`

        Log all events.

    This is generally meant to be used to debug SDL itself, but can be useful for
    application developers that need better visibility into what is going on in the
    event queue. Logged events are sent through `SDL_Log( )`, which means by
    default they appear on stdout on most platforms or maybe `OutputDebugString(
    )` on Windows, and can be funneled by the app with `SDL_LogSetOutputFunction(
    )`, etc.

    This hint can be toggled on and off at runtime, if you only need to log events
    for a small subset of program execution.

- `SDL_HINT_WAVE_RIFF_CHUNK_SIZE`

    Controls how the size of the RIFF chunk affects the loading of a WAVE file.

    The size of the RIFF chunk (which includes all the sub-chunks of the WAVE file)
    is not always reliable. In case the size is wrong, it's possible to just ignore
    it and step through the chunks until a fixed limit is reached.

    Note that files that have trailing data unrelated to the WAVE file or corrupt
    files may slow down the loading process without a reliable boundary. By
    default, SDL stops after 10000 chunks to prevent wasting time. Use the
    environment variable SDL\_WAVE\_CHUNK\_LIMIT to adjust this value.

    This variable can be set to the following values:

    - `force`

        Always use the RIFF chunk size as a boundary for the chunk search

    - `ignorezero`

        Like "force", but a zero size searches up to 4 GiB (default)

    - `ignore`

        Ignore the RIFF chunk size and always search up to 4 GiB

    - `maximum`

        Search for chunks until the end of file (not recommended)

- `SDL_HINT_WAVE_TRUNCATION`

    Controls how a truncated WAVE file is handled.

    A WAVE file is considered truncated if any of the chunks are incomplete or the
    data chunk size is not a multiple of the block size. By default, SDL decodes
    until the first incomplete block, as most applications seem to do.

    This variable can be set to the following values:

    - `verystrict`

        Raise an error if the file is truncated

    - `strict`

        Like "verystrict", but the size of the RIFF chunk is ignored

    - `dropframe`

        Decode until the first incomplete sample frame

    - `dropblock`

        Decode until the first incomplete block (default)

- `SDL_HINT_WAVE_FACT_CHUNK`

    Controls how the fact chunk affects the loading of a WAVE file.

    The fact chunk stores information about the number of samples of a WAVE file.
    The Standards Update from Microsoft notes that this value can be used to
    'determine the length of the data in seconds'. This is especially useful for
    compressed formats (for which this is a mandatory chunk) if they produce
    multiple sample frames per block and truncating the block is not allowed. The
    fact chunk can exactly specify how many sample frames there should be in this
    case.

    Unfortunately, most application seem to ignore the fact chunk and so SDL
    ignores it by default as well.

    This variable can be set to the following values:

    - `truncate`

        Use the number of samples to truncate the wave data if the fact chunk is
        present and valid

    - `strict`

        Like "truncate", but raise an error if the fact chunk is invalid, not present
        for non-PCM formats, or if the data chunk doesn't have that many samples

    - `ignorezero`

        Like "truncate", but ignore fact chunk if the number of samples is zero

    - `ignore`

        Ignore fact chunk entirely (default)

- `SDL_HINT_DISPLAY_USABLE_BOUNDS`

    Override for `SDL_GetDisplayUsableBounds( )`

    If set, this hint will override the expected results for
    `SDL_GetDisplayUsableBounds( )` for display index 0. Generally you don't want
    to do this, but this allows an embedded system to request that some of the
    screen be reserved for other uses when paired with a well-behaved application.

    The contents of this hint must be 4 comma-separated integers, the first is the
    bounds x, then y, width and height, in that order.

- `SDL_HINT_AUDIO_DEVICE_APP_NAME`

    Specify an application name for an audio device.

    Some audio backends (such as PulseAudio) allow you to describe your audio
    stream. Among other things, this description might show up in a system control
    panel that lets the user adjust the volume on specific audio streams instead of
    using one giant master volume slider.

    This hints lets you transmit that information to the OS. The contents of this
    hint are used while opening an audio device. You should use a string that
    describes your program ("My Game 2: The Revenge")

    Setting this to "" or leaving it unset will have SDL use a reasonable default:
    probably the application's name or "SDL Application" if SDL doesn't have any
    better information.

    On targets where this is not supported, this hint does nothing.

- `SDL_HINT_AUDIO_DEVICE_STREAM_NAME`

    Specify an application name for an audio device.

    Some audio backends (such as PulseAudio) allow you to describe your audio
    stream. Among other things, this description might show up in a system control
    panel that lets the user adjust the volume on specific audio streams instead of
    using one giant master volume slider.

    This hints lets you transmit that information to the OS. The contents of this
    hint are used while opening an audio device. You should use a string that
    describes your what your program is playing ("audio stream" is probably
    sufficient in many cases, but this could be useful for something like "team
    chat" if you have a headset playing VoIP audio separately).

    Setting this to "" or leaving it unset will have SDL use a reasonable default:
    "audio stream" or something similar.

    On targets where this is not supported, this hint does nothing.

- `SDL_HINT_AUDIO_DEVICE_STREAM_ROLE`

    Specify an application role for an audio device.

    Some audio backends (such as Pipewire) allow you to describe the role of your
    audio stream. Among other things, this description might show up in a system
    control panel or software for displaying and manipulating media
    playback/capture graphs.

    This hints lets you transmit that information to the OS. The contents of this
    hint are used while opening an audio device. You should use a string that
    describes your what your program is playing (Game, Music, Movie, etc...).

    Setting this to "" or leaving it unset will have SDL use a reasonable default:
    "Game" or something similar.

    On targets where this is not supported, this hint does nothing.

- `SDL_HINT_ALLOW_ALT_TAB_WHILE_GRABBED`

    Specify the behavior of Alt+Tab while the keyboard is grabbed.

    By default, SDL emulates Alt+Tab functionality while the keyboard is grabbed
    and your window is full-screen. This prevents the user from getting stuck in
    your application if you've enabled keyboard grab.

    The variable can be set to the following values:

    - `0`

        SDL will not handle Alt+Tab. Your application is responsible for handling
        Alt+Tab while the keyboard is grabbed.

    - `1`

        SDL will minimize your window when Alt+Tab is pressed (default)

- `SDL_HINT_PREFERRED_LOCALES`

    Override for SDL\_GetPreferredLocales( )

    If set, this will be favored over anything the OS might report for the user's
    preferred locales. Changing this hint at runtime will not generate a
    SDL\_LOCALECHANGED event (but if you can change the hint, you can push your own
    event, if you want).

    The format of this hint is a comma-separated list of language and locale,
    combined with an underscore, as is a common format: "en\_GB". Locale is
    optional: "en". So you might have a list like this: "en\_GB,jp,es\_PT"

## `:logcategory`

The predefined log categories

By default the application category is enabled at the INFO level, the assert
category is enabled at the WARN level, test is enabled at the VERBOSE level and
all other categories are enabled at the CRITICAL level.

- `SDL_LOG_CATEGORY_APPLICATION`
- `SDL_LOG_CATEGORY_ERROR`
- `SDL_LOG_CATEGORY_ASSERT`
- `SDL_LOG_CATEGORY_SYSTEM`
- `SDL_LOG_CATEGORY_AUDIO`
- `SDL_LOG_CATEGORY_VIDEO`
- `SDL_LOG_CATEGORY_RENDER`
- `SDL_LOG_CATEGORY_INPUT`
- `SDL_LOG_CATEGORY_TEST`
- `SDL_LOG_CATEGORY_RESERVED1`
- `SDL_LOG_CATEGORY_RESERVED2`
- `SDL_LOG_CATEGORY_RESERVED3`
- `SDL_LOG_CATEGORY_RESERVED4`
- `SDL_LOG_CATEGORY_RESERVED5`
- `SDL_LOG_CATEGORY_RESERVED6`
- `SDL_LOG_CATEGORY_RESERVED7`
- `SDL_LOG_CATEGORY_RESERVED8`
- `SDL_LOG_CATEGORY_RESERVED9`
- `SDL_LOG_CATEGORY_RESERVED10`
- `SDL_LOG_CATEGORY_CUSTOM`

## `:logpriority`

The predefined log priorities.

- `SDL_LOG_PRIORITY_VERBOSE`
- `SDL_LOG_PRIORITY_DEBUG`
- `SDL_LOG_PRIORITY_INFO`
- `SDL_LOG_PRIORITY_WARN`
- `SDL_LOG_PRIORITY_ERROR`
- `SDL_LOG_PRIORITY_CRITICAL`
- `SDL_NUM_LOG_PRIORITIES`

## `:windowflags`

The flags on a window.

- `SDL_WINDOW_FULLSCREEN` - Fullscreen window
- `SDL_WINDOW_OPENGL` - Window usable with OpenGL context
- `SDL_WINDOW_SHOWN` - Window is visible
- `SDL_WINDOW_HIDDEN` - Window is not visible
- `SDL_WINDOW_BORDERLESS` - No window decoration
- `SDL_WINDOW_RESIZABLE` - Window can be resized
- `SDL_WINDOW_MINIMIZED` - Window is minimized
- `SDL_WINDOW_MAXIMIZED` - Window is maximized
- `SDL_WINDOW_MOUSE_GRABBED` - Window has grabbed mouse input
- `SDL_WINDOW_INPUT_FOCUS` - Window has input focus
- `SDL_WINDOW_MOUSE_FOCUS` - Window has mouse focus
- `SDL_WINDOW_FULLSCREEN_DESKTOP` - Fullscreen window without frame
- `SDL_WINDOW_FOREIGN` - Window not created by SDL
- `SDL_WINDOW_ALLOW_HIGHDPI` - Window should be created in high-DPI mode if supported.

    On macOS NSHighResolutionCapable must be set true in the application's
    Info.plist for this to have any effect.

- `SDL_WINDOW_MOUSE_CAPTURE` - Window has mouse captured (unrelated to `MOUSE_GRABBED`)
- `SDL_WINDOW_ALWAYS_ON_TOP` - Window should always be above others
- `SDL_WINDOW_SKIP_TASKBAR` - Window should not be added to the taskbar
- `SDL_WINDOW_UTILITY` - Window should be treated as a utility window
- `SDL_WINDOW_TOOLTIP` - Window should be treated as a tooltip
- `SDL_WINDOW_POPUP_MENU` - Window should be treated as a popup menu
- `SDL_WINDOW_KEYBOARD_GRABBED` - Window has grabbed keyboard input
- `SDL_WINDOW_VULKAN` - Window usable for Vulkan surface
- `SDL_WINDOW_METAL` - Window usable for Metal view
- `SDL_WINDOW_INPUT_GRABBED` - Equivalent to `SDL_WINDOW_MOUSE_GRABBED` for compatibility

## `:windowEventID`

Event subtype for window events.

- `SDL_WINDOWEVENT_NONE` - Never used
- `SDL_WINDOWEVENT_SHOWN` - Window has been shown
- `SDL_WINDOWEVENT_HIDDEN` - Window has been hidden
- `SDL_WINDOWEVENT_EXPOSED` - Window has been exposed and should be redrawn
- `SDL_WINDOWEVENT_MOVED` - Window has been moved to `data1, data2`
- `SDL_WINDOWEVENT_RESIZED` - Window has been resized to `data1 x data2`
- `SDL_WINDOWEVENT_SIZE_CHANGED` - The window size has changed, either as a result of an API call or through the system or user changing the window size.
- `SDL_WINDOWEVENT_MINIMIZED` - Window has been minimized
- `SDL_WINDOWEVENT_MAXIMIZED` - Window has been maximized
- `SDL_WINDOWEVENT_RESTORED` - Window has been restored to normal size and position
- `SDL_WINDOWEVENT_ENTER` - Window has gained mouse focus
- `SDL_WINDOWEVENT_LEAVE` - Window has lost mouse focus
- `SDL_WINDOWEVENT_FOCUS_GAINED` - Window has gained keyboard focus
- `SDL_WINDOWEVENT_FOCUS_LOST` - Window has lost keyboard focus
- `SDL_WINDOWEVENT_CLOSE` - The window manager requests that the window be closed
- `SDL_WINDOWEVENT_TAKE_FOCUS` - Window is being offered a focus (should `SetWindowInputFocus( )` on itself or a subwindow, or ignore)
- `SDL_WINDOWEVENT_HIT_TEST` - Window had a hit test that wasn't `SDL_HITTEST_NORMAL`.

## `:displayEventID`

Event subtype for display events.

- `SDL_DISPLAYEVENT_NONE` - Never used
- `SDL_DISPLAYEVENT_ORIENTATION` - Display orientation has changed to data1
- `SDL_DISPLAYEVENT_CONNECTED` - Display has been added to the system
- `SDL_DISPLAYEVENT_DISCONNECTED` - Display has been removed from the system

## `:displayOrientation`

- `SDL_ORIENTATION_UNKNOWN` - The display orientation can't be determined
- `SDL_ORIENTATION_LANDSCAPE` - The display is in landscape mode, with the right side up, relative to portrait mode
- `SDL_ORIENTATION_LANDSCAPE_FLIPPED` - The display is in landscape mode, with the left side up, relative to portrait mode
- `SDL_ORIENTATION_PORTRAIT` - The display is in portrait mode
- `SDL_ORIENTATION_PORTRAIT_FLIPPED` - The display is in portrait mode, upside down

## `:glAttr`

OpenGL configuration attributes.

- `SDL_GL_RED_SIZE`
- `SDL_GL_GREEN_SIZE`
- `SDL_GL_BLUE_SIZE`
- `SDL_GL_ALPHA_SIZE`
- `SDL_GL_BUFFER_SIZE`
- `SDL_GL_DOUBLEBUFFER`
- `SDL_GL_DEPTH_SIZE`
- `SDL_GL_STENCIL_SIZE`
- `SDL_GL_ACCUM_RED_SIZE`
- `SDL_GL_ACCUM_GREEN_SIZE`
- `SDL_GL_ACCUM_BLUE_SIZE`
- `SDL_GL_ACCUM_ALPHA_SIZE`
- `SDL_GL_STEREO`
- `SDL_GL_MULTISAMPLEBUFFERS`
- `SDL_GL_MULTISAMPLESAMPLES`
- `SDL_GL_ACCELERATED_VISUAL`
- `SDL_GL_RETAINED_BACKING`
- `SDL_GL_CONTEXT_MAJOR_VERSION`
- `SDL_GL_CONTEXT_MINOR_VERSION`
- `SDL_GL_CONTEXT_EGL`
- `SDL_GL_CONTEXT_FLAGS`
- `SDL_GL_CONTEXT_PROFILE_MASK`
- `SDL_GL_SHARE_WITH_CURRENT_CONTEXT`
- `SDL_GL_FRAMEBUFFER_SRGB_CAPABLE`
- `SDL_GL_CONTEXT_RELEASE_BEHAVIOR`
- `SDL_GL_CONTEXT_RESET_NOTIFICATION`
- `SDL_GL_CONTEXT_NO_ERROR`

## `:glProfile`

- `SDL_GL_CONTEXT_PROFILE_CORE`
- `SDL_GL_CONTEXT_PROFILE_COMPATIBILITY`
- `SDL_GL_CONTEXT_PROFILE_ES`

## `:glContextFlag`

- `SDL_GL_CONTEXT_DEBUG_FLAG`
- `SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG`
- `SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG`
- `SDL_GL_CONTEXT_RESET_ISOLATION_FLAG`

## `:glContextReleaseFlag`

- `SDL_GL_CONTEXT_RELEASE_BEHAVIOR_NONE`
- `SDL_GL_CONTEXT_RELEASE_BEHAVIOR_FLUSH`

## `:glContextResetNotification`

- `SDL_GL_CONTEXT_RESET_NO_NOTIFICATION`
- `SDL_GL_CONTEXT_RESET_LOSE_CONTEXT`

## `:rendererFlags`

Flags used when creating a rendering context.

- `SDL_RENDERER_SOFTWARE` - The renderer is a software fallback
- `SDL_RENDERER_ACCELERATED` - The renderer uses hardware acceleration
- `SDL_RENDERER_PRESENTVSYNC` - Present is synchronized with the refresh rate
- `SDL_RENDERER_TARGETTEXTURE` - The renderer supports rendering to texture

## `:scaleMode`

The scaling mode for a texture.

- `SDL_SCALEMODENEAREST` - nearest pixel sampling
- `SDL_SCALEMODELINEAR` - linear filtering
- `SDL_SCALEMODEBEST` - anisotropic filtering

## `:textureAccess`

The access pattern allowed for a texture.

- `SDL_TEXTUREACCESS_STATIC` - Changes rarely, not lockable
- `SDL_TEXTUREACCESS_STREAMING` - Changes frequently, lockable
- `SDL_TEXTUREACCESS_TARGET` - Texture can be used as a render target

## `:textureModulate`

The texture channel modulation used in [`SDL_RenderCopy( ...
)`](#sdl_rendercopy).

- `SDL_TEXTUREMODULATE_NONE` - No modulation
- `SDL_TEXTUREMODULATE_COLOR` - srcC = srcC \* color
- `SDL_TEXTUREMODULATE_ALPHA` - srcA = srcA \* alpha

## `:renderFlip`

Flip constants for [`SDL_RenderCopyEx( ... )`](#sdl_rendercopyex).

- `SDL_FLIP_NONE` - do not flip
- `SDL_FLIP_HORIZONTAL` - flip horizontally
- `SDL_FLIP_VERTICAL` - flip vertically

## `:blendMode`

The blend mode used in [`SDL_RenderCopy( ... )`](#sdl_rendercopy) and drawing operations.

- `SDL_BLENDMODE_NONE` - no blending

            dstRGBA = srcRGBA

- `SDL_BLENDMODE_BLEND` - alpha blending

            dstRGB = (srcRGB * srcA) + (dstRGB * (1-srcA))
        dstA = srcA + (dstA * (1-srcA))

- `SDL_BLENDMODE_ADD` - additive blending

            dstRGB = (srcRGB * srcA) + dstRGB
            dstA = dstA

- `SDL_BLENDMODE_MOD` - color modulate

            dstRGB = srcRGB * dstRGB
            dstA = dstA

- `SDL_BLENDMODE_MUL` - color multiply

            dstRGB = (srcRGB * dstRGB) + (dstRGB * (1-srcA))
            dstA = (srcA * dstA) + (dstA * (1-srcA))

- `SDL_BLENDMODE_INVALID` -

Additional custom blend modes can be returned by [`SDL_ComposeCustomBlendMode( ... )`](#sdl_composecustomblendmode)

## `:blendOperation`

The blend operation used when combining source and destination pixel
components.

- `SDL_BLENDOPERATION_ADD` - `dst + src`: supported by all renderers
- `SDL_BLENDOPERATION_SUBTRACT` - `dst - src`: supported by D3D9, D3D11, OpenGL, OpenGLES
- `SDL_BLENDOPERATION_REV_SUBTRACT` - `src - dst`: supported by D3D9, D3D11, OpenGL, OpenGLES
- `SDL_BLENDOPERATION_MINIMUM` - `min(dst, src)`: supported by D3D11
- `SDL_BLENDOPERATION_MAXIMUM` - `max(dst, src)`: supported by D3D11

## `:blendFactor`

The normalized factor used to multiply pixel components.

- `SDL_BLENDFACTOR_ZERO` - `0, 0, 0, 0`
- `SDL_BLENDFACTOR_ONE` - `1, 1, 1, 1`
- `SDL_BLENDFACTOR_SRC_COLOR` - `srcR, srcG, srcB, srcA`
- `SDL_BLENDFACTOR_ONE_MINUS_SRC_COLOR` - `1-srcR, 1-srcG, 1-srcB, 1-srcA`
- `SDL_BLENDFACTOR_SRC_ALPHA` - `srcA, srcA, srcA, srcA`
- `SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA` - `1-srcA, 1-srcA, 1-srcA, 1-srcA`
- `SDL_BLENDFACTOR_DST_COLOR` - `dstR, dstG, dstB, dstA`
- `SDL_BLENDFACTOR_ONE_MINUS_DST_COLOR` - `1-dstR, 1-dstG, 1-dstB, 1-dstA`
- `SDL_BLENDFACTOR_DST_ALPHA` - `dstA, dstA, dstA, dstA`
- `SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA` - `1-dstA, 1-dstA, 1-dstA, 1-dstA`

## `:audio`

Audio format flags.

These are what the 16 bits in SDL\_AudioFormat currently mean... (Unspecified
bits are always zero).

    ++-----------------------sample is signed if set
    ||
    ||       ++-----------sample is bigendian if set
    ||       ||
    ||       ||          ++---sample is float if set
    ||       ||          ||
    ||       ||          || +---sample bit size---+
    ||       ||          || |                     |
    15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00

There are macros in SDL 2.0 and later to query these bits.

### Audio flags

- `SDL_AUDIO_MASK_BITSIZE`
- `SDL_AUDIO_MASK_DATATYPE`
- `SDL_AUDIO_MASK_ENDIAN`
- `SDL_AUDIO_MASK_SIGNED`
- `SDL_AUDIO_BITSIZE`
- `SDL_AUDIO_ISFLOAT`
- `SDL_AUDIO_ISBIGENDIAN`
- `SDL_AUDIO_ISSIGNED`
- `SDL_AUDIO_ISINT`
- `SDL_AUDIO_ISLITTLEENDIAN`
- `SDL_AUDIO_ISUNSIGNED`

### Audio format flags

Defaults to LSB byte order.

- `AUDIO_U8` - Unsigned 8-bit samples
- `AUDIO_S8` - Signed 8-bit samples
- `AUDIO_U16LSB` - Unsigned 16-bit samples
- `AUDIO_S16LSB` - Signed 16-bit samples
- `AUDIO_U16MSB` - As above, but big-endian byte order
- `AUDIO_S16MSB` - As above, but big-endian byte order
- `AUDIO_U16` - `AUDIO_U16LSB`
- `AUDIO_S16` - `AUDIO_S16LSB`

### `int32` support

- `AUDIO_S32LSB` - 32-bit integer samples
- `AUDIO_S32MSB` - As above, but big-endian byte order
- `AUDIO_S32` - `AUDIO_S32LSB`

### `float32` support

- `AUDIO_F32LSB` - 32-bit floating point samples
- `AUDIO_F32MSB` - As above, but big-endian byte order
- `AUDIO_F32` - `AUDIO_F32LSB`

### Native audio byte ordering

- `AUDIO_U16SYS`
- `AUDIO_S16SYS`
- `AUDIO_S32SYS`
- `AUDIO_F32SYS`

### Allow change flags

Which audio format changes are allowed when opening a device.

- `SDL_AUDIO_ALLOW_FREQUENCY_CHANGE`
- `SDL_AUDIO_ALLOW_FORMAT_CHANGE`
- `SDL_AUDIO_ALLOW_CHANNELS_CHANGE`
- `SDL_AUDIO_ALLOW_SAMPLES_CHANGE`
- `SDL_AUDIO_ALLOW_ANY_CHANGE`

# Development

SDL2 is still in early development: the majority of SDL's functions have yet to
be implemented and the interface may also grow to be less sugary leading up to
an eventual 1.0 release. If you like stable, well tested software that performs
as documented, you should hold off on trying to use SDL2 for a bit.

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
