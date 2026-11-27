# Rex::GPU House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

GPU detection and driver management for Rex: `gpu_setup()` takes a bare-metal host from bare
PCI to GPU-ready for Kubernetes. Pipeline, detection contract and distro matrix: skill
`rex-gpu-core`.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug anything under `lib/` | `rex-gpu-worker` (default) |
| New tests, regression tests, failure-path coverage, golden harness | `rex-gpu-test-writer` |
| New GPU / driver branch / NVIDIA support list: generation rows, name rules, NVSwitch/NVLink IDs, vGPU table | `rex-gpu-hardware-curator` |
| Commits, `Changes`, card → done, pre-release audit | `rex-gpu-release-manager` |
| Read-only research, audit, gap analysis | `rex-gpu-worker` ("read-only, change nothing") |

Behavior-relevant = anything under `lib/`, the tests, and any change to a detection rule, a
package list, an OS-version branch, the pipeline order, an emitted shell command, the
containerd config, or the reboot logic. `README.md` and `Changes` wording are not.

## Release

`Rex::LibSSH` is a `recommends`, not a pin, so it does not gate a release here.

## Hazards

- **The blast radius is a remote root shell that installs and reboots.** Every method emits a
  package install, an initramfs rebuild or a `shutdown -r` on someone else's bare-metal host,
  as root, and the *choice* of what to run comes from string-matched `lspci -nn` and
  OS-version output. None of this reproduces in a local test: when a change touches a regex,
  a package list or a version branch, say what it does on a host you are not testing on. The
  traps themselves are in skill `rex-gpu-core`.
- **Never route a driver package through Rex::Pkg.** Driver and toolkit installs call
  `run "apt-get/dnf/zypper install", auto_die => 0` directly and verify with
  `dpkg -l`/`rpm -q` — **not `pkg`**. `pkg` is for inert helpers only (`pciutils`, `curl`,
  `epel-release`). This is the load-bearing invariant of the distribution: do not "clean it
  up". Rationale: skill `rex-gpu-core`.
- **A green suite is not a proof.** `prove -lr t/` covers compilation, pure selection logic
  and golden files of the emitted host commands (`t/golden/`, regenerate on purpose with
  `REX_GPU_GOLDEN_UPDATE=1`) — no detection, install, containerd or reboot path runs without
  a real GPU host. Never report green as evidence for a behavior change; state that it was not
  exercised against hardware and what a maintainer would run on a real node to confirm.
- **This distribution is an upstream.** `Rex::Rancher` calls `gpu_setup` via its optional
  `gpu => 1`, and `Rex::LibSSH` is the backend these deploys ride on. A change to
  `gpu_setup`'s signature, defaults or detection outcome reaches Rancher's production deploys
  with no version gate — a follow-up ticket on the *other* repo's board, never an edit made
  here.

## Perl / Rex specifics — reference, don't restate

Perl house style and cpanfile pinning: skills `getty-perl-core`,
`getty-perl-release-author-getty`, `perl-release-dist-ini`. Rex idioms, connection types and
the SFTP question: skill `rex`. This distribution's internals: skill `rex-gpu-core`. All are
force-loaded for `rex-gpu-*` agents.
