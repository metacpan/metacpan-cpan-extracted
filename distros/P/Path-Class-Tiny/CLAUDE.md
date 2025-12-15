# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Path::Class::Tiny is a Path::Tiny wrapper that provides backward compatibility with the Path::Class API. It allows code written for Path::Class to work with Path::Tiny's performance benefits without requiring a full rewrite.

**Key Architecture:**
- Inherits from Path::Tiny (`our @ISA = qw< Path::Tiny >`)
- All Path::Class::Tiny objects are blessed Path::Tiny objects
- Exports `path`, `file`, `dir`, `cwd`, `tempfile`, and `tempdir` by default
- `dir()` export is handled specially via custom `import` (line 12-17)

## Development Commands

### Building and Testing
```bash
# Run all tests
prove -l t/

# Run specific test
prove -lv t/ctor.t

# Build distribution (requires Dist::Zilla)
dzil build

# Test distribution before release
dzil test
```

### Testing Notes
- Tests use Test::Most framework
- Custom test utilities in `t/lib/Test/PathClassTiny/Utils.pm`
- Symlink tests may be skipped on Windows (see t/symlinks.t)
- Tests are organized by feature: ctor.t, components.t, ef.t, tempfile.t, etc.
- Legacy Path::Class tests adapted in `t/path-class/`

## Code Architecture

### Method Categories

**Reblessings** (lines 64-69): Methods that call Path::Tiny equivalents and rebless results
- `parent`, `realpath`, `copy_to`, `children`, `tempfile`, `tempdir`

**Simple Aliases** (lines 72-75): Direct references to other methods
- `dir` → `parent`
- `dirname` → `parent`
- `subdir` → `child`
- `rmtree` → `Path::Tiny::remove_tree`

**Wrappers** (lines 83-103): Methods that add functionality to Path::Tiny methods
- `touch`: Handles datetime objects with `epoch` method
- `move_to`: MUTATOR - modifies object in place after move (unlike Path::Tiny's immutable `move`)

**Reimplementations** (lines 108-173):
- `dir_list`/`components`: Splits path into array of components with offset/length support
- `slurp`: Context-sensitive (array vs scalar), accepts hash args (not hashref)
- `spew`: Accepts Path::Class-style `iomode` parameter

**New Methods**:
- `ef` (line 187): Bash-style `-ef` file equivalence test using realpath comparison
- `mtime` (line 194): Returns Date::Easy::Datetime object (lazy loaded)

### Special Behavior

**Constructor Equivalence**: `path()`, `file()`, and `dir()` all create identical objects
- `file` is aliased to `path` (line 40)
- `_global_dir` handles `dir()` with no args returning cwd (line 41)

**Context Sensitivity**:
- `slurp` in list context returns array of lines; scalar context returns string
- `dir_list` returns count in scalar context, components list in list context

**Iterator Pattern**: `next()` uses a package-level `$_iter` variable (line 176-182)

## Dependencies

**Runtime**:
- Path::Tiny >= 0.104 (required)
- Date::Easy >= 0.06 (recommended, lazy loaded by `mtime`)
- Module::Runtime (for dynamic loading)

**Testing**:
- Test::Most >= 0.25
- Test::Differences >= 0.500
- Test::Exception (via Test::Most)

## Distribution

Uses Dist::Zilla with [@BAREFOOT] bundle for packaging. Current version: 0.06
