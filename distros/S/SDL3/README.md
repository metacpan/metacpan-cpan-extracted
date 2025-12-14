# NAME

SDL3 - Perl Wrapper for the Simple DirectMedia Layer 3.0

# SYNOPSIS

```perl
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
```

# DESCRIPTION

This module provides a Perl wrapper for SDL3, a cross-platform development library designed to provide low level access
to audio, keyboard, mouse, joystick, and graphics hardware.

This is very much still under construction. There are a few examples in this distribution's `eg/` directory but a few
games and other demos I've written may be found on github: [https://github.com/sanko/SDL3.pm-demos](https://github.com/sanko/SDL3.pm-demos).

## Features

Each feature listed below is a tag you may use.

### `:all`

This binds all functions, defines all types, and imports them into your package.

See [the SDL3 Wiki](https://wiki.libsdl.org/SDL3/FrontPage) for documentation of the hundreds of types and functions
you'll have access to with this import tag.

### `:asyncio` - Async I/O

SDL offers a way to perform I/O asynchronously. This allows an app to read or write files without waiting for data to
actually transfer; the functions that request I/O never block while the request is fulfilled.

See [SDL3: CategoryAsyncIO](https://wiki.libsdl.org/SDL3/CategoryAsyncIO)

### `:atomic` - Atomic Operations

Atomic operations.

IMPORTANT: If you are not an expert in concurrent lockless programming, you should not be using any functions in this
file. You should be protecting your data structures with full mutexes instead.

See [SDL3: CategoryAtomic](https://wiki.libsdl.org/SDL3/CategoryAtomic)

### `:audio` - Audio Playback, Recording, and Mixing

Audio functionality for the SDL library.

All audio in SDL3 revolves around `SDL_AudioStream`. Whether you want to play or record audio, convert it, stream it,
buffer it, or mix it, you're going to be passing it through an audio stream.

See [SDL3: CategoryAudio](https://wiki.libsdl.org/SDL3/CategoryAudio)

### `:bits` - CategoryBlendmode

Functions for fiddling with bits and bitmasks.

See [SDL3: CategoryBits](https://wiki.libsdl.org/SDL3/CategoryBits)

### `:blendmode` - Blend modes

Blend modes decide how two colors will mix together. There are both standard modes for basic needs and a means to
create custom modes, dictating what sort of math to do on what color components.

See [SDL3: CategoryBlendmode](https://wiki.libsdl.org/SDL3/CategoryBlendmode)

### `:camera` - Camera Support

Video capture for the SDL library.

See [SDL3: CategoryCamera](https://wiki.libsdl.org/SDL3/CategoryCamera)

### `:clipboard` - Clipboard Handling

SDL provides access to the system clipboard, both for reading information from other processes and publishing
information of its own.

This is not just text! SDL apps can access and publish data by mimetype.

See [SDL3: CategoryClipboard](https://wiki.libsdl.org/SDL3/CategoryClipboard)

### `:cpuinfo` - CPU Feature Detection

CPU feature detection for SDL.

These functions are largely concerned with reporting if the system has access to various SIMD instruction sets, but
also has other important info to share, such as system RAM size and number of logical CPU cores.

See [SDL3: CategoryCPUInfo](https://wiki.libsdl.org/SDL3/CategoryCPUInfo)

### `:dialog` - File Dialogs

File dialog support.

SDL offers file dialogs, to let users select files with native GUI interfaces. There are "open" dialogs, "save"
dialogs, and folder selection dialogs. The app can control some details, such as filtering to specific files, or
whether multiple files can be selected by the user.

Note that launching a file dialog is a non-blocking operation; control returns to the app immediately, and a callback
is called later (possibly in another thread) when the user makes a choice.

See [SDL3: CategoryDialog](https://wiki.libsdl.org/SDL3/CategoryDialog)

### `:error` - Error Handling

Simple error message routines for SDL.

Most apps will interface with these APIs in exactly one function: when almost any SDL function call reports failure,
you can get a human-readable string of the problem from [SDL\_GetError()](https://wiki.libsdl.org/SDL3/SDL_GetError).

See [SDL3: CategoryError](https://wiki.libsdl.org/SDL3/CategoryError)

### `:events` - Event Handling

Event queue management.

See [SDL3: CategoryEvents](https://wiki.libsdl.org/SDL3/CategoryEvents)

### `:filesystem` - Filesystem Access

SDL offers an API for examining and manipulating the system's filesystem. This covers most things one would need to do
with directories, except for actual file I/O.

See [SDL3: CategoryFilesystem](https://wiki.libsdl.org/SDL3/CategoryFilesystem)

### `:gamepad` - Gamepad Support

SDL provides a low-level joystick API, which just treats joysticks as an arbitrary pile of buttons, axes, and hat
switches. If you're planning to write your own control configuration screen, this can give you a lot of flexibility,
but that's a lot of work, and most things that we consider "joysticks" now are actually console-style gamepads. So SDL
provides the gamepad API on top of the lower-level joystick functionality.

See [SDL3: CategoryGamepad](https://wiki.libsdl.org/SDL3/CategoryGamepad)

### `:gpu` - 3D Rendering and GPU Compute

The GPU API offers a cross-platform way for apps to talk to modern graphics hardware. It offers both 3D graphics and
compute support, in the style of Metal, Vulkan, and Direct3D 12.

See [SDL3: CategoryGPU](https://wiki.libsdl.org/SDL3/CategoryGPU)

### `:guid` - GUIDs

A GUID is a 128-bit value that represents something that is uniquely identifiable by this value: "globally unique."

SDL provides functions to convert a GUID to/from a string.

See [SDL3: CategoryGUID](https://wiki.libsdl.org/SDL3/CategoryGUID)

### `:haptic` - Force Feedback Support

The SDL haptic subsystem manages haptic (force feedback) devices.

See [SDL3: CategoryHaptic](https://wiki.libsdl.org/SDL3/CategoryHaptic)

### `:hidapi` - HIDAPI

HID devices.

See [SDL3: CategoryHIDAPI](https://wiki.libsdl.org/SDL3/CategoryHIDAPI)

### `:hints` - Configuration Variables

Functions to set and get configuration hints, as well as listing each of them alphabetically.

See [SDL3: CategoryHints](https://wiki.libsdl.org/SDL3/CategoryHints)

### `:init` - Initialization and Shutdown

All SDL programs need to initialize the library before starting to work with it.

See [SDL3: CategoryInit](https://wiki.libsdl.org/SDL3/CategoryInit)

### `:iostream` - I/O Streams

SDL provides an abstract interface for reading and writing data streams. It offers implementations for files, memory,
etc, and the app can provide their own implementations, too.

SDL\_IOStream is not related to the standard C++ iostream class, other than both are abstract interfaces to read/write
data.

See [SDL3: CategoryIOStream](https://wiki.libsdl.org/SDL3/CategoryIOStream)

### `:joystick` - Joystick Support

SDL joystick support.

This is the lower-level joystick handling. If you want the simpler option, where what each button does is well-defined,
you should use the gamepad API instead.

See [SDL3: CategoryJoystick](https://wiki.libsdl.org/SDL3/CategoryJoystick)

### `:keyboard` - Keyboard Support

SDL keyboard management.

See [SDL3: CategoryKeyboard](https://wiki.libsdl.org/SDL3/CategoryKeyboard)

### `:keycode` - Keyboard Keycodes

Defines constants which identify keyboard keys and modifiers.

See [SDL3: CategoryKeycode](https://wiki.libsdl.org/SDL3/CategoryKeycode)

### `:loadso` - Shared Object/DLL Management

System-dependent library loading routines.

See [SDL3: CategorySharedObject](https://wiki.libsdl.org/SDL3/CategorySharedObject)

### `:locale` - Locale Info

A struct to provide locale data.

This provides a way to get a list of preferred locales (language plus country) for the user. There is exactly one
function: [SDL\_GetPreferredLocales()](https://wiki.libsdl.org/SDL3/SDL_GetPreferredLocales), which handles all the
heavy lifting, and offers documentation on all the strange ways humans might have configured their language settings.

See [SDL3: CategoryLocale](https://wiki.libsdl.org/SDL3/CategoryLocale)

### `:log` - Log Handling

Simple log messages with priorities and categories. A message's `SDL_LogPriority` signifies how important the message
is. A message's `SDL_LogCategory` signifies from what domain it belongs to. Every category has a minimum priority
specified: when a message belongs to that category, it will only be sent out if it has that minimum priority or higher.

See [SDL3: CategoryLog](https://wiki.libsdl.org/SDL3/CategoryLog)

### `:main` - Application entry points

This is a special import tag that informs SDL to use its new callback based App system.

You **must** define [SDL\_AppInit](https://wiki.libsdl.org/SDL3/SDL_AppInit),
[SDL\_AppEvent](https://wiki.libsdl.org/SDL3/SDL_AppEvent),
[SDL\_AppIterate](https://wiki.libsdl.org/SDL3/SDL_AppIterate), and
[SDL\_AppQuit](https://wiki.libsdl.org/SDL3/SDL_AppQuit) in your code.

See `eg/hello_world.pl` for an example and [SDL3: CategoryMain](https://wiki.libsdl.org/SDL3/CategoryMain).

### `:messagebox` - Message Boxes

SDL offers a simple message box API, which is useful for simple alerts, such as informing the user when something fatal
happens at startup without the need to build a UI for it (or informing the user \_before\_ your UI is ready).

See [SDL3: CategoryMessagebox](https://wiki.libsdl.org/SDL3/CategoryMessagebox)

### `:metal` - Metal support

Functions to creating Metal layers and views on SDL windows.

This provides some platform-specific glue for Apple platforms. Most macOS and iOS apps can use SDL without these
functions, but this API they can be useful for specific OS-level integration tasks.

See [SDL3: CategoryMetal](https://wiki.libsdl.org/SDL3/CategoryMetal)

### `:misc` - Miscellaneous

SDL API functions that don't fit elsewhere.

See [SDL3: CategoryMisc](https://wiki.libsdl.org/SDL3/CategoryMisc)

### `:mouse` - Mouse Support

Any GUI application has to deal with the mouse, and SDL provides functions to manage mouse input and the displayed
cursor.

See [SDL3: CategoryMouse](https://wiki.libsdl.org/SDL3/CategoryMouse)

### `:mutex` - Thread Synchronization Primitives

SDL offers several thread synchronization primitives. This document can't cover the complicated topic of thread safety,
but reading up on what each of these primitives are, why they are useful, and how to correctly use them is vital to
writing correct and safe multithreaded programs.

See [SDL3: CategoryMutex](https://wiki.libsdl.org/SDL3/CategoryMutex)

### `:pen` - Pen Support

SDL pen event handling.

SDL provides an API for pressure-sensitive pen (stylus and/or eraser) handling, e.g., for input and drawing tablets or
suitably equipped mobile / tablet devices.

See [SDL3: CategoryPen](https://wiki.libsdl.org/SDL3/CategoryPen)

### `:pixels` - Pixel Formats and Conversion Routines

SDL offers facilities for pixel management.

See [SDL3: CategoryPixels](https://wiki.libsdl.org/SDL3/CategoryPixels)

### `:platform` - Platform Detection

SDL provides a means to identify the app's platform, both at compile time and runtime.

See [SDL3: CategoryPlatform](https://wiki.libsdl.org/SDL3/CategoryPlatform)

### `:power` - Power Management Status

SDL power management routines.

Well, routine.

There is a single function in this category: [SDL\_GetPowerInfo()](https://wiki.libsdl.org/SDL3/SDL_GetPowerInfo).

This function is useful for games on the go. This allows an app to know if it's running on a draining battery, which
can be useful if the app wants to reduce processing, or perhaps framerate, to extend the duration of the battery's
charge. Perhaps the app just wants to show a battery meter when fullscreen, or alert the user when the power is getting
extremely low, so they can save their game.

See [SDL3: CategoryPower](https://wiki.libsdl.org/SDL3/CategoryPower)

### `:process` - Process Control

Process control support.

These functions provide a cross-platform way to spawn and manage OS-level processes.

See [SDL3: CategoryProcess](https://wiki.libsdl.org/SDL3/CategoryProcess)

### `:properties` - Object Properties

A property is a variable that can be created and retrieved by name at runtime.

See [SDL3: CategoryProperties](https://wiki.libsdl.org/SDL3/CategoryProperties)

### `:rect` - Rectangle Functions

Some helper functions for managing rectangles and 2D points, in both integer and floating point versions.

See [SDL3: CategoryRect](https://wiki.libsdl.org/SDL3/CategoryRect)

### `:render` - 2D Accelerated Rendering

SDL 2D rendering functions.

See [SDL3: CategoryRender](https://wiki.libsdl.org/SDL3/CategoryRender)

### `:scancode` - Keyboard Scancodes

The SDL keyboard scancode representation.

An SDL scancode is the physical representation of a key on the keyboard, independent of language and keyboard mapping.

See [SDL3: CategoryScancode](https://wiki.libsdl.org/SDL3/CategoryScancode)

### `:sensor` - Sensors

SDL sensor management.

These APIs grant access to gyros and accelerometers on various platforms.

See [SDL3: CategorySensor](https://wiki.libsdl.org/SDL3/CategorySensor)

### `:storage` - Storage Abstraction

The storage API is a high-level API designed to abstract away the portability issues that come up when using something
lower-level.

See [SDL3: CategoryStorage](https://wiki.libsdl.org/SDL3/CategoryStorage)

### `:surface` - Surface Creation and Simple Drawing

SDL surfaces are buffers of pixels in system RAM. These are useful for passing around and manipulating images that are
not stored in GPU memory.

See [SDL3: CategorySurface](https://wiki.libsdl.org/SDL3/CategorySurface)

### `:stdinc` - Standard Library Functionality

SDL provides its own implementation of some of the most important C runtime functions. Using these functions allows an
app to have access to common C functionality without depending on a specific C runtime (or a C runtime at all).

See [SDL3: CategoryStdinc](https://wiki.libsdl.org/SDL3/CategoryStdinc)

### `:system` - Platform-specific Functionality

Platform-specific SDL API functions. These are functions that deal with needs of specific operating systems, that
didn't make sense to offer as platform-independent, generic APIs.

Most apps can make do without these functions, but they can be useful for integrating with other parts of a specific
system, adding platform-specific polish to an app, or solving problems that only affect one target.

See [SDL3: CategorySystem](https://wiki.libsdl.org/SDL3/CategorySystem)

### `:thread` - Thread Management

SDL offers cross-platform thread management functions. These are mostly concerned with starting threads, setting their
priority, and dealing with their termination.

See [SDL3: CategoryThread](https://wiki.libsdl.org/SDL3/CategoryThread)

### `:time` - Date and Time

SDL realtime clock and date/time routines.

There are two data types that are used in this category: [SDL\_Time](https://wiki.libsdl.org/SDL3/SDL_Time), which
represents the nanoseconds since a specific moment (an "epoch"), and
[SDL\_DateTime](https://wiki.libsdl.org/SDL3/SDL_DateTime), which breaks time down into human-understandable components:
years, months, days, hours, etc.

Much of the functionality is involved in converting those two types to other useful forms.

See [SDL3: CategoryTime](https://wiki.libsdl.org/SDL3/CategoryTime)

### `:timer` - Timer Support

SDL provides time management functionality. It is useful for dealing with (usually) small durations of time.

See [SDL3: CategoryTimer](https://wiki.libsdl.org/SDL3/CategoryTimer)

### `:touch` - Touch Support

SDL offers touch input, on platforms that support it. It can manage multiple touch devices and track multiple fingers
on those devices.

See [SDL3: CategoryTouch](https://wiki.libsdl.org/SDL3/CategoryTouch)

### `:tray` - System Tray

SDL offers a way to add items to the "system tray" (more correctly called the "notification area" on Windows). On
platforms that offer this concept, an SDL app can add a tray icon, submenus, checkboxes, and clickable entries, and
register a callback that is fired when the user clicks on these pieces.

See [SDL3: CategoryTray](https://wiki.libsdl.org/SDL3/CategoryTray)

### `:version` - Querying SDL Version

Functionality to query the current SDL version, both as headers the app was compiled against, and a library the app is
linked to.

See [SDL3: CategoryVersion](https://wiki.libsdl.org/SDL3/CategoryVersion)

### `:video` - Display and Window Management

SDL's video subsystem is largely interested in abstracting window management from the underlying operating system. You
can create windows, manage them in various ways, set them fullscreen, and get events when interesting things happen
with them, such as the mouse or keyboard interacting with a window.

See [SDL3: CategoryVideo](https://wiki.libsdl.org/SDL3/CategoryVideo)

### `:vulkan` - Vulkan Support

Functions for creating Vulkan surfaces on SDL windows.

See [SDL3: CategoryVulkan](https://wiki.libsdl.org/SDL3/CategoryVulkan)

# See Also

The project's repo: [https://github.com/Perl-SDL3/SDL3.pm](https://github.com/Perl-SDL3/SDL3.pm)

The SDL3 Wiki: [https://wiki.libsdl.org/SDL3/FrontPage](https://wiki.libsdl.org/SDL3/FrontPage)

# LICENSE

This software is Copyright (c) 2025 by Sanko Robinson <sanko@cpan.org>.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

See the `LICENSE` file for full text.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
