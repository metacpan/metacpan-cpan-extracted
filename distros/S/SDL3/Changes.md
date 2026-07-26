# Changelog

All notable changes to SDL.pm will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

  - Initial release

[Unreleased]: https://github.com/Perl-SDL3/SDL3.pm/compare/v0.0.4...HEAD
[v0.0.4]: https://github.com/Perl-SDL3/SDL3.pm/compare/v0.0.3...v0.0.4
[v0.0.3]: https://github.com/Perl-SDL3/SDL3.pm/compare/v0.0.2...v0.0.3
[v0.0.2]: https://github.com/Perl-SDL3/SDL3.pm/compare/v0.0.1...v0.0.2
[v0.0.1]: https://github.com/Perl-SDL3/SDL3.pm/releases/tag/v0.0.1
