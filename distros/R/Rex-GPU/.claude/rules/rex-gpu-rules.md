# Rex::GPU House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their conventions from the skills
force-loaded via `briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions. When uncertain, ask rather than guess.
   Push back when a simpler approach exists. Stop when confused; name what's unclear.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative.
3. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code,
   comments or formatting. Match existing style.
4. **Match the codebase's conventions, even if you disagree** — Conformance > taste.
   Surface a harmful convention; don't fork silently.
5. **Fail loud** — "Done" is wrong if anything was skipped silently. Surface uncertainty,
   don't hide it. A green `prove` is not evidence that a detection or install change works.
6. **A red test is a claim before it is a failure** — Before changing code to turn a test
   green, say what the test asserts and whether your fix keeps that claim or replaces it.

## Delegation

Depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  code yourself — delegate. Your lane: coordinate, inspect, plan, review diffs, run tests,
  manage git, edit non-behavioral docs. Why: only the `rex-gpu-*` agents get their skills
  force-loaded via `briefing.skills`; you get no briefing and would touch code that installs
  drivers and reboots production servers with too little context.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug anything under `lib/` | `rex-gpu-worker` (default) |
  | New tests, regression tests, failure-path coverage, golden harness | `rex-gpu-test-writer` |
  | New GPU / driver branch / NVIDIA support list: generation rows, name rules, NVSwitch/NVLink IDs, vGPU table | `rex-gpu-hardware-curator` |
  | Pre-release audit | `rex-gpu-release-checker` |

- **You cannot spawn subagents** (you ARE a `rex-gpu-*` agent): The delegation lock does not
  apply — implement, refactor, debug and test per these rules.

Behavior-relevant = anything under `lib/`, the tests, and any change to a detection rule, a
package list, an OS-version branch, the pipeline order, an emitted shell command, the
containerd config, or the reboot logic. `README.md` and `Changes` wording are not.

## The blast radius is a remote root shell that installs and reboots

Every method here emits a package install, an initramfs rebuild or a `shutdown -r` on
someone else's bare-metal host, as root, and the *choice* of what to run comes from
string-matched `lspci -nn` and OS-version output. A wrong detection branch installs the
wrong driver; a `10.1`-style version whose dots get stripped picks the wrong package set; a
fresh boot where cloud-init holds the dpkg lock fails an install that is written to survive
it. None of this reproduces in a local test. When a change touches a regex, a package list
or a version branch, say what it does on a host you are not testing on.

## Never route a driver package through Rex::Pkg

Driver and toolkit installs call `run "apt-get/dnf/zypper install", auto_die => 0` directly
and verify with `dpkg -l`/`rpm -q` — **not `pkg`**. `Rex::Pkg` dies on the non-zero exit
that DKMS builds, grub and initramfs regeneration return *on success*. `pkg` is for inert
helpers only (`pciutils`, `curl`, `epel-release`). This is the load-bearing invariant of
the distribution — full rationale in skill `rex-gpu-core`; do not "clean it up".

## A green suite is not a proof

The suite covers compilation, pure selection logic and golden files of the emitted host
commands (`t/golden/`, regenerate on purpose with `REX_GPU_GOLDEN_UPDATE=1`) — no detection, install,
containerd or reboot path runs without a real GPU host. Never report green as evidence for
a behavior change; state that it was not exercised against hardware and what a maintainer
would run on a real node to confirm.

```bash
prove -lr t/
```

## Release — never without permission

`dzil build` / `dzil test` / `prove -lr t/` are fine anytime. `dzil release` and any CPAN
upload are STRICTLY forbidden without the maintainer's explicit go-ahead — even if a plan
lists "release" as the next step. Stop and ask. `Rex::LibSSH` is a `recommends`, not a pin,
so it does not gate a release here.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — don't
invoke the skill first, just use it. Board state lives in `refs/karr/*`.

- `karr list --compact` / `karr board` · `karr show ID` · `karr create "Title" --priority high --body '…'`
- `karr edit ID -a "note"` · `karr move ID in-progress --claim NAME` · `karr handoff ID --claim NAME --note "…"`

Serialize board mutations when fanning out: keep implementation parallel, then loop the
`karr move`/`handoff`/`sync` calls sequentially. Full command surface: skill
`kanban-issues-karr-cli`.

## Downstream — this distribution is an upstream

`Rex::Rancher` calls `gpu_setup` via its optional `gpu => 1`, and `Rex::LibSSH` is the
backend these deploys ride on. A change to `gpu_setup`'s signature, defaults or detection
outcome reaches Rancher's production deploys with no version gate. Such a change belongs in
a follow-up ticket on the *other* repo's board, never as an edit made here.

## Reference, don't restate

Perl house style and cpanfile pinning: skills `getty-perl-core`,
`getty-perl-release-author-getty`, `perl-release-dist-ini`. Rex idioms, connection types and
the SFTP question: skill `rex`. This distribution's pipeline, detection contract and
distro matrix: skill `rex-gpu-core`. All are force-loaded for `rex-gpu-*` agents; do not
duplicate them here.
