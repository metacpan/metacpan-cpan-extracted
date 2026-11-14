# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [v0.2.0] - 2026-11-13

### Added

- label_for method that a subclass can override to decide how a migration is named in error messages

## [v0.1.0] - 2026-11-13

### Added

- MojoX::Pg::Migrations::Env, a drop-in Mojo::Pg::Migrations subclass that replaces ${NAME} and ${NAME:-fallback} placeholders in migration sql from the environment

### Build

- Require Mojo::Pg 4.04 and Mojolicious 7.51, run the manifest and perltidy tests only with AUTHOR_TESTING, and test and release to PAUSE with GitHub Actions
