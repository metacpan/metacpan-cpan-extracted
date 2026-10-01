# OrePAN2-S3 2.1.2 Release Notes

## Summary

This release focuses on build system improvements and dependency
cleanup. The core module functionality is unchanged; all changes are
to the project infrastructure managed by `CPAN::Maker::Bootstrapper`.

## Dependency Cleanup

Redundant sub-module dependencies have been removed from `requires`
and `cpanfile`. The following packages were already pulled in
transitively by top-level dependencies and no longer need to be
listed explicitly:

- `CLI::Simple::Constants` and `CLI::Simple::Utils` (included by
  `CLI::Simple`)
- `DarkPAN::Utils::Docs` (included by `DarkPAN::Utils`)
- `Role::Tiny::With` (included by `Role::Tiny`)

## Build System Changes

Significant updates to the build infrastructure were made via
`CPAN::Maker::Bootstrapper`. Notable improvements include:

- **Dependency installation** (`local.mk`): The `local` target now
  tracks installation state via a `local/.installed` sentinel file,
  installs runtime and test dependencies separately, and correctly
  handles the case where no CPAN installer is configured.
- **Syntax and lint checking** (`perl.mk`): Check steps now emit
  clearer progress messages (`Checking SYNTAX...`, `Checking POD...`,
  `Checking TIDINESS...`, `Checking PERLCRITIC...`).
- **Dependency scanning**: The `PERL5LIB` is now set correctly during
  scanning so locally installed modules are visible. The
  `test-requires` pipeline has been split into discrete steps
  (`test-requires.scan` → `test-requires.raw` → `test-requires`)
  with improved filtering logic.
- **DarkPAN support**: New `DARKPAN_REQUIRES` / `DARKPAN_URL`
  variables and associated targets for projects that pull dependencies
  from a private DarkPAN mirror.
- **Extra-files validation**: The `extra-files` target now verifies
  that all listed files are tracked in git before packaging.
- **Test discovery**: `find-files` now picks up `.pm` and `.pl`
  helper files under `t/` in addition to `.t` files.
- A new `publish.mk` include has been added.
- `extra-files.mk` is now included unconditionally (previously used
  `-include`).
- Various generated files (`provides`, `test-requires.scan`,
  `cpanfile.*`) are now properly listed in `CLEANFILES`.

## Notes on ChangeLog Inconsistencies

- The `recommends` and `test-requires` files are listed as modified
  in the ChangeLog but are not present in the diff. The nature of
  those changes is not visible in this release.
- `.prompts/release-notes.prompt` is listed in the ChangeLog but
  does not appear in the diff and is not in the changed-files
  listing — its content and purpose are unclear.
- `Makefile` is attributed to `CPAN::Maker::Bootstrapper` in the
  ChangeLog, but the Makefile in this repo is the project's own
  (not the bootstrapper's `Makefile.txt`). The ChangeLog entry may
  be imprecise.

---

