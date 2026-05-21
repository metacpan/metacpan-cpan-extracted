# PAX

**PAX** is a Perl-native adaptive compiler and standalone binary packager.

## Introduction

PAX exists to turn a Perl application plus its repeatable build inputs into one
standalone executable.

Without that layer, a normal Perl deployment usually depends on some mix of:

- the original source tree
- the host Perl installation
- host CPAN modules
- asset directories beside the app
- local bootstrap scripts
- container images that carry the whole working tree

PAX changes that deployment shape. The target artifact is one executable that
can carry compiled code units, packaged runtime payloads, embedded assets, and
native artifacts where PAX can prove a region is safe to specialize.

In bundled-runtime mode that includes the packaged helper programs and the
linked shared libraries and SONAME aliases required by bundled XS modules, so helper commands and
query/runtime helpers still work after the original source tree and CPAN
installation are gone.

The design goal is not "replace Perl with magic". The design goal is:

- keep Perl correctness
- keep fallback behavior explicit
- package applications into one binary
- move eligible hot paths toward native speed
- stay neutral across arbitrary Perl projects

The public command surface is intentionally small:

```bash
perl bin/pax help
perl bin/pax build
perl bin/pax run
```

Everything else in the repository is compiler/runtime implementation, test
coverage, or release tooling. Users should not call internal diagnostic
subcommands through `bin/pax`.

## What You Get

- one public entrypoint with two commands: `pax build` and `pax run`
- a repeatable build contract through `paxfile.yml`
- one standalone executable output
- embedded assets for web applications and static payloads
- packaged runtime payloads for source-tree-free execution
- packaged helper commands plus linked XS shared libraries and SONAME aliases for source-tree-free execution
- adaptive compilation with explicit fallback behavior
- static standalone analysis for plain Perl scripts, so long-running entrypoints do not execute themselves during `pax build`
- self-hosted build capability, including building `bin/pax` itself
- Docker-friendly multi-stage packaging

## Goals

- Build one executable from a Perl entrypoint.
- Read repeatable build inputs from `paxfile.yml`.
- Let CLI arguments override `paxfile.yml`.
- Embed assets and dependency payloads into the executable.
- Keep PAX neutral: no project-specific package names in compiler, loader, or runtime logic.
- Preserve correctness with fallback paths while compiling supported code units and native regions.

## Main Concepts

- `PAX::CLI`
  The small public facade behind `pax build` and `pax run`.

- `PAX::Paxfile`
  Loads repeatable build inputs from `paxfile.yml`.

- `PAX::StandaloneImage`
  Builds the standalone executable image, packages runtime payloads, and writes
  the launcher.

- `PAX::CodeUnitCompiler`
  Compiles supported Perl source shapes into PAX code unit records.

- `PAX::StandaloneRuntime`
  Provides the packaged runtime helpers used by the standalone executable after
  launch.

- `PAX::StandaloneDispatch`
  Runs packaged native regions and deopt fallback paths under the standalone
  model.

## Quick Start

Build from a local `paxfile.yml`:

```bash
perl bin/pax build
```

Long builds print a DD-style task rundown on `stderr` by default. On a real
terminal the board redraws live; in non-interactive runs it prints a static
rundown. The build path is broken into concrete checkpoints such as code-unit
compilation, application metadata inference, dependency analysis, native
artifact analysis, manifest writing, and launcher compilation. The code-unit
phase is further split into source discovery, entrypoint compilation,
application unit compilation, and dependency unit compilation so long builds
keep moving visibly. Application unit compilation includes the current file
name, so a slow module no longer looks like a frozen counter. To suppress it:

```bash
PAX_PROGRESS=0 perl bin/pax build --compact
```

Build an explicit entrypoint:

```bash
perl bin/pax build bin/my-app
```

Build to a specific output path:

```bash
perl bin/pax build -o ./build/my-app bin/my-app
perl bin/pax build --output ./build/my-app bin/my-app
```

Build and immediately run:

```bash
perl bin/pax run -- version
perl bin/pax run bin/my-app -- version
```

`pax run` uses the same build inputs as `pax build`, writes or refreshes the
standalone executable, and then executes that binary with arguments after `--`.

Interpreter-style execution is also available when the `pax` executable is used
as a shebang target for a Perl script:

```perl
#!/usr/local/bin/pax
use strict;
use warnings;
print "hello from pax shebang\n";
```

In that mode, `pax` treats the script path as a direct execution target instead
of requiring an explicit `build` or `run` command.

## CLI Contract

```text
usage:
  pax build ...
  pax run ...
```

Public commands:

- `build`: compile/package the source tree behind an entrypoint into one executable.
- `run`: build the executable, then run it.

Interpreter mode:

