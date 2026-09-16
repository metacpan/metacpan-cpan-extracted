# OrePAN2-S3 Release Notes

## Version 2.1.1

**Released:** Mon Sep 14 2026  
**Author:** Rob Lauer <rclauer@gmail.com>

---

### New Features

#### `download-version-index` Command
A new CLI command has been added to download the packages version
index to the current working directory. This index is typically a
SQLite database used with the `DarkPAN::Resolver::SQLite`
resolver. The command requires a `packages_version_index` entry to be
defined in your configuration file.

```
orepan2-s3 download-version-index
```

#### `has_packages_version_index` Method
A new internal method (`has_packages_version_index`) has been added to
check whether a `packages_version_index` is defined in the active
configuration profile.

#### Packages Version Index Integration for `delete`
When deleting a distribution, if a `packages_version_index` is
configured, the corresponding records are now automatically removed
from that index via the new `_delete_from_packages_version_index`
helper method.

#### CloudFront Invalidation for Packages Version Index
The `_invalidate_index` method now includes the configured
`packages_version_index` path in CloudFront invalidation requests when
one is defined.

#### `--force` Short Option
The `--force` option now accepts `-f` as a shorthand alias.

---

### Changes

#### Renamed Constant: `$PACKAGE_INDEX` → `$PACKAGES_DETAILS_INDEX`
The internal constant previously named `$PACKAGE_INDEX` has been
renamed to `$PACKAGES_DETAILS_INDEX` for clarity and consistency
throughout `OrePAN2::S3`. All references across the codebase have been
updated accordingly.

#### Improved Error Handling in `fetch_config`
- `die` calls replaced with `croak` for more idiomatic Perl error
  propagation.
- Config profile loading now logs at `debug` level instead of `info`
  to reduce noise in standard operation.

#### Quieter Logging in `fetch_template`
Template loading messages have been downgraded from `info` to `debug`
level logging.

#### `cmd_delete` — Improved Match Reporting
When multiple objects match a delete pattern, the full list of
matching keys is no longer printed to stdout. Instead, a concise
warning is logged showing only the count of matches, e.g.:

```
Multiple objects match "Foo-Bar" (3) - use --delete-all to remove all objects
```

---

### Dependency Updates

| Dependency | Previous Version | New Version |
|---|---|---|
| `OrePAN2::Lite` | 1.0.1 | 2.0.0 |
| `DarkPAN::Indexer` | *(not required)* | 1.0.2 *(new)* |

---

### Build System Updates

- `bootstrap.mk` added to managed includes via `CPAN::Maker::Bootstrapper`.
- `update.mk` and `Makefile` updated by `CPAN::Maker::Bootstrapper`.
- `PACKAGE_VERSION` and `MODULE_NAME` are now exported from the `Makefile`.
- `PERL5LIB` is now prepended with `$(pwd)/local/lib/perl5` when invoking `cpan-maker`.
- `test-requires` scanning now filters out internally provided
  packages using a generated `provides` file, preventing false
  positive test dependencies.
- `extra-files` and `extra-files.mk` generation refactored to use `cmb
  extra-files`; `extra-files.mk` is skipped during bootstrap builds
  (`BOOTSTRAP_BUILD`).
- `$(MODULE_PATH).in` generation: `gen-vars-file` is now called before
  the template resolution step.
- `builder`: fixed a bug where `CPAN::Maker::Bootstrapper` was
  overwriting rather than appending to `build-requires`.

---

### Documentation Updates

- POD for the `delete` command updated to note that records are
  removed from a packages version index if one is configured.
- `download-version-index` command documented in the command reference.
- `dump-template` command entry repositioned in the command listing
  for better logical grouping.
