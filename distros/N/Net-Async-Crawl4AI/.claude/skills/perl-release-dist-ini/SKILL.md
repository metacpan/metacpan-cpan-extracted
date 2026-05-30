---
name: perl-release-dist-ini
description: "Load when reading, editing, or debugging any dist.ini file — any Perl distribution, any plugin bundle (Author::GETTY, Author::ETHER, Author::KENTNL, etc.), checking version config, plugins, metadata, prereqs"
user-invocable: false
allowed-tools: Read, Grep
model: sonnet
---

Generic Dist::Zilla dist.ini reference — applies to any distribution regardless of author bundle.
For `[@Author::GETTY]`-specific conventions (next-version semantics, POD commands, bundle options), the perl-release-author-getty skill applies additionally.

When analyzing dist.ini:

## Section Detection

```ini
[@Author::PLUGIN_BUNDLE]   # Plugin bundle
[Some::Plugin]             # Individual plugin
```

## Common dist.ini Sections

| Section | Purpose |
|---------|---------|
| `name` | Distribution name |
| `author` | CPAN author |
| `license` | License type |
| `copyright_holder` | Copyright owner |
| `copyright_year` | Override year |
| `[@Bundle]` | Plugin bundle |
| `[Plugin]` | Individual plugin |

## Plugin Loading Order

1. `[GatherDir]` - Collects files
2. `[PruneCruft]` - Removes unwanted files
3. `[Prereqs]` / `cpanfile` - Dependencies
4. `[Version plugins]` - PkgVersion, AutoVersion, etc.
5. `[Meta plugins]` - MetaJSON, MetaYAML
6. `[Test plugins]` - Tests
7. `[Release plugins]` - UploadToCPAN, etc.
8. `[VCS plugins]` - Git::Commit, Git::Tag, etc.

## Key Questions

1. Which plugin bundle is used?
2. Are there custom plugins configured?
3. Are prereqs in dist.ini or cpanfile?
4. What release mechanism is configured?
5. What is the version in dist.ini — and does the bundle auto-bump it post-release or is it manual?
