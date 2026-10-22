# Changelog

All notable changes to SDL.pm will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.0.7] - 2026-10-21

### Added

- Document prerequisites based on what I needed to do for the CI.

## [v0.0.6] - 2026-10-20

Finally getting around to SDL3::Mixer, SDL3::Image, and SDL3::TTF.

### Added

- SDL3::Mixer - Load audio files (wav, mp3, ogg, many others), mix multiple sounds, apply effects to them.
- SDL3::Image - Load image files (bmp, gif, jpg, many others) into an SDL_Surface or SDL_Texture.
- SDL3::TTF - Load font files (ttf, etc) and render text with them.
- Loads of demos:
    - `eg/basics/rope.pl` - a port of [rope-jai](https://github.com/tsoding/rope-jai/tree/master)
    - `eg/image/pretty.pl` - displays randomly generated bitmaps.
    - `eg/image/showanim.pl` - displays an animated gif.
    - `eg/image/showclipboard.pl` - displays whatever image is currently on the system clipboard.
    - `eg/image/showimage.pl` - displays a list of image files.
    - `eg/mixer/3d-position.pl` - a quick 3d audio example
    - `eg/mixer/load-and-play.pl` - creates a mixer, loads a single sound, and plays it once
    - `eg/mixer/metadata.pl` - loads a single sound, and displays metadata.
    - `eg/mixer/play-multiple-sounds.pl` - creates a mixer, loads two sounds, and mixes them.
    - `eg/mixer/play-with-options.pl` - creates a mixer, loads a single sound, and plays it with several playback options (fade-in, loop, etc).
    - `eg/mixer/sinewave.pl` - creates a mixer and plays a sinewave forever.
    - `eg/mixer/seeking.pl` - creates a mixer, loads a single sound, and plays it on loop. Also lets the user seek around in playback with an on-screen slider.
    - `eg/mixer/tag-tracks.pl` - a background music track and a pile of sound effects share the mixer just like an actual game.
    - `eg/ttf/hello.pl` - displays 'Hello, World' on screen in a TTF.
    - `eg/ttf/font-styles.pl` - renders a sample string through every font setting that showfont supports and lets you change them while it runs
    - `eg/ttf/showfps.pl` - draws a live frames-per-second counter using a TTF_Text object held on a renderer text engine

### Fixed

- `SDL_RenderGeometry`'s Affix prototype now marks its pointer arguments `Const`, matching the `const SDL_*` parameters in SDL3's headers.

## [v0.0.5] - 2026-08-07

I'm going to bundle all the demos I had hidden away on github to the main SDL3 dist. Maybe someone will actually use this if finding working examples was easier...

### Added

- `eg/audio/polysynth.pl` - a simple polyphonic synthesizer
- `eg/basics/boids.pl` - an [artificial life algotithm](https://en.wikipedia.org/wiki/Boids)
- `eg/basics/bunny_bench.pl` - benchmark of Affix's hot path disguised as an SDL demo
- `eg/basics/matrix.pl` - the Matrix "digital rain" rendered with a procedurally generated glyph atlas
- `eg/basics/message_box.pl` - native message boxes via `SDL_ShowMessageBox` and `SDL_ShowSimpleMessageBox`
- `eg/basics/triangle.pl` - a spinning triangle via `SDL_RenderGeometry`
- `eg/basics/particle_waterfall.pl` - particles that flow between overlapping windows via their OS z-order
- `eg/games/2.5d_map.pl` - an isometric map toy (a "Perl Tycoon" work in progress)
- `eg/games/meteors.pl` - a simple meteor-dodging game
- `eg/games/raycaster_maze.pl` - a "Duke Nukem style" raycaster maze
- `eg/games/safe_cracker.pl` - crack a combination safe with gamepad haptics
- `eg/games/scalar_sprint.pl` - a platformer demonstrating gamepad support
- `eg/games/space_invaders.pl` - space invaders with procedurally generated sprite assets
- `eg/games/tetris.pl` - classic tetromino stacking with score, next-piece preview and landing shadow
- `eg/gpu/hello_world.pl` - a raw GPU swapchain clear-to-color demo proving the render pipeline works
- `eg/renderer/starfield.pl` - an animated starfield drawn via `SDL_RenderPoints`
- Here's a few screenshots:
 - ![https://raw.githubusercontent.com/Perl-SDL3/.github/refs/heads/main/screenshots/tetris.gif]
 - ![https://raw.githubusercontent.com/Perl-SDL3/.github/refs/heads/main/screenshots/particle_waterfall.gif]

### Fixed

- `SDL_AppEvent` callback prototype to expect a pointer to an `SDL_Event`.

### Removed

- `SDL_GDKRunApp` and `SDL_UIKitRunApp` have been deprecated upstream (use `SDL_RunApp` instead).

## [v0.0.4] - 2026-07-25

### Fixed

  - Several functions in `:main` only exist on Windows but were being bound (and failing) on all systems.
  - `:log` functions now support `sprintf` style args that Affix supports varargs. `SDL_Log( 'Current player: %s, Location: x:%d y:%d', 'John', 200, 345 );`

### Changed

- Require Affix v1.1.0

## [v0.0.3] - 2025-12-14

### Changed

  - Require Affix v1.0.2 (critical fix for POSIX: https://github.com/sanko/infix/pull/35)

### Added

  - Copy of the synopsis is now in `eg/synopsis.pl`

## [v0.0.2] - 2025-12-14

### Changed

  - First functioning release :)

## [v0.0.1] 2025-10-06

## News

  - It exists!

[Unreleased]: https://github.com/Perl-SDL3/SDL3.pm/compare/v0.0.7...HEAD
[v0.0.7]: https://github.com/Perl-SDL3/SDL3.pm/compare/v0.0.6...v0.0.7
[v0.0.6]: https://github.com/Perl-SDL3/SDL3.pm/compare/v0.0.5...v0.0.6
[v0.0.5]: https://github.com/Perl-SDL3/SDL3.pm/compare/v0.0.4...v0.0.5
[v0.0.4]: https://github.com/Perl-SDL3/SDL3.pm/compare/v0.0.3...v0.0.4
[v0.0.3]: https://github.com/Perl-SDL3/SDL3.pm/compare/v0.0.2...v0.0.3
[v0.0.2]: https://github.com/Perl-SDL3/SDL3.pm/compare/v0.0.1...v0.0.2
[v0.0.1]: https://github.com/Perl-SDL3/SDL3.pm/releases/tag/v0.0.1
