# Publishing Perl CodeMap

**Maintainer:** Scott Muller <scott@21h.io>.

- Public repository: https://github.com/interrupt21h/perl-codemap/
- Live sample: https://interrupt21h.github.io/perl-codemap/
- GitHub releases: https://github.com/interrupt21h/perl-codemap/releases
- CPAN distribution: https://metacpan.org/dist/Perl-CodeMap
- CPAN module documentation: https://metacpan.org/pod/Perl::CodeMap
- PAUSE author: MULLER (Scott Muller), https://metacpan.org/author/MULLER

The repository is public. The v0.3.1 distribution was uploaded to CPAN and
successfully indexed by PAUSE as `Perl::CodeMap` on 2026-11-05.
PAUSE accepted `Perl-CodeMap-0.3.1.tar.gz` from author `MULLER` and
reported "Status of this distro: OK" and "The package was indexed successfully."

Users can install it with `cpanm Perl::CodeMap`; `PPI` is optional but
recommended. Since v0.3.2, the CPAN distribution also includes detailed POD
for the [Perl module API](https://metacpan.org/pod/Perl::CodeMap) and the
executable (`perl-codemap --help`, `perl-codemap --man`, and
`perldoc perl-codemap`). For future releases, follow
[RELEASING.md](RELEASING.md) rather than reinitializing the repository.

## Before publishing

Confirm changes and release artifacts contain only code you are authorized to
share. The tracked `examples/sample/`, `examples/demo.html`, and
`docs/assets/example-map.png` are synthetic. Generated reports may embed
complete source files and must not be published if they contain proprietary
code, secrets, or personal information.

```sh
git status --short
git diff --stat
git grep -n -E 'PASSWORD|TOKEN|PRIVATE_KEY' -- . ':!docs/PUBLISHING.md'
```

The quick text search is illustrative; use a dedicated secret-scanning tool
for a real security review.

## Repository metadata

**Name:** `interrupt21h/perl-codemap`.

**Maintainer:** Scott Muller <scott@21h.io>.

**Description:** Interactive code maps for Perl projects. Visualize package
dependencies, explore modules and subroutines, and browse syntax-highlighted
source code.

**Topics:** `perl`, `static-analysis`, `dependency-graph`,
`code-visualization`, `ppi`, `software-architecture`, `code-browser`.

**License:** MIT; original Go CodeMap and PrismJS retain their respective
third-party notices in `NOTICE.md` and the Prism license.

## Releasing

The GitHub **Release** workflow uses `$Perl::CodeMap::VERSION` and validates
the matching version tag; it produces the distribution tarball and a SHA-256
checksum. Do not overwrite an existing version or force-move a published tag.
The workflow can be started through **Actions → Release → Run workflow** after
the version and changelog are committed to `main`.

CPAN publication remains a separate manual step. Upload the **same tested
GitHub release tarball** to PAUSE using the `MULLER` account, then confirm
the acknowledgment and namespace-indexer reports. Do not create a second
archive under the same version or add PAUSE credentials to public workflows.
See [RELEASING.md](RELEASING.md).

## GitHub Pages

The existing CI workflow deploys a synthetic demo from `examples/sample/`
to [https://interrupt21h.github.io/perl-codemap/](https://interrupt21h.github.io/perl-codemap/)
on successful pushes to `main`. It publishes only `_site` and never scans
employer or customer source trees. See [GITHUB_PAGES.md](GITHUB_PAGES.md).
