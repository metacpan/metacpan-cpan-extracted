# Module::ScanDeps::Static 1.9.5 Release Notes

## Overview

This release focuses on correctness in dependency detection:
`parse_line` now properly ignores Perl comments in all contexts where
they previously caused false positives. A new runtime dependency on
`List::Util` 1.33 is declared explicitly, and build system bookkeeping
in the `.includes/` makefiles is tidied up.

## Bug Fixes: Comment Handling in `parse_line`

The central change in this release is a set of related fixes to
`parse_line` in `Module::ScanDeps::Static`:

**Full-line comments are now skipped before any dependency parsing.**
Previously, a line consisting entirely of a comment (e.g.,
`# use Foo::Bar`) could be matched by the `use`/`require` pattern and
produce a spurious dependency. Lines matching `/\A\s*\#/` are now
returned early, before any other processing.

**The `eval { ... }` body scanner strips commented lines before
scanning for `use`/`require`.** Comment lines inside an eval block
such as:

    eval {
        # require Commented::Out
        require Real::Module;
    };

would previously cause `Commented::Out` to be added to the dependency
list alongside `Real::Module`. Commented lines are now removed from
the captured eval body before it is scanned for module names.

**The `eval "..."` string-form comment exclusion regex was corrected.**
The quoted-string eval path had a faulty exclusion regex that could
still pass commented-out `use`/`require` expressions through for
matching.

Together these fixes mean that dependency signals appearing in comments
— whether as full-line comments, comments inside `eval {}` blocks, or
comments in string eval expressions — are no longer reported as
dependencies.

## New Tests

- `t/01-scandeps.t` adds regression tests verifying that commented
  `use` and `require` statements are not reported as dependencies.
- `t/03-suggests-recommends.t` adds regression tests covering commented
  dependency signals inside `eval` bodies, and verifies that such
  comments do not produce false entries in any of the three dependency
  tiers.

## New Dependency: `List::Util` 1.33

`List::Util` 1.33 is now declared as an explicit runtime dependency in
both `cpanfile` and `requires`. This version introduced `any`/`none`
and related functions that the module uses. Although `List::Util` is a
core module, its feature set has expanded over time, and the minimum
version constraint ensures compatibility with environments where an
older version may be present.

## Build System Changes

Several changes to `.includes/local.mk`, `.includes/test.mk`, and
`.includes/update.mk` refine the project's build workflow:

- **`test.mk`** now owns the `test-requires.cpanfile` recipe (moved
  from `local.mk`) and the test dependency generation rules. The `test`
  target prerequisite uses `SOURCE_FILES` instead of `GSOURCE_FILES`.
- **`local.mk`** is simplified by the removal of the recipe now in
  `test.mk`.
- **`update.mk`** defines `INCLUDES_DIR` and `BOOTSTRAPPER_DIST_DIR`
  explicitly.
- **`Makefile`** skips local dependency installation for tarball builds
  when `SKIP_TESTS` is set, removes `--log-level info` from the test
  dependency scanning invocation, and reconciles missing dependency
  files without requiring a full rescan.
- **`.gitignore`** adds `*.vars` to the ignore list.

---

