# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0]

### Added
- Added `--help`, `--version` support to `term-datamatrix` script
- Added man page for `term-datamatrix` script

### Changed
- Replace `Module::Install` build with `ExtUtils::MakeMaker`
- No longer use `FindBin` when installed
- Update POD
- Don't set `->{stdoutbuf}` on the object for every barcode
- Use 'fields' to restrict object members

## [0.01] - 2013-08-31
Initial published version

[Unreleased]: https://codeberg.org/h3xx/perl-Term-DataMatrix/compare/v1.0.0...HEAD
[1.0.0]: https://codeberg.org/h3xx/perl-Term-DataMatrix/compare/v0.01...v1.0.0
[0.01]: https://codeberg.org/h3xx/perl-Term-DataMatrix/releases/tag/v0.01