- if `pax` is invoked with a plain Perl script path instead of `build` or `run`,
  it executes that script directly as a shebang/interpreter target

Common options:

- `--paxfile`: read defaults from a manifest path; default is `paxfile.yml`.
- `--no-paxfile`: ignore manifest defaults.
- `-I`: prepend a Perl library directory for inline builds/runs; repeatable.
- `-M`: load and import a Perl module for inline builds/runs; repeatable.
- `-e`: synthesize the entrypoint from inline Perl code.
- `--name`: artifact name.
- `--lib`: application library path; repeatable.
- `--source-root`: source tree to scan/package; repeatable.
- `--cpanfile`: dependency policy/source file; repeatable.
- `--asset`: individual asset file to embed; repeatable.
- `--asset-dir`: asset directory to embed recursively; repeatable.
- `--output` / `-o`: executable output path.
- `--runtime-mode`: runtime strategy, typically `bundled_perl` or `host_perl`.
- `--compact`: compact JSON build output.

## `paxfile.yml`

With no positional entrypoint, `pax build` and `pax run` read `paxfile.yml`.
CLI flags override file values. When a positional entrypoint is supplied on the
CLI, PAX treats that target as an isolated build and does not silently inherit
`libs`, `source_roots`, `assets`, `asset_dirs`, `cpanfiles`, or app metadata
from the ambient default `paxfile.yml`. An explicit `--paxfile` still applies
its manifest defaults.

Example:

```yaml
name: example-app
entrypoint: bin/example-app
output: build/example-app
libs:
  - lib
source_roots:
  - lib
assets:
  - share/banner.txt
asset_dirs:
  - share/public
cpanfiles:
  - cpanfile
runtime_mode: bundled_perl
```

Output path precedence:

1. CLI `--output` / `-o`
2. `paxfile.yml` `output`
3. fallback `.pax/standalone/<name>/<name>`

## Manual

### Installation

For local development, install the distribution prerequisites and run from the
repository checkout:

```bash
cpanm --installdeps .
perl bin/pax help
```

For release packaging, Dist::Zilla must also be available:

```bash
cpanm Dist::Zilla
```

### First Build

The simplest workflow is a project-local `paxfile.yml`:

```yaml
name: example-app
entrypoint: bin/example-app
output: build/example-app
libs:
  - lib
cpanfiles:
  - cpanfile
runtime_mode: bundled_perl
```

Then build:

```bash
perl bin/pax build
```

Run the result:

```bash
./build/example-app
```

### Build Without `paxfile.yml`

PAX does not require a manifest when the CLI provides the required build shape:

```bash
perl bin/pax build -o ./build/example-app bin/example-app
```

That keeps one-off builds and self-hosting neutral even inside repositories
that ship their own `paxfile.yml`. Extra roots, assets, and CPAN policy files
must be declared explicitly on the CLI in that mode.

Inline entrypoints use the same public surface. `-I` adds Perl library roots,
`-M` loads and imports modules before execution, and `-e` supplies the
entrypoint code directly:

```bash
perl bin/pax build \
  -I lib \
  -MDateTime \
  -e 'print DateTime->now'
```

`pax run` accepts the same switches:

```bash
perl bin/pax run \
  -I lib \
  -MDateTime \
  -e 'print DateTime->now'
```

### Self Compile

PAX can build PAX itself:

```bash
perl bin/pax build -o /tmp/pax bin/pax
/tmp/pax help
```

When the original source paths still exist, that self-built standalone `pax`
binary can also rebuild from another standalone `pax` binary input.

That same self-built binary can then build another standalone application from
its own `paxfile.yml`. It can also rebuild from another standalone `pax`
binary when the original source checkout is no longer present, because the
build path carries an embedded source snapshot for the application units it
needs to rebuild.

For plain executable Perl scripts, the standalone build path now keeps source
analysis static. `pax build` does not need to execute a long-running script
just to inspect it, and recognized numeric loop subs can be rebound through
packaged native artifacts before the script's top-level work starts.

## Asset Embedding

Assets are copied into the executable payload and extracted into a private
runtime directory when the binary starts. Framework code can read them through
the embedded asset root prepared by the PAX runtime.

Example:

```bash
perl bin/pax build \
  --name webapp \
  --lib lib \
  --source-root lib \
  --asset-dir share \
  --cpanfile cpanfile \
  --runtime-mode bundled_perl \
  --output ./build/webapp \
  bin/webapp
```

This pattern supports web applications that include Perl modules, templates,
CSS, JavaScript, and other static files.

### Web Applications

PAX supports the single-binary packaging shape for framework applications that
combine:

- Perl modules
- PSGI/web framework code
- templates
- CSS
- JavaScript
- other static assets

