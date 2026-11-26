---
name: getty-perl-release-author-getty
description: "Use when a dist.ini contains [@Author::GETTY] — bundle options, POD conventions (=attr/=method/=opt), next-version semantics, the dzil release workflow."
user-invocable: false
allowed-tools: Read, Grep
model: sonnet
---

# `[@Author::GETTY]`

What the bundle adds on top of plain Dist::Zilla; generic `dist.ini` mechanics are skill
`perl-release-dist-ini`.

The bundle is for Getty's own CPAN work. A distribution that is not released to CPAN — a
proprietary application, a deploy artefact — lists its Dist::Zilla plugins explicitly
instead, because the bundle assumes a CPAN release. Non-CPAN dists that still use the
bundle set `no_cpan = 1`.

## Versioning Convention — CRITICAL

**The version in the repository is always the NEXT release version, not the current one.**

Before a release, the files already contain the upcoming version:
- `dist.ini` or module `$VERSION` = e.g. `1.005`
- `Changes` has `{{$NEXT}}` as the placeholder for unreleased changes
- The currently released version on CPAN is `1.004`

After `dzil release` runs:
1. `{{$NEXT}}` in Changes is replaced with `1.005` + release date
2. The version is bumped to `1.006` (or next AutoVersion value)
3. A Git tag `1.005` is created (default `tag_format = %v`, no `v` prefix)

- **Do NOT treat the version in dist.ini as the released version.** If the user asks
  "what version is released?", check CPAN or git tags — not the current `$VERSION`.
- **Do NOT bump the version manually before a release** — `dzil release` does it.
- **Each file under `lib/` and `bin/` needs its own `our $VERSION = '...';`**, set to
  the NEXT version — one higher than what is on CPAN (or higher). A file without one
  ships versionless and breaks consumers that pin against it.
- **One package per file.** RewriteVersion::Transitional and BumpVersionAfterRelease
  rewrite only the FIRST `our $VERSION` in a file, so a second package stays frozen at
  the version it was written with — while MetaProvides::Update reports the real release
  version. META and code then disagree silently, release after release. Split
  multi-package files before releasing.
- **Executables belong in `bin/`, never `script/`.** The bundle sets no `ExecDir`, so
  Dist::Zilla's default of `bin` applies: files under `script/` are not installed as
  executables and their `$VERSION` is never rewritten. Rename a `script/` directory to
  `bin/`.

## Release Workflow

**A human runs `dzil release`, never the agent.** It uploads to CPAN, tags and pushes —
irreversible, outward-facing, and the maintainer's call every time. Preparing a release
is in scope (tidy `Changes`, confirm the build and interop pass, stage the version);
running `dzil release` is not. Never run it on your own initiative, and never treat your
own offer to run it as a yes — only an explicit instruction from the maintainer to
release is authorization; absent that, you never assume it.

```bash
dzil release        # Builds, tests, uploads to CPAN, bumps version, commits, tags
```

Read the `{{$NEXT}}` section of `Changes` once as a whole first. It was written bullet by
bullet over weeks: merge entries circling one topic into one, cut over-detailed ones back
(skill `getty-git-commit-style`). `GitHub::CreateRelease` runs with
`notes_from = ChangeLog` and publishes the section verbatim as the release notes.

Fix it in its own commit *before* `dzil release`. `Changes` sits in the release commit's
`allow_dirty` list, so an uncommitted edit stops nothing — it is folded into the release
snapshot silently, under a message naming only the version.

## Required Metadata

```ini
name = Distribution-Name
author = Name <email>
license = Perl_5
copyright_holder = Copyright Owner
```

## Conventions

1. `copyright_year` IS used in dist.ini — GETTY has it in ALL distributions, do NOT
   remove it
2. Dependencies in `cpanfile`, not dist.ini
3. Changes file with `{{$NEXT}}` for unreleased
4. `LICENSE` is generated once with `dzil genlicense` and **committed** (`git add` is not
   optional) — the build aborts without it
5. For XS+Alien modules: use `xs_alien = Alien::Foo` (auto-configures
   MakeMaker::Awesome)
6. `Git::GatherDir` ships every *tracked* file, dotfiles included
   (`gather_include_dotfiles` defaults to 1): `.claude/`, `CLAUDE.md` and `.github/`
   ship with the dist, and `[GatherAgentContext]` adds a snapshot of the agent context
   under `misc/agent-context/` (build provenance, not installed). We keep them in. Out
   by default: `README.md` (see `include_readme`) and `.karr`.
7. POD: `# ABSTRACT:` under every `package`, `=attr`/`=method` inline directly after the
   code, no `=head1 SUPPORT/AUTHOR/COPYRIGHT` — skill `getty-perl-pod`

## Read on demand

- Any bundle option — feature toggles, `no_github`/`gitea`, authority, versioning
  (`task`, `manual_version`, `version_finder`), Git (`tag_format`, `release_branch`,
  `commit_files_after_release`), XS/Alien, Docker, `pp` binaries, IRC support, run
  hooks: [references/bundle-options.md](references/bundle-options.md)
- The build aborts with `no LICENSE in the distribution`, an older dist is picked up,
  `license`/`copyright_holder`/`copyright_year` changed, or a forge shows the dist as
  unlicensed: [references/license.md](references/license.md)
- POD shortcut commands (`=attr`, `=method`, `=opt`, …), `# ABSTRACT` and the sections
  Pod::Weaver generates: skill `getty-perl-pod`
