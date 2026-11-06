# Development and release process

## Local workflow

```sh
perl Makefile.PL
make
make test
prove -Ilib -v t
node --check lib/Perl/CodeMap/assets/app.js
node t/browser-smoke.js
prove -Ilib t/60-pod.t           # built-in POD syntax and CLI help tests
# Optional author checks:
cpanm Test::Pod Test::Pod::Coverage
prove -Ilib xt/author/pod.t
perl bin/perl-codemap --root examples/sample --parser lite \
  --output example.html --json example.json
```

Node.js is only needed for frontend smoke checks. `PPI` enables the optional
PPI integration tests; otherwise those tests are skipped and `lite` tests run.

Run the Chromium end-to-end check after installing Playwright for Python:

```sh
python -m pip install playwright
python -m playwright install chromium
python script/browser-smoke.py
```

This test generates a report from the **synthetic fixture only** and verifies
actual graph interaction, search, source highlighting and line navigation.

## Install smoke test

```sh
perl Makefile.PL
make
PERL5LIB=blib/lib perl blib/script/perl-codemap \
  --root examples/sample --parser lite --output example.html
```

The assets reside under `lib/Perl/CodeMap/assets` and are copied by
`Makefile.PL` to the Perl library path, so installed CLI scripts can find them.

## Documentation quality

Both the command and library contain their own POD manual. When changing an
option or public method, update the relevant POD and accompanying tests in
the same change. The command's `--help` and `--man` now render from POD through
`Pod::Usage`; do not introduce a separate help text string.

The standard test suite validates POD syntax using core `Pod::Simple::Checker`,
checks every supported CLI option and public API method is documented, and
runs both CLI documentation modes. Optional author checks under `xt/author/`
use `Test::Pod` and `Test::Pod::Coverage` and run as part of GitHub's release
workflow. The distribution automatically builds the executable's Unix man
page through MakeMaker's `EXE_FILES` handling.

## Review requirements

Changes to the parser should add a synthetic Perl fixture and a regression
test. Changes to the visualizer should preserve offline operation, escaping of
JSON, no dynamic remote dependencies, and bounded rendering for large trees.
Do not include real user repository exports in tests or Git commits. Verify
`git status --short` and consider `git grep` for internal domains or paths
before public publication.

## Versioning and releases

We use semantic versions. Update `$Perl::CodeMap::VERSION`, `CHANGELOG.md`,
and README/CLI docs when shipping user-visible changes. Validate on a clean
checkout before running the **Release** GitHub Actions workflow from `main`:

```sh
git status --short
prove -Ilib t
node t/browser-smoke.js
perl Makefile.PL
make test
make distcheck
make disttest
```

The release workflow installs PPI, builds the CPAN-compatible tarball, verifies
the generated author metadata, tags the tested commit, and uploads a tarball
plus SHA-256 checksum to GitHub Releases. Since v0.3.1, the distribution is
also published on [CPAN](https://metacpan.org/dist/Perl-CodeMap) by PAUSE author
[MULLER](https://metacpan.org/author/MULLER). Each future CPAN upload is a
separate, manual publication of the identical tested GitHub release tarball.
See [RELEASING.md](RELEASING.md) for the workflow, immutability, and PAUSE steps.
Generated reports from real source trees must **not** be part of public releases.

## Maintainer

Scott Muller <scott@21h.io>.

## Licensing and provenance

The implementation is MIT licensed. The original Go CodeMap repository was
verified as MIT licensed, and it is credited in `NOTICE.md`. Bundled PrismJS is
also MIT licensed, with its license shipped alongside the JavaScript assets.
