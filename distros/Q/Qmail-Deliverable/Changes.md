# Changes

Revision history for the `Qmail::Deliverable` Perl extension.

## 1.12

- fix: tests on CPAN smoker machines failed due to umask
- change: shed dependencies, they pull in half of CPAN. :-(
- change: add perltidy and 'make tidy' target

## 1.11

- new: `Qmail::Deliverable::Status` module exporting symbolic constants (`QD_DELIVERABLE`, ...) for the 16 status codes
- fix: sticky-bit homedir check (status `0x22`) used `-T _`  where it should have been `-k _`; the check is now reachable
- change: `qmail-deliverabled` now performs proper daemonization with `POSIX::setsid`; binds the listen socket before forking so port-bind errors are visible
- change: `qmail-deliverabled` installs SIGTERM/SIGINT handlers for clean shutdown, removes the pidfile on exit
- change: `qmail-deliverabled` ignores SIGPIPE so a broken client mid-response does not kill the daemon
- change: removed the deprecated old-style positional argv parsing in `qmail-deliverabled` (deprecated since 1.04, ~2007)
- docs: added signal handling details for SIGHUP, SIGTERM, and SIGINT

## 1.10

- new: a raft of new tests focusing on end-to-end behavior
- change: docs are now in markdown format
- updated attribution for contributors

## 1.09

- new: detect ezmlm lists, reject null senders to lists
- new: correctly ignore comments in `qmail/users/assign` (#3)
- new: add module syntax tests (#3)
- new: add regression test that exercises bug reported in #2
- fix: fix interpretation of wildcard assignments (#2)
- Contributors: Martin Sluka, Matt Simerson

## 1.08

- change: License change only.

## 1.07

- fix: `default@example.org` in `vpopmail/valias` now works as intended.
- new: Support for vpopmail user-ext (disabled by default).
- change: The plugin `check_qmail_deliverable` lost its `check_` prefix.
- Contributor: Matt Simerson

## 1.06

- new: Support for vpopmail `vaddaliasdomain`.

## 1.05

- new: Support for vpopmail valias address extensions (`foo-default`).

## 1.04

- new: Support for vpopmail valias addresses.
- new: Support for vpopmail "big dir" (hashed directory structure).
- change: `qmail-deliverabled` now uses GNU-style long options; old-style argument passing is deprecated.
- new: `qmail-deliverabled` can now stay in the foreground for use with DJB's daemontools.
- security: Made `qmail-deliverabled` safer and taint-mode compliant for
  Perl 5.10.

## 1.03

- new: `qmail-deliverabled` now takes a pidfile on the command line, and can stop itself using that.
- docs: `Qmail::Deliverable::Comparison`, a document to compare with other qmail deliverability checkers.
- fix: Now correctly loads `me` if `locals` does not exist.
- new: An example init.d script.

## 1.02

- new: Support for `bouncesaying`, although without using the configured error message. Plesk puts `|bouncesaying` in `.qmail-default`.

## 1.01

- change: qpsmtpd plugin `check_qmail_deliverable` installs as a binary, so that it has a manpage. If you execute it, you get installation instructions.
- new: `$Qmail::Deliverable::Client::SERVER` can be a callback now.
- change: Plugin now uses the callback option for cleaner code.
- fix: Plugin now allows hostnames instead of IP addresses only.
- fix: Exclusions now enabled for smtproutes.
- incompatible: `::Client::qmail_local` no longer returns `undef` on
  connection error, because `undef` already meant something else.
- new: `qmail-deliverabled` has basic statistics in `$0`.
- docs: Minor documentation updates.

## 1.00

- new: First CPAN release.