The validated SOW-03 proof includes a Dancer2 + Plack/Starman + Template
Toolkit web application packaged as one executable and deployed through a
multi-stage Docker flow.

## Docker Deployment

Two-stage pattern for a generic project:

```dockerfile
FROM perl:5.42 AS builder
WORKDIR /workspace
COPY . /workspace
RUN cpanm --installdeps .
RUN perl bin/pax build --output /out/app

FROM debian:bookworm-slim
COPY --from=builder /out/app /usr/local/bin/app
CMD ["/usr/local/bin/app"]
```

The final stage receives only the built executable. It does not need the source
tree, asset tree, `cpanfile`, or web framework installation when the binary was
built in bundled runtime mode.

For an external application, the validated deployment pattern is:

1. build a standalone `pax` binary
2. copy that `pax` binary into the application build stage
3. compile the application into its own standalone binary
4. copy only that final application binary into the runtime stage

## Architecture

PAX packages an application through these stages:

1. Entrypoint and manifest loading.
2. Dependency and source-root discovery.
3. Code unit compilation into PCU or hybrid PCU records where supported.
4. Native artifact packaging for supported hot regions.
5. Asset and runtime payload embedding.
6. Standalone launcher generation.
7. Runtime extraction and dispatch with fallback safety.

Compilation is adaptive. If a module shape fails, the preferred fix is a reusable
compiler, loader, dependency discovery, or runtime improvement that works for
other projects with the same structure.

### Why The Two-Command Surface Works

PAX used to expose more internal diagnostic and build commands at the CLI
surface. SOW-03 intentionally collapsed that down to:

- `pax build`
- `pax run`

That keeps the operator workflow small while still allowing the internal Perl
modules to carry richer build, inspection, and validation logic behind the
public facade.

## Known Limits

- Perl’s dynamic loading and runtime mutation can require fallback code paths.
- Native speedups depend on whether PAX can prove a region is safe to compile.
- Performance is still shape-driven today. PAX is not hard-coded for one app or
  one module name, but it does accelerate some Perl code shapes better than
  others. Good current candidates include tight integer arithmetic loops,
  repeated numeric leaf routines, and structurally predictable hot paths. Weak
  current candidates include dynamic metaprogramming, runtime-heavy startup,
  IO-dominated scripts, irregular control flow, and broad general-purpose Perl
  that never lowers into a native region.
- Proven acceleration examples matter more than claims. The current strong
  cases are simple integer sum-loop kernels that PAX can lower into a native
  region safely. The following five snippets were measured on this repository's
  `0.030` toolchain on the local Linux/x86_64 build host:

  Invoice rollup:

  ```perl
  use strict;
  use warnings;
  use Time::HiRes qw(time);
  sub sum_to_n {
      my ($n) = @_;
      my $sum = 0;
      for (my $i = 1; $i <= $n; $i++) {
          $sum += $i;
      }
      return $sum;
  }
  sub invoice_rollup {
      my ($lines, $tax_basis) = @_;
      my $subtotal = sum_to_n($lines);
      my $tax = sum_to_n($tax_basis) & 0xFFFF;
      return ($subtotal ^ $tax) & 0x7fffffff;
  }
  my $start = time();
  my $out = 0;
  for my $batch (1..8) {
      $out ^= invoice_rollup(500_000_000, 50_000);
  }
  print "elapsed=", time() - $start, "\n";
  ```
  Measured runtime: stock Perl `120.35s`, standalone `1.26s`, about `95.4x`
  faster.

  Retry budget planning:

  ```perl
  use strict;
  use warnings;
  use Time::HiRes qw(time);
  sub sum_to_n {
      my ($n) = @_;
      my $sum = 0;
      for (my $i = 1; $i <= $n; $i++) {
          $sum += $i;
      }
      return $sum;
  }
  sub retry_budget {
      my ($attempts) = @_;
      my $budget = sum_to_n($attempts);
      return ($budget >> 3) & 0xFFFFFFFF;
  }
  my $start = time();
  my $acc = 0;
  for my $svc (1..8) {
      $acc += retry_budget(500_000_000);
  }
  print "elapsed=", time() - $start, "\n";
  ```
  Measured runtime: stock Perl `116.70s`, standalone `1.27s`, about `91.6x`
  faster.

  Shard weight planning:

  ```perl
  use strict;
  use warnings;
  use Time::HiRes qw(time);
  sub sum_to_n {
      my ($n) = @_;
      my $sum = 0;
      for (my $i = 1; $i <= $n; $i++) {
          $sum += $i;
      }
      return $sum;
  }
  sub shard_weight {
      my ($events) = @_;
      my $w = sum_to_n($events);
      return (($w << 1) ^ ($w >> 5)) & 0x7FFFFFFF;
  }
  my $start = time();
  my @weights;
  for my $shard (1..8) {
      push @weights, shard_weight(500_000_000);
  }
  my $acc = 0;
  $acc ^= $_ for @weights;
  print "elapsed=", time() - $start, "\n";
  ```
  Measured runtime: stock Perl `117.49s`, standalone `1.19s`, about `98.4x`
  faster.

  Backfill window checksum:

  ```perl
  use strict;
  use warnings;
  use Time::HiRes qw(time);
  sub sum_to_n {
      my ($n) = @_;
      my $sum = 0;
      for (my $i = 1; $i <= $n; $i++) {
          $sum += $i;
      }
      return $sum;
  }
  sub window_checksum {
      my ($n) = @_;
      my $v = sum_to_n($n);
      return (($v & 0xFFFF) ^ (($v >> 16) & 0xFFFF));
  }
  my $start = time();
  my $checksum = 0;
  for my $window (1..8) {
      $checksum = (($checksum << 5) ^ window_checksum(500_000_000)) & 0x7FFFFFFF;
  }
  print "elapsed=", time() - $start, "\n";
  ```
  Measured runtime: stock Perl `117.31s`, standalone `1.23s`, about `95.1x`
  faster.

  Cohort retention counting:

  ```perl
  use strict;
  use warnings;
  use Time::HiRes qw(time);
  sub sum_to_n {
      my ($n) = @_;
      my $sum = 0;
      for (my $i = 1; $i <= $n; $i++) {
          $sum += $i;
      }
      return $sum;
  }
  sub retention_counter {
      my ($population) = @_;
      my $total = sum_to_n($population);
      return ($total % 1_000_003);
  }
  my $start = time();
  my $acc = 1;
  for my $cohort (1..8) {
      $acc = ($acc * 33 + retention_counter(500_000_000)) % 1_000_003;
  }
  print "elapsed=", time() - $start, "\n";
  ```
  Measured runtime: stock Perl `117.10s`, standalone `1.16s`, about `100.7x`
  faster.

