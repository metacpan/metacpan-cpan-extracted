# Net::Async::Kubernetes House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Async Kubernetes client for IO::Async, built on `Kubernetes::REST` and `IO::K8s`. Read first:
the seam you're touching — the Kubernetes::REST request-building calls, the duplex transport,
`t/lib/`.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `nak-worker` (default) |
| Write/extend tests (mock harness, dual-mode) | `nak-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `nak-release-manager` |
| POD in the house format (`=attr`/`=method`) | `nak-pod-writer` |
| Read-only research, audit, gap analysis | `nak-worker` ("read-only, change nothing") |

Behavior-relevant = the request/response pipeline (Kubernetes::REST seam, IO::K8s inflation),
Watcher reconnect and resourceVersion handling, the Controller runtime (workqueue, reconcile
dispatch), the websocket duplex transport (exec/attach/port-forward/cp), TLS/kubeconfig/PEM
handling, error and Future semantics, tests, performance. Pure prose docs, POD wording and
`Changes` notes are not.

## Hazards

- **Live tests mutate a real cluster.** With `TEST_KUBERNETES_REST_KUBECONFIG` set, the same
  `t/*.t` files run against whatever cluster that kubeconfig points to — creating and deleting
  real resources. Only ever point it at a disposable cluster (minikube). Never set it on your
  own initiative; unset, the suite runs mock-only, so always report *which mode* was green.
- **Getty-dist version trap.** `Kubernetes::REST` and `IO::K8s` are Getty dists: the repo
  `$VERSION` is always one ahead of CPAN, so a version copied from a sibling repo into
  `cpanfile` is uninstallable. Pin to the released version (`cpanm --info`) — full rule in
  skill `getty-perl-core`.

## Perl / async specifics — reference, don't restate

Module loading, cpanfile pinning and house style: `getty-perl-core`. Async/Future lifecycle:
`perl-io-async-future`. K8s API usage: `perl-kubernetes-rest` + `perl-io-k8s-kubernetes-classes`.
Release conventions: `getty-perl-release-author-getty` + `perl-release-dist-ini`.
