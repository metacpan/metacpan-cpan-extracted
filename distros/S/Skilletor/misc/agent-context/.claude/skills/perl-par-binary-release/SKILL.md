---
name: perl-par-binary-release
description: "Use when a Perl dist should ship standalone PAR::Packer (pp) binaries in its GitHub release: release-binaries workflow, build/verify/smoke scripts, runtime-lib check."
---

# Shipping a PAR::Packer binary with a Perl release

A dist's GitHub release carries one `pp` binary per platform (Linux x86_64, Linux
aarch64, macOS arm64), so users run the CLI without Perl. The recipe is a workflow
`release-binaries.yml` plus `scripts/`: `build-binary.sh`, `loaded-modules.pl`,
`verify-binary.sh`, `check-binary-libs.sh` and `smoke-binary.sh`. Start from the closest
sibling dist's files and keep the shape.

Templates: [references/workflow.md](references/workflow.md) (the YAML and the README
text for users) and [references/scripts.md](references/scripts.md) (the scripts and the
smoke keeper test). Per-script rules and reasons: [references/pipeline.md](references/pipeline.md).
This page holds the decisions.

**Verification is the centre.** `pp` exits 0 on a binary that dies at runtime: a module
loaded by name is not found by the scanner, a share tree is not packed, an XS module
links a lib the target lacks. Each of those passes `--help`. The build is done when
`verify-binary.sh`, `check-binary-libs.sh` and the smoke jobs pass, not when `pp` returns.

## Workflow

Three jobs, `build`, then `smoke`, then `release`. Triggers: `release: types: [published]`
and `workflow_dispatch` with an optional `tag` input.

- **Least privilege.** The workflow default is `permissions: contents: read`; only the
  `release` job sets `contents: write`. Every `actions/checkout` sets
  `persist-credentials: false`, so no job leaves a token in the checkout.
- **The tag decides.** With a tag (from the release or the input) every job, build and
  smoke alike, checks out that tag (`ref: ${{ env.TAG }}`), so fixtures and `$VERSION`
  come from the release. Without a tag the run is a probe: it builds and checks the
  chosen ref and keeps the results as Actions artifacts only, leaving every release
  untouched. Only the `release` job (`if` tag set) touches the release. The version step
  reads `$VERSION` from `lib/` (dzil-built dists may carry no literal `our $VERSION` in
  the repo), stops when it cannot (`[ -n "$want" ] || fail`), and stops when the tag does
  not match it.
- **What a rebuild picks up.** A `workflow_dispatch` with a tag runs the workflow file
  from the dispatched ref and the scripts and code from the tag. A fix in `scripts/` or
  `lib/` ships with the next release; a fix in the workflow file applies to a rebuild of
  an existing tag.
- Hygiene: a `concurrency` group per tag with `cancel-in-progress: false` (two runs for
  one tag queue, not race on `--clobber`); `timeout-minutes` on every job (build
  30, smoke 30, release 15; the timeouts leave room for a slow package mirror).
- **Tag values reach shell only through `env`.** Set
  `TAG: ${{ github.event.release.tag_name || inputs.tag }}` at job level and write
  `"$TAG"` in `run:` bodies, so a crafted tag name cannot inject shell. Step outputs
  travel the same way, as `env:` entries.
- **The build image sets the glibc floor.** Linux builds run in a pinned old-glibc image
  (`perl:5.40-bullseye`, glibc 2.31): the packed XS modules need the build image's glibc
  or newer, and the image decides which optional libs they link (a `-dev` package in a
  newer image can make `Unicode::LineBreak` link `libthai`). The lib check compares the
  floor against a constant (`GLIBC_MAX`), and the README names the same version.
- **The build uses what the image carries.** `perl:5.40-bullseye` holds git, unzip, gcc,
  g++, make, binutils and cpanm, so the Linux build has no `apt-get` step and keeps
  working after bullseye moves to archive.debian.org. Check a changed image with
  `docker run --rm <image> sh -c 'command -v git unzip gcc g++ make objdump cpanm'`
  before adding a package step.
- macOS builds on `macos-14` (arm64) with Perl from `shogo82148/actions-setup-perl@v1`.
  The scripts stay bash-3.2 compatible (`while read` loops, no `mapfile`) and `tar` is
  bsdtar there.
- A dist with an Alien dependency sets `ALIEN_INSTALL_TYPE=share` inline on the one
  `cpanm` call that builds that Alien. Build-tool Aliens (`Alien::cmake3`) stay `system`
  and are installed first.

## build-binary.sh and loaded-modules.pl