- By contrast, a normal CLI command such as `dashboard version` or `dashboard
  ps1` can still be bottlenecked by framework startup, helper dispatch,
  subprocess work, or other runtime behavior that is not yet a native hot
  region.
- This means PAX is not yet "compile once and every Perl workload becomes
  Rust-fast." The current model is broader than a one-off app patch, but still
  selective by supported semantic pattern.
- Bundled runtime artifacts are larger than source-only wrappers because they
  include enough Perl/runtime payload to run without the source tree.
- Bundled-perl binaries are validated for builder and runtime environments from
  the same libc family; arbitrary host-built cross-distro portability is not a
  release guarantee, so build inside the target container family for
  multi-stage Docker deployment.
- Docker validation requires a local Docker daemon and build access.

## FAQ

### Is PAX only for one specific project?

No. PAX uses DD and other applications as validation corpora, but core compiler
and runtime logic are expected to stay neutral and reusable.

### Does PAX guarantee Rust-like speed for all Perl code?

No. The target is to package the whole application correctly and accelerate hot
paths that PAX can prove are safe to specialize. Dynamic regions still use
fallback execution.

### Is PAX still case by case?

Not by project name or package name. It should stay neutral across arbitrary
Perl applications. But today it is still case by supported code shape. If PAX
recognizes a loop or leaf routine class and can lower it safely, it can do very
well. The five examples above are proven cases on this host: invoice rollup,
retry budget planning, shard weight planning, backfill window checksum, and
cohort retention counting. In those runs stock Perl took about `116s` to
`120s`, while the standalone binaries finished in about `1.16s` to `1.27s`.
If the workload stays in dynamic Perl semantics, it will package correctly but
may run close to stock Perl speed.

### What should I report as a performance issue?

Report any case where:

- a standalone binary is slower than stock Perl in a workload that looks
  structurally simple
- a hot loop or numeric kernel does not improve when you expected it to
- an application command regresses badly after packaging
- performance changes significantly across builder/runtime environments

For a useful report, include:

- the command or script you ran
- stock Perl timing
- PAX build timing
- standalone runtime timing
- whether the workload is CPU-heavy, IO-heavy, startup-heavy, or dynamic

### Does `pax run` require a separate app server?

No. Under SOW-03, `pax run` builds the standalone executable and then runs that
binary directly.

### Can PAX build web applications with embedded static assets?

Yes. The validated packaging path includes templates, CSS, JavaScript, and
framework code embedded into one standalone executable.

## Repository Map

- `bin/pax`: public command entrypoint.
- `lib/PAX/`: compiler, packager, loader, runtime, and validation modules.
- `t/`: unit, behavior, and acceptance tests.
- `examples/`: neutral examples used to validate packaging behavior.
- `paxfile.yml`: neutral example build manifest.
