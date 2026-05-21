package PAX;

use strict;
use warnings;

our $VERSION = '0.031';

1;

__END__

=head1 NAME

PAX - Perl Adaptive eXecution compiler and standalone binary packager

=head1 VERSION

Current release version is kept in C<our $VERSION> in this module and mirrored
to every C<lib/PAX/*.pm> module before release.

=head1 SYNOPSIS

  perl bin/pax help
  perl bin/pax build
  perl bin/pax build -o ./build/my-app bin/my-app
  perl bin/pax run -- version
  perl bin/pax run bin/my-app -- version

=head1 DESCRIPTION

PAX turns a Perl entrypoint plus its repeatable build inputs into a standalone
executable. The executable can include compiled code units, native artifacts
where supported, asset payloads, dependency payloads, and a runtime launcher.

The project is deliberately neutral. Core compiler, packaging, loader, runtime,
and dispatch code must not embed assumptions about one application, company, or
module namespace.

=head1 INTRODUCTION

PAX exists to change the deployment shape of a Perl application.

Without PAX, a Perl application commonly depends on some mix of the original
source tree, a host Perl installation, host CPAN modules, asset directories
next to the app, and local bootstrap scripts or container images that carry the
whole working tree.

PAX aims to turn that into one executable that can carry compiled code units,
runtime payloads, embedded assets, and native artifacts where a region can be
proven safe to specialize.

In bundled-runtime mode that includes the packaged helper programs and the
linked shared libraries and SONAME aliases required by bundled XS modules, so helper commands and
query/runtime helpers still work after the original source tree and CPAN
installation are gone.

The goal is not to pretend every Perl feature can become a native binary with
no trade-offs. The real goal is:

=over 4

=item *

keep Perl correctness

=item *

keep fallback execution explicit

=item *

package applications into one binary

=item *

move eligible hot paths toward native speed

=item *

stay neutral across arbitrary Perl projects

=back

=head1 WHAT YOU GET

=over 4

=item *

one public command surface with C<pax build> and C<pax run>

=item *

a repeatable build contract through C<paxfile.yml>

=item *

one standalone executable output

=item *

embedded asset packaging for web applications and static payloads

=item *

runtime payload packaging for source-tree-free execution

=item *

packaged helper commands plus linked XS shared libraries and SONAME aliases for source-tree-free
execution

=item *

static standalone analysis for plain Perl scripts, so long-running entrypoints
do not execute themselves during C<pax build>

=item *

self-hosted build capability, including building C<bin/pax> itself

=item *

Docker-friendly multi-stage packaging

=back

=head1 MAIN CONCEPTS

=head2 Public Facade

C<PAX::CLI> owns the public operator contract behind C<pax build> and
C<pax run>.

=head2 Manifest Loading

C<PAX::Paxfile> loads repeatable build inputs from C<paxfile.yml>.

=head2 Standalone Image Builder

C<PAX::StandaloneImage> collects dependencies, packages runtime payloads,
embeds assets, and writes the standalone launcher.

=head2 Code Unit Compilation

C<PAX::CodeUnitCompiler> lowers supported Perl source shapes into PAX code unit
records. Unsupported regions remain on explicit fallback paths instead of being
silently miscompiled.

=head2 Packaged Runtime

C<PAX::StandaloneRuntime> provides the packaged helper runtime used after the
standalone executable starts.

=head2 Native Dispatch

C<PAX::StandaloneDispatch> and related runtime pieces execute packaged native
regions and deopt fallback behavior under the standalone model.

=head1 SOW-03 PUBLIC COMMAND SURFACE

PAX exposes only two public commands through C<bin/pax>:

=over 4

=item * C<build>

Compile and package the source tree behind an entrypoint into one standalone
executable.

=item * C<run>

Run the same build flow and then execute the resulting binary with arguments
after C<-->.

=item * interpreter mode

If C<pax> is invoked with a plain Perl script path instead of C<build> or
C<run>, it executes that script directly as interpreter-mode shebang
execution.

=back

The canonical usage is:

  pax build ...
  pax run ...

Interpreter-mode execution is intended for the case where a built C<pax>
binary is installed at a stable path and then used from a shebang line such as
C<#!/usr/local/bin/pax>. In that path, C<PAX::CLI> treats the script argument
as a direct Perl program to run under the packaged runtime instead of as a CLI
subcommand.

Common CLI switches include:

=over 4

=item * C<--paxfile>, C<--no-paxfile>

=item * C<-I>, to prepend Perl library directories for inline builds/runs

=item * C<-M>, to load and import Perl modules for inline builds/runs

=item * C<-e>, to synthesize an entrypoint from inline Perl code

=item * C<--lib>, C<--source-root>, C<--cpanfile>, C<--asset>, C<--asset-dir>

=item * C<--output> / C<-o>

=item * C<--runtime-mode>

=item * C<--compact>

=back

Internal diagnostics and validation modules remain available as Perl APIs for
the test suite and release gates. They are not public C<bin/pax> subcommands.

=head1 PAXFILE CONTRACT

When no positional entrypoint is supplied, C<build> and C<run> read
C<paxfile.yml> by default. C<--paxfile> selects a different manifest and
C<--no-paxfile> disables manifest loading.
When a positional entrypoint is supplied on the CLI, PAX treats that target as
an isolated build and does not silently inherit C<libs>, C<source_roots>,
C<assets>, C<asset_dirs>, C<cpanfiles>, or app metadata from the ambient
C<paxfile.yml>. An explicit C<--paxfile> still applies its manifest defaults.

Supported manifest keys:

=over 4

=item * C<name>

=item * C<entrypoint>

=item * C<libs>

=item * C<source_roots>

=item * C<assets>

=item * C<asset_dirs>

=item * C<cpanfiles>

=item * C<output>

=item * C<runtime_mode>

=item * C<app_name>, C<app_namespace>, C<app_entrypoint_env>, C<app_entrypoint_fallback>, C<app_command>

=back

CLI flags override file values. Output path precedence is:

=over 4

=item 1. C<--output> / C<-o>

=item 2. C<paxfile.yml> C<output>

=item 3. C<.pax/standalone/<name>/<name>>

=back

=head1 MANUAL

=head2 Installation

For development from a repository checkout:

  cpanm --installdeps .
  perl bin/pax help

For release packaging:

  cpanm Dist::Zilla

=head2 First Build

The simplest workflow is a local C<paxfile.yml>:

  name: example-app
  entrypoint: bin/example-app
  output: build/example-app
  libs:
    - lib
  cpanfiles:
    - cpanfile
  runtime_mode: bundled_perl

Then build:

  perl bin/pax build

Long builds print a DD-style task rundown on C<stderr> by default. On a real
terminal the board redraws live; in non-interactive runs it prints a static
rundown while the machine-readable build payload stays on C<stdout>. The build
path is broken into concrete checkpoints such as code-unit compilation,
application metadata inference, dependency analysis, native artifact analysis,
manifest writing, and launcher compilation. The code-unit phase is further
split into source discovery, entrypoint compilation, application unit
compilation, and dependency unit compilation so long builds keep moving
visibly. Application unit compilation includes the current file name, so a
slow module no longer looks like a frozen counter. Set
C<PAX_PROGRESS=0> to suppress the rundown.

And run the result directly:

  ./build/example-app

=head2 Build Without paxfile.yml

When the CLI provides the required shape, C<paxfile.yml> is optional:

  perl bin/pax build -o ./build/example-app bin/example-app

That keeps one-off builds and self-hosting neutral even inside repositories
that ship their own C<paxfile.yml>. Extra roots, assets, and CPAN policy files
must be declared explicitly on the CLI in that mode.

Inline entrypoints use the same public surface. C<-I> adds Perl library roots,
C<-M> loads/imports modules before execution, and C<-e> supplies the
entrypoint code directly:

  perl bin/pax build \
    -I lib \
    -MDateTime \
    -e 'print DateTime->now'

C<pax run> accepts the same switches:

  perl bin/pax run \
    -I lib \
    -MDateTime \
    -e 'print DateTime->now'

=head2 Self Compile

PAX can build itself:

  perl bin/pax build -o /tmp/pax bin/pax
  /tmp/pax help

That self-built binary can then build another standalone application from its
own C<paxfile.yml>. A self-built standalone C<pax> binary can also rebuild
from another standalone C<pax> binary input after the original source tree has
been removed, because the rebuild path carries an embedded source snapshot for
the application units it needs to rebuild.

For plain executable Perl scripts, the standalone build path now keeps source
analysis static. C<pax build> does not need to execute a long-running script
just to inspect it, and recognized numeric loop subs can be rebound through
packaged native artifacts before the script's top-level work starts.

=head1 ARCHITECTURE

=head2 Entrypoint and Build Configuration

C<PAX::CLI> is a small public facade. It resolves C<build> and C<run> inputs
from CLI arguments plus C<PAX::Paxfile>, then delegates to the standalone image
builder.

=head2 Compilation and Code Units

C<PAX::CodeUnitCompiler> compiles supported Perl source shapes into PCU records.
Unsupported or partially supported module shapes use hybrid or fallback payloads
so correctness is preserved while reusable compiler support expands.

=head2 Dependency Discovery

C<PAX::StandaloneImage> follows entrypoints, library directories, source roots,
and C<cpanfile> inputs to collect application modules and dependency payloads.
The mechanism is structural and path/module based, not tied to a project name.

=head2 Asset Embedding

Individual assets and asset directories are embedded into the executable payload.
The generated runtime extracts them into a private runtime directory and exposes
that location to the packaged program.

=head2 Native and Fallback Dispatch

PAX can package native artifacts for supported hot regions. Runtime dispatch
uses native execution when assumptions hold and falls back to bundled Perl
payloads when they do not.

=head2 Standalone Launcher

The final output is an executable launcher containing package metadata, code
units, dependency payloads, optional native artifacts, assets, and runtime helper
code.

=head1 EXAMPLES

Build from C<paxfile.yml>:

  perl bin/pax build

Build a specific entrypoint:

  perl bin/pax build -o ./build/example bin/example

Run after building:

  perl bin/pax run -- status

Embed application assets:

  perl bin/pax build \
    --name webapp \
    --lib lib \
    --source-root lib \
    --asset-dir share \
    --cpanfile cpanfile \
    --runtime-mode bundled_perl \
    --output ./build/webapp \
    bin/webapp

Build PAX itself:

  perl bin/pax build -o /tmp/pax bin/pax
  /tmp/pax help

=head2 Web Applications

PAX supports the single-binary packaging shape for framework applications that
combine Perl modules, PSGI or web framework code, templates, CSS, JavaScript,
and other static assets.

The validated SOW-03 proof includes a Dancer2 + Plack/Starman + Template
Toolkit web application packaged as one executable.

=head1 DOCKER DEPLOYMENT MODEL

PAX supports a minimal multi-stage image pattern:

  FROM perl:5.42 AS builder
  WORKDIR /workspace
  COPY . /workspace
  RUN cpanm --installdeps .
  RUN perl bin/pax build --output /out/app

  FROM debian:bookworm-slim
  COPY --from=builder /out/app /usr/local/bin/app
  CMD ["/usr/local/bin/app"]

The final image contains only the executable. The source tree, assets, cpanfile,
and framework installation are builder-stage inputs.

For an external application, the validated packaging pattern is:

=over 4

=item 1.

build a standalone C<pax> binary

=item 2.

copy that C<pax> binary into the application build stage

=item 3.

compile the application into its own standalone binary

=item 4.

copy only that final binary into the runtime stage

=back

=head1 ADAPTIVE COMPILATION RULE

When a module or framework fails under PAX, fixes should improve a reusable
compiler, packaging, loader, or runtime path for arbitrary modules of the same
class. A project-specific branch is not complete when a neutral generalized
implementation is locally actionable.

=head1 RELEASE GATES

Release readiness requires:

=over 4

=item * C<Changes>, C<README.md>, C<cpanfile>, C<dist.ini>, and C<lib/PAX.pm>.

=item * canonical version synchronization across all PAX modules.

=item * POD and README parity for public behavior.

=item * C<make doc-gate>, which includes C<POD-DOC-ALL> for the full
maintained Perl surface plus changed subroutine comments.

=item * C<make test>.

=item * C<make release-gate>.

=item * a deliberate version-bump step such as
C<make cpan-bump-version VERSION=E<lt>next-versionE<gt>> followed by a meaningful top entry in
C<Changes>.

=item * C<make cpan-build> and C<make cpan-gate>.

=item * C<make git-gate> on the committed tree.

=item * C<make push-gate> as the final closure gate that pushes the committed
HEAD to C<origin>.

=back

C<cpan-gate> verifies that release tarballs exclude temporary probes,
generated workspaces, planning artifacts, and other non-release paths. Git
cleanliness and forbidden tracked-file checks belong to the separate final
C<git-gate>.

C<make cpan-release> follows the DD-style PAUSE flow: run the repo gates,
locate the built tarball in the repository root, and upload it with
C<cpan-upload> using the local uploader configuration. After a successful
upload, the release flow must retag the released commit as
C<RELEASED_TO_PAUSE> and push that tag to C<origin>.

The version bump happens before C<dzil build>, for example with
C<make cpan-bump-version VERSION=E<lt>next-versionE<gt>> or C<make cpan-auto-bump>. After the
bump, the operator must write a meaningful top C<Changes> entry for that
version and commit the release-preparation changes. After a successful PAUSE
upload, the operator must move C<RELEASED_TO_PAUSE> to the released commit and
push the tag to C<origin>. C<make cpan-dist> and
C<make cpan-build> then enforce the version gate, the C<Changes> gate, and the
documentation gate for C<README.md>, this module POD, and the full maintained
Perl surface through C<POD-DOC-ALL> without mutating tracked source files
during the packaging step.

=head1 TESTING AND COVERAGE

Primary validation from a repository checkout is:

  make tdd-gate
  make bdd-gate
  make atdd-gate
  make qa-gate
  make test
  make release-gate
  make cpan-build
  make cpan-gate

Completion requires the full chain, not a partial subset. C<release-gate>,
C<cpan-gate>, C<git-gate>, or C<push-gate> alone are not sufficient. In
project rules, "all gates" means the full closure sequence from TDD through
the final push gate. C<make all-gates> is only the convenience target for
replaying that final verification set. Treat the change set as complete only
when the full gate chain has closed, the committed tree passes git gate, and
the committed HEAD has been pushed to C<origin>.

=head1 KNOWN LIMITATIONS

=over 4

=item * Dynamic loading and runtime mutation can require fallback paths.

=item * Native speed depends on region selection and guard validity.

=item * Performance is still shape-driven today. PAX is not hard-coded for one
application or module name, but it currently accelerates some Perl code shapes
better than others. Tight integer arithmetic loops, repeated numeric leaf
routines, and structurally predictable hot paths are strong candidates. Dynamic
metaprogramming, runtime-heavy startup, IO-dominated scripts, irregular control
flow, and broad general-purpose Perl that never lowers into a native region are
weaker current candidates.

=item * Practical examples matter more than slogans. The current strong cases
are integer sum-loop workloads that PAX can lower into a native region safely.
The following five snippets were measured on this repository's C<0.030>
toolchain on the local Linux/x86_64 build host:

Invoice rollup:

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

Measured runtime: stock Perl C<120.35s>, standalone C<1.26s>, about C<95.4x>
faster.

Retry budget planning:

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

Measured runtime: stock Perl C<116.70s>, standalone C<1.27s>, about C<91.6x>
faster.

Shard weight planning:

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

Measured runtime: stock Perl C<117.49s>, standalone C<1.19s>, about C<98.4x>
faster.

Backfill window checksum:

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

Measured runtime: stock Perl C<117.31s>, standalone C<1.23s>, about C<95.1x>
faster.

Cohort retention counting:

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

Measured runtime: stock Perl C<117.10s>, standalone C<1.16s>, about C<100.7x>
faster.

=item * By contrast, a normal CLI command such as C<dashboard version> or
C<dashboard ps1> can still be dominated by framework startup, helper dispatch,
subprocess work, or other runtime behavior that is outside the current native
region coverage.

=item * This means PAX is not yet "compile once and every Perl workload becomes
Rust-fast." The current model is broader than one-off app patches, but still
selective by supported semantic pattern.

=item * Bundled runtime executables are larger than wrappers because they carry
runtime payloads needed to run without the source tree.

=item * Bundled-perl binaries are validated for builder and runtime
environments from the same libc family; arbitrary host-built cross-distro
portability is not a release guarantee, so multi-stage Docker deployment
should build inside the target container family.

=item * Docker validation requires local Docker access.

=back

=head1 FAQ

=head2 Is PAX tied to one specific project?

No. Example applications are validation corpora. Core compiler and runtime
logic are expected to stay neutral and reusable.

=head2 Does PAX guarantee Rust-like speed for all Perl code?

No. PAX packages the whole application correctly and accelerates hot paths that
it can safely specialize. Dynamic regions continue to use fallback execution.

=head2 Is PAX still case by case?

Not by project name or package name. PAX should stay neutral across arbitrary
Perl applications. But today it is still case by supported code shape. If PAX
recognizes a loop or leaf routine class and can lower it safely, it can do very
well. The five examples above are proven cases on this host: invoice rollup,
retry budget planning, shard weight planning, backfill window checksum, and
cohort retention counting. In those runs stock Perl took about C<116s> to
C<120s>, while the standalone binaries finished in about C<1.16s> to C<1.27s>.
If the workload stays in dynamic Perl semantics, it will package correctly but
may run close to stock Perl speed.

=head2 What should operators report as a performance issue?

Report cases where:

=over 4

=item * a standalone binary is slower than stock Perl in a structurally simple workload

=item * a hot loop or numeric kernel does not improve when native lowering was expected

=item * an application command regresses badly after packaging

=item * performance changes significantly across builder/runtime environments

=back

For a useful report, include the command or script, stock Perl timing, PAX
build timing, standalone runtime timing, and whether the workload is CPU-heavy,
IO-heavy, startup-heavy, or highly dynamic.

=head2 Does pax run require a separate app server?

No. Under SOW-03, C<pax run> builds the standalone executable and then executes
that binary directly.

=head2 Can PAX package web applications with embedded static assets?

Yes. The validated packaging path includes templates, CSS, JavaScript, and
framework code embedded into one standalone executable.

=head1 FILES

=over 4

=item * C<bin/pax> - public command entrypoint.

=item * C<lib/PAX/> - compiler, packaging, runtime, and validation modules.

=item * C<paxfile.yml> - neutral build manifest.

=item * C<README.md> - operator documentation.

=item * C<Changes>, C<cpanfile>, C<dist.ini> - release metadata.

=back

=head1 LICENSE

Copyright 2026 PAX Contributors.

This distribution is licensed under the Artistic License 2.0.

You may use, modify, and redistribute it under the terms of the Artistic
License 2.0. The full license text is available at
L<https://opensource.org/license/artistic-2-0>.

=head1 SECURITY

Security issues should be reported privately before they are discussed in a
public issue tracker.

See the repository F<SECURITY.md> for the reporting address, the backup private
advisory route, and the reproduction detail needed for triage.

=head1 SEE ALSO

The repository C<README.md> mirrors the public command contract and operator
workflow documented here.

The internal documentation rule for DD-style parity is recorded in
F<docs/pax-doc-parity.md>.

=cut
