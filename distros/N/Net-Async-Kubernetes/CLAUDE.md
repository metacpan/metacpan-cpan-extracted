# CLAUDE.md

## Distribution

Net::Async::Kubernetes - Async Kubernetes client for Perl built on IO::Async.

Uses Dist::Zilla with `[@Author::GETTY]` plugin bundle.

## Structure

- `lib/Net/Async/Kubernetes.pm` - Main client (IO::Async::Notifier): CRUD, watch,
  pod logs, and exec / attach / port-forward / cp over a websocket duplex transport
- `lib/Net/Async/Kubernetes/Watcher.pm` - Auto-reconnecting watch stream
- `lib/Net/Async/Kubernetes/Controller.pm` - Minimal controller runtime: watch
  registration, keyed workqueue dedup, serialized reconcile dispatch, retry hooks
- `lib/Net/Async/Kubernetes/PortForwardSession.pm` - Duplex websocket session
  returned by port_forward / exec / attach
- `eg/demo.pl` - Comprehensive idempotent demo (requires minikube)
- `eg/watch_pods.pl` - Simple watcher example
- `eg/live_features.pl` - Live demo of exec/attach/cp/port-forward features

## Dependencies

- **IO::Async** / **Net::Async::HTTP** / **Net::Async::WebSocket::Client** - Async
  framework, HTTP and websocket transports
- **Kubernetes::REST** - Sync REST client (used for request building/response parsing)
- **IO::K8s** - Kubernetes API object classes

## Testing

```bash
prove -l t/                    # Mock mode (no cluster needed) — the default check
TEST_KUBERNETES_REST_KUBECONFIG=~/.kube/config prove -lv t/   # Live mode (minikube!)
```

Dual-mode architecture (`t/lib/MockTransport.pm`, `t/lib/TestKube.pm`) — the same
tests run against mock or live cluster. Live mode mutates the target cluster; details
and guardrails in `.claude/rules/nak-rules.md`.

**A new test file must be `git add`ed before `dzil test` runs it.** The bundle
gathers via `Git::GatherDir`, so an untracked `t/*.t` is silently left out of the
build — `dzil test` then reports a green run that never executed the new file. Use
`git add -N t/NN-name.t` (intent-to-add, no commit) as soon as the file exists.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
principle and lane are in `.claude/rules/nak-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `nak-worker` (default) |
| Write/extend tests (mock harness, dual-mode) | `nak-test-writer` |
| Pre-release audit | `nak-release-checker` |
| POD in the house format | `nak-pod-writer` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live under `.claude/skills/` —
architecture and invariants in `nak-core`, hardlink-shared house skills alongside it.

## PodWeaver

`[@Author::GETTY]` conventions: inline `=attr`, `=method`, `=seealso`. No manual
NAME/VERSION/AUTHOR sections. Full rules: skill `getty-perl-release-author-getty`.
