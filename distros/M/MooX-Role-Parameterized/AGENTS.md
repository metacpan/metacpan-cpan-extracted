# AGENTS.md

This file provides guidance to agentic coding tools when working with code in this repository.

## Project

`MooX::Role::Parameterized` is a CPAN distribution: a port of `MooseX::Role::Parameterized` to `Moo`. It lets a Moo role accept composition-time parameters that customize what gets injected into the consumer (attributes, methods, modifiers).

Minimum Perl is 5.12 (CI matrix runs Perl 5.12, 5.20, 5.30, and the latest stable). Patches must be submitted against the `devel` branch.

Security vulnerabilities should be reported privately as described in `SECURITY.md`, not through public issues.

## Common commands

Install Dist::Zilla and all dependencies:

```
cpanm -nq Dist::Zilla
dzil authordeps --missing | cpanm -nq
dzil listdeps --develop --missing | cpanm -nq
```

Build / test (Dist::Zilla):

```
dzil test          # t/ tests only
dzil test --all    # t/ plus author and release tests (xt/)
dzil build         # build the release tarball
dzil install       # install from the working copy
```

Run a single test file during development (`.proverc` adds `-I t/lib -I lib`):

```
prove -lv t/02_basic.t
```

Coverage (run by the linux CI workflow's build job):

```
dzil cover -report Coveralls
```

Author tests run under `dzil test --all`. Dist::Zilla generates the perlcritic, synopsis, compile, version, POD-syntax, and CPAN-changes tests automatically from `dist.ini` plugins. `xt/author/examples.t` is a hand-written test that runs every `examples/*.pl` script. Perltidy formatting is checked separately by the linux CI workflow — there is no Dist::Zilla plugin for perltidy. Lint configuration lives in `perlcriticrc` and `perltidyrc` at the repo root.

## Architecture

Four modules implement the system; understanding how they cooperate is the bulk of the codebase:

### `lib/MooX/Role/Parameterized.pm` — the DSL and registry
- Exports `parameter`, `role`, `apply`, `apply_roles_to_target`.
- All per-role state lives in the package-global `%INFO`, keyed by role package name. Each entry holds `is_role`, the `code_for` block passed to `role { ... }`, and either a list of `parameters_definition` or a lazily-built `parameter_definition_klass`.
- `role { ... }` may only be called once per package; calling twice croaks.
- `parameter NAME => (...)` stashes a `Moo::has`-style spec. On first apply, `_create_parameters_klass` synthesizes an anonymous Moo class (`<Role>::__MOOX_ROLE_PARAMETERIZED_PARAMS__`) via `MooX::BuildClass` and uses it to bless+validate every params hash thereafter (this is what enforces `required`, `isa`, `default`).
- `apply_roles_to_target` is the real entry point: it runs the role's code block once per params hashref (an arrayref means "apply N times with N parameter sets"), then finishes by calling `Moo::Role->apply_roles_to_package`.
- `build_apply_roles_to_package($orig)` returns the closure that `::With` installs as the caller's `with`. Order of dispatch: parameterized role → fall back to `$orig` (the consumer's pre-existing `with`, e.g. Moo's) → fall back to `Moo::Role->apply_roles_to_package` → croak. This is how Moo, Moo::Role, and Role::Tiny roles all keep working alongside parameterized ones.

### `lib/MooX/Role/Parameterized/Mop.pm` — proxy passed into the role block
- The `$mop` second argument to `role { my ($p, $mop) = @_; ... }`. Holds only `target` (consumer package) and `role` (defining package).
- `has`, `with`, `before`, `around`, `after` `goto` the corresponding sub installed in the **target** package — this is the whole point: it sidesteps the trap where calling `has` directly inside the role body would install on the role instead of the consumer.
- `requires` `goto`s into the **role** package, not the target.
- `method($name, $code)` installs by glob assignment (`*{ "${target}::${name}" } = $code`); when `$MooX::Role::Parameterized::VERBOSE` is true it carps before overriding an existing method.

### `lib/MooX/Role/Parameterized/With.pm` — `with` override
- `use MooX::Role::Parameterized::With;` overrides the caller's `with` at import time, capturing the previous `with` (if any) as the fallback `$orig` described above. Consumers can then write `with RoleName => { params }` or `with RoleName => [ {...}, {...} ]`, mixed with plain Moo/Role::Tiny role names in the same call.

### `$VERBOSE` flag
`$MooX::Role::Parameterized::VERBOSE` (default false) controls non-fatal warnings (method override, `apply` deprecation carp, redefining `with`). Tests rely on the silent default — flipping it on may add unexpected output.

### `lib/MooX/Role/Parameterized/Cookbook.pm` — documentation only
POD-only module: five recipes with worked examples, no functional code (just the `package`/`use`/`1;` boilerplate before `__END__`). Each recipe is backed by a script in `examples/`, and `xt/author/examples.t` runs them all.

## Releasing

Releases are automated by `.github/workflows/release.yml`, triggered by pushing a `v*` tag. The workflow checks that the tag matches the `version =` line in `dist.ini`, runs `dzil test --all`, builds with `dzil build`, uploads the tarball to CPAN, and publishes a GitHub release.

To cut a release: bump the single `version =` line in `dist.ini` (the one source of truth — the `[OurPkgVersion]` plugin injects it into every module at build time), add a `Changelog` entry, commit, then `git tag vX.YYY && git push origin vX.YYY`.

The `PAUSE_USER` and `PAUSE_PASSWORD` repository secrets must be configured for the CPAN upload step.

## CI

`linux.yml` is two-stage: a `build` job runs on the latest Perl and does three things: (1) builds the release tarball with `dzil build --in build-dir` and uploads it as an artifact, (2) runs the perltidy formatting check against the repo source, and (3) runs coverage (`dzil cover -report Coveralls`). A `test` job then runs a matrix over Perl 5.12, 5.20, 5.30, and latest; it downloads the built artifact and tests the unpacked tarball via plain EUMM (`perl Makefile.PL && make && make test`) — not `dzil test`. `macos.yml` and `windows.yml` run `dzil test --all` on Perl 5.40.
