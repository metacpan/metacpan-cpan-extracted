# Module::ScanDeps::Static 1.9.1 Release Notes

**Release Date:** 2026-07-21
**Distribution:** Module-ScanDeps-Static

---

## Overview

Version 1.9.1 is a refactoring release that migrates
`Module::ScanDeps::Static` from using `Class::Accessor::Fast` to
inheriting from `CLI::Simple`. This modernises the internal
architecture, simplifies the command-line interface, and adds
structured logging support.

---

## What's New

### Refactored to Use `CLI::Simple`

The module has been refactored to use `CLI::Simple` as its parent
class, replacing the previous `Class::Accessor::Fast`-based
implementation. Key structural changes include:

- The module now inherits from `CLI::Simple` rather than
  `Class::Accessor::Fast`
- A new `init()` method handles startup initialisation (file list
  resolution, state setup)
- Scanning logic has been extracted into a dedicated `cmd_scan()` subcommand handler
- `main()` now delegates to `CLI::Simple`'s command dispatch framework
- `new()` has been reworked to translate hash-style option arguments
  into `@ARGV`-style arguments for `CLI::Simple`
- Log4perl integration added via `use_log4perl( level => 'info' )`

### New `--log-level` Option

A new `-l` / `--log-level` command-line option has been added to
control logging verbosity at runtime.

### Debug Logging in `is_core()`

The `is_core()` method now emits structured debug log messages showing
the module name, its first release version, its removal version (if
any), and the configured minimum core version. A second message
confirms whether the module was determined to be core or not.

### Updated Command Name in Documentation

Documentation examples have been updated to reflect the new compiled
binary name:

```
scandeps-static [options] Module
```

(Previously shown as `scandeps-static.pl`.)

### `with` Statement Support Documented

The POD documentation now explicitly notes that the scanner detects
Moo/`Role::Tiny` role composition via `with` statements, in addition
to `use`, `require`, `parent`, and `base`.

---

## Dependency Changes

| Dependency | Change |
|---|---|
| `CLI::Simple` | Bumped from `2.1.0` to `2.1.1` |
| `Class::Accessor::Fast` | **Removed** |

---

## Test Suite Refactoring

The test file `t/01-scandeps.t` has been updated to work with the new
`CLI::Simple`-based architecture:

- Tests no longer use `__DATA__` sections; test code is now held in a
  heredoc (`$CODE`)
- Each subtest now temporarily overrides `cmd_scan()` to inject a
  filehandle pointing at the test code string, then invokes
  `Module::ScanDeps::Static->main()` directly
- `local @ARGV` is used within each subtest to simulate command-line invocation

---

## Internal / Build Changes

- `bin/scandeps-static.in` added as the new source template for the
  compiled binary
- `bin/scandeps-static` added to `.gitignore`
- `project.mk` added
- `VERSION` bumped to `1.9.1`

---

## Upgrading

If you use `Module::ScanDeps::Static` programmatically via its OO
interface, note that the constructor behaviour has NOT
changed.
