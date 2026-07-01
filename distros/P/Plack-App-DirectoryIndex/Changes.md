# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.4]

### Fixed

- Lower `MIN_PERL_VERSION` from 5.38.0 to 5.26.0. The module itself only needs
  Perl 5.10, and its only non-core prerequisite (`WebServer::DirIndex`)
  supports Perl 5.26+, so the 5.38 floor was unnecessarily excluding usable
  Perl versions.

### Changed

- CI now tests across Perl 5.26 through 5.42 (previously only `latest`), so the
  declared `MIN_PERL_VERSION` is actually exercised.

## [0.2.3] - 2026-03-16

### Fixed

- Require a version of WebServer::DirIndex that cpanm understands

## [0.2.2] - 2026-03-12

### Fixed

- Require a version of WebServer::DirIndex that declares its version number correctly

## [0.2.1] - 2026-03-10

### Fixed

- We now need WebServer::DirIndex v0.1.0 or greater.

## [0.2.0] - 2026-02-24

### Added

- `icons` attribute to control whether Font Awesome icons are shown in directory listings

## [0.1.0] - 2026-02-21

### Changed

- Move web page production into a separate WebServer::DirIndex CPAN distribution

## [0.0.5] - 2026-02-21

### Added

- Documentation for the `pretty` option

## [0.0.4] - 2023-06-05

### Added

- `pretty` attribute to use nicer CSS for default directory listings

## [0.0.3] - 2020-12-21

### Fixed

- Use File::Spec to make tests more cross-platform

## [0.0.2] - 2020-12-10

### Fixed

- Stop tests failing on Windows

## [0.0.1] - 2020-12-09

### Added

- Everything

