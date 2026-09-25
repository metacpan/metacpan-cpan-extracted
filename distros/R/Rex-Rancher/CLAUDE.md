# Rex::Rancher

Zero-touch RKE2/K3s Kubernetes deployment for Rex — raw Linux node to a running cluster
with Cilium CNI and optional GPU support. No `kubectl` on the remote host (K8s API is
spoken locally via `Kubernetes::REST`), no SFTP required (built for SFTP-less Hetzner
dedicated servers via `Rex::LibSSH`).

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
principle and lane are in `.claude/rules/rex-rancher-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug anything under `lib/` | `rex-rancher-worker` (default) |
| Pre-release audit | `rex-rancher-release-checker` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live under `.claude/skills/` —
`rex-rancher-core` is owned here, the rest are hardlinks (`manage-skills sync` after a
clone). House rules and the delegation lock: `.claude/rules/rex-rancher-rules.md`.

## Build and test

```bash
prove -lr t/        # compile check + offline unit tests (run faked) — not a deploy proof
dzil build
dzil test
```

There is no integration test; a pipeline change is only trustworthy after a live run
against a real node (`eg/hetzner-gpu.Rexfile`). `dzil release` is maintainer-only — see
the rules file.
