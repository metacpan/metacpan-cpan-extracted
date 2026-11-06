# Releasing Perl CodeMap

**Author and maintainer:** Scott Muller <scott@21h.io>.

- Source: https://github.com/interrupt21h/perl-codemap
- Releases: https://github.com/interrupt21h/perl-codemap/releases
- Live sample: https://interrupt21h.github.io/perl-codemap/
- CPAN distribution: https://metacpan.org/dist/Perl-CodeMap
- CPAN module: https://metacpan.org/pod/Perl::CodeMap
- PAUSE author: MULLER, https://metacpan.org/author/MULLER

## Versioning

Use semantic versions. The canonical software version is
`$Perl::CodeMap::VERSION` in `lib/Perl/CodeMap.pm`.
The distribution is `Perl-CodeMap-X.Y.Z.tar.gz`, the annotated tag is
`vX.Y.Z`, and the command is `perl-codemap`.

Bump the module version and update `CHANGELOG.md` for every new release.
Update the README when behavior, installation, or compatibility changes.
Never replace an existing GitHub release asset or move a published version tag.

## Validate a candidate

```sh
cpanm PPI
perl Makefile.PL
make
make test
node --check lib/Perl/CodeMap/assets/app.js
node t/browser-smoke.js
make distcheck
make disttest
```

The release workflow repeats these checks on GitHub Actions, including the
PPI parser and documentation author tests, verifies the generated Unix
`perl-codemap(1)` man page, tests the dist tarball, verifies `META.json`
author metadata, and writes a SHA-256 checksum.

Every CLI option and public Perl method must have corresponding POD:
`bin/perl-codemap` for CLI users and `lib/Perl/CodeMap.pm` for MetaCPAN.
Update the POD and documentation tests before publishing a new CPAN archive.

## Publish on GitHub

After committing version and documentation changes to `main`, open
**Actions → Release → Run workflow**, selecting `main`. The workflow:

1. Reads and validates the module version.
2. Refuses to overwrite an already published release.
3. Installs PPI and runs all Perl, JavaScript, and MakeMaker tests.
4. Builds and inspects the tarball, including author metadata and required assets.
5. Creates an annotated `vX.Y.Z` tag on the tested commit, or validates an
   existing tag points at that same commit.
6. Creates a published GitHub release with tarball, SHA-256 checksum, notes,
   and links to the live demo and maintainer.

The v0.3.1 maintenance release has already been published. The v0.3.2
documentation release runs when the release workflow upgrade is committed
to `main`. Subsequent releases should be initiated deliberately with
**Run workflow** after the version and changelog are updated. Release notes
are generated from the matching `CHANGELOG.md` entry.
A tag that points elsewhere causes a hard failure rather than being moved.

If a failure occurs, review the workflow logs. A partially successful attempt
may leave a tag but no published release; rerunning is safe **only when the tag
still points at the same tested commit**.

## CPAN / PAUSE

**Initial CPAN publication completed:** `Perl-CodeMap-0.3.1.tar.gz` was
uploaded on 2026-11-05 by PAUSE account **MULLER (Scott Muller)**. The namespace
indexer reported **Status of this distro: OK** and successfully indexed
`Perl::CodeMap` (normalized version `0.003001`). The uploaded SHA-256
matched the GitHub v0.3.1 release:
`6a161d6cb14f880641c857237f7144b6589627d28077d19b5a4b44e35d1d4e5b`.

For each subsequent CPAN release:

1. Publish a new, immutable versioned tarball through GitHub Actions.
2. Download and verify its accompanying SHA-256 checksum.
3. Sign in to [PAUSE](https://pause.perl.org/) as `MULLER` and upload that
   **exact** tarball. Do not rebuild or alter it after GitHub publication.
4. Check both the PAUSE upload acknowledgment and the namespace indexer report.
   Confirm that `Perl::CodeMap` is indexed at the expected version.
5. Verify the distribution at [MetaCPAN](https://metacpan.org/dist/Perl-CodeMap)
   and check [CPAN Testers](https://matrix.cpantesters.org/?dist=Perl-CodeMap).

PAUSE author metadata identifies Scott Muller <scott@21h.io>.
Keep PAUSE credentials out of the Git repository and public CI logs.
If uploads are later automated, use a separately approved protected environment
and publish only the already-tested archive.

## Private source safety

The CLI can embed source contents in HTML and JSON. Do not include private
reports, credentials, or proprietary code in this public distribution or on
the public Pages demo.
