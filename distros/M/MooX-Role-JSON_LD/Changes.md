# Change Log

## [2.1.0] - 2025-10-07

### Changed

- Only emit the '@context' key for the top-level JSON-LD

## [2.0.0] - 2025-06-05

### Changed

- Use 'https' for the schema.org URI

## [1.1.0] - 2025-01-08

### Added

- New `json_ld_wrapped()` method

- Documentation for methods

## [1.0.1] - 2021-06-06

### Fixed

- Decreased code complexity

- Bring version numbers in line across modules

### Added

- Github Actions CI

## [1.0.0] - 2020-03-12

### Fixed

- Tidied SYNOPSIS example code.

- Bumped to version 1.0.0.

## [0.0.18] - 2020-03-11

### Fixed

- Fix problem with nested objects of same type (Github #23)

## [0.0.17] - 2020-03-10

### Fixed

- Fix problem with arrays of objects (Github #22)

- Fix installation of MooX::JSON_LD methods into Moo roles.

- Fix inconsistent version between modules.

- Fix minimum prereq for List::Util.

## [0.0.16] - 2018-11-06

### Fixed

- Fix typo in SYNOPSIS.

- Do not apply role from MooX::JSON_LD if the target is a role or it
  already has the expected methods.

  This should fix issues with inheritance, but existing code that
  works around this bug may need to be updated.

- Allow `_build_json_ld_encoder` method to be overridden.

- Explicitly test subclass parent.

## [0.0.14] - 2018-07-31

### Changed

- Changed context attribute to be lazy.

- Removed dependency on Ref::Util

## [0.0.13] - 2018-06-02

### Fixed

- Removed Perl v5.10+ code that was not actually used.

## [0.0.12] - 2018-05-30

### Fixed

- Fix handling of subclasses in MooX::JSON_LD. It will inherit fields
  defined in parent classes.

- Fixed namespace::autoclean pre-req.

## [0.0.11] - 2018-05-28

### Fixed

- Added namespace::autoclean

## [0.0.10] - 2018-05-28

### Fixed

- Added missing test module.

## [0.0.9] - 2018-05-28

### Added

- Added MooX::JSON_LD to MANIFEST so it actually gets shipped.

## [0.0.8] - 2018-05-27

### Added

- Allow context to be a hashref or arrayref (thanks robrwo)

- Use JSON::MaybeXS instead of JSON (thanks robrwo)

- Added MooX::JSON_LD helper module (thanks robrwo)

### Fixed

- Typo in documentation (thanks manwar)

## [0.0.7] - 2018-05-26

### Added

- Added tests for configurable contexts

## [0.0.6] - 2018-05-26

### Added

- Make context configurable

## [0.0.5] - 2018-03-30

### Fixed

- More packaging fixes.

## [0.0.4] - 2018-03-30

### Fixed

- Added Changes.md to MANIFEST.

## [0.0.3] - 2018-03-30

### Fixed

- Removed unwanted files from MANIFEST.

## [0.0.2] - 2018-03-30

### Fixed

- Various packaging fixes.

## [0.0.1] - 2018-03-30

### Added

- All the things. Release early, release often.