`set -euo pipefail`, run from the checkout root, output path from `<NAME>_BIN_OUT`.
Rules and reasons: [pipeline.md](references/pipeline.md#build-binarysh-and-loaded-modulespl).

- `PAR_VERBATIM=1 pp -o "$OUT" -I lib "${mods[@]}" -M 'Dist::**' bin/<name>`:
  `PAR_VERBATIM=1` stops pp's POD-stripping filter from corrupting modules; `-I lib`
  resolves the dist from the checkout.
- **One computed module set for build and verify**: `loaded-modules.pl` runs every
  command path and prints the modules that loaded from their own file; build packs each
  with `-M`, verify requires each in the archive. Backends the scanner cannot see are
  listed there explicitly.
- Guard optional modules before `-M`; pack share trees with
  `-a "<src>;lib/auto/share/dist/<Dist-Name>"` (pp exits 0 for a missing `-a` path).
- **`-X` drops one file.** `pp -X Name` removes exactly `Name.pm`, has no wildcard, and
  the scanner still follows `require Name` into its dependencies. To leave out an
  optional module only some runners have (an output format such as `YAML` on macOS), add
  one `-X` per module of its family found in `@INC` on the build host, and let verify
  reject any file of the family in the archive. Every binary then has the same features
  everywhere. The walk spans the namespace, siblings included; a module the CLI needs
  from it fails verify, and the walk narrows then. Template: [scripts.md](references/scripts.md).
- Guards at the top refuse a build with a missing precondition; each `-M`/`-a`/`-X` line
  carries a comment naming the failure it prevents.

## verify-binary.sh

Runs where the binary was built, as a user's machine would: fresh `PAR_GLOBAL_TEMP`
(first start, then a second start on the same cache), a wiped environment (`env -i`),
no network. Output equals `perl -Ilib bin/<name>` on success and error paths; the
computed module set sits inside the unzipped archive; the family from `-X` is absent from
it. The check reads the archive, never the host's `@INC`. Every run is bounded by
`timeout`. See [pipeline.md](references/pipeline.md#verify-binarysh).

## check-binary-libs.sh

A packed binary is portable when it needs only the libs the README names: `ldd` (macOS
`otool -L`) on the loader and every shared object inside, compared with `RUNTIME_LIBS`
plus `BASE_LIBS`. The `pp` loader links libperl, which needs `libcrypt.so.1` before PAR
extracts anything, so such libs come from the system: list them in `RUNTIME_LIBS`
(`--list`), name them in the README with the package that carries them, and let CI grep
the README. A glibc check compares the highest `GLIBC_x.y` with `GLIBC_MAX`. Run it as a
plain command, so its exit code decides the step. See
[pipeline.md](references/pipeline.md#check-binary-libssh).

## smoke-binary.sh and the smoke job

Smoke what users download, on machines that never built it: `almalinux:9`,
`ubuntu:22.04`, `debian:bullseye-slim` (x86_64), `almalinux:9` (aarch64), `macos-14`,
`macos-15`; no setup-perl, no build container, `env -i`, and the cell asserts the build
Perl is absent.

- Linux cells start the clean image with `docker run` (checkout and artifacts mounted):
  a clean image has no git, and `actions/checkout` without git fetches the REST archive,
  which honours `export-ignore` and drops scripts and fixtures.
- The script unpacks the tarball and checks the binary inside it (executable,
  `cmp`-identical to the bare asset, `LICENSE`, `README`).
- **Smoke every subcommand.** Each runs on a fixture and its output is compared byte for
  byte with a checked-in expectation; a `t/` test keeps that expectation equal to what
  the Perl code writes, so it cannot rot. One error path as well. See
  [pipeline.md](references/pipeline.md#smoke-binarysh-and-the-smoke-job).

## Packaging, checksums, users

- Per platform: the raw binary and `<base>.tar.gz` (`<base>/<name>`, `LICENSE`, README),
  `<base>` = `<name>-<version>-<os>-<arch>`; the `release` job writes one
  `<name>-<version>-checksums.txt` and runs `gh release upload "$TAG" ... --clobber` on
  the plain runner with `GH_TOKEN` in its `env:`.
- `release: published` fires for a release made with a personal token; a release created
  by a workflow's `GITHUB_TOKEN` starts no workflow. Create the release the way the
  dist's release tool does (`dzil release`), or dispatch the workflow with the tag.
- **The dist README tells users** (text in `references/workflow.md`): the bare asset has
  no executable bit, so `mkdir -p ~/.local/bin` first (a fresh account has none; BSD
  `install` on macOS has no `-D`), then `install -m 755`; the checksum check works
  without `--ignore-missing`; the macOS binary is unsigned (`xattr -d
  com.apple.quarantine`). Details: [pipeline.md](references/pipeline.md#packaging-checksums-users).

## Done when

- `verify-binary.sh` and `check-binary-libs.sh` pass on every build platform, from a
  fresh cache, and every smoke cell passes on the tarball.
- Every runtime lib `--list` prints appears in `README.md`.
- A probe run (dispatch without a tag) ends green with Actions artifacts and no release
  change; a tag dispatch ends with assets and one checksums file on the release.
