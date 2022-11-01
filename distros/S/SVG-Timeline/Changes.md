# Change Log

## [0.1.3] - 2022-11-01

### Fixed

- Bump required Perl version

## [0.1.2] - 2022-10-31

### Fixed

- Add DateTime::Format::Strptime as pre-req

## [0.1.1] - 2022-10-31

### Fixed

- Switch from Time::Piece to DateTime because it handles
  older dates.

## [0.1.0] - 2022-10-30

### Improved

- Support full dates (YYYY-MM-DD) instead of just years for
  start and end events (thanks simbabque and tcheukueppo).

## [0.0.10] - 2022-06-14

### Fixed

- Fixes to the way that we interact with the underlying
  SVG object (thanks choroba)

## [0.0.9] - 2020-12-22

### Fixed

- Added Time::Piece to pre-reqs

## [0.0.8] - 2020-12-21

### Fixed

- Better testing
- More subclassable

### Added

- Bugtracker info

## [0.0.7] - 2017-09-06

### Fixed

- Fixed packaging errors

## [0.0.6] - 2017-08-19

### Improved

- Generally made the class easier to subclass.

## [0.0.5] - 2017-08-19

### Improved

- Let the events draw themselves.
- Moved pod tests from t to xt.

## [0.0.4] - 2017-08-02

### Fixed

- Reverted previous shebang change as the Perl toolchain is cleverer than I thought.

## [0.0.3] - 2017-07-31

### Fixed

- Changed the command line program shebang to use `/usr/bin/env perl`

## [0.0.2] - 2017-07-31

### Fixed

- Various packaing fixes for better kwalitee

## [0.0.1] - 2017-07-29

### Added

- All the things. Release early, release often.
