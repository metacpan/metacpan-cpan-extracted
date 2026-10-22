# Idempotency, change detection, and notifications

## Design a convergence contract

Desired-state resources and imperative commands can coexist in Rex. A second
successful run is not by itself proof of idempotence: compare actual configuration,
service activation, installed versions, and disruptive side effects. Read-only `run`
commands can be reported as changed because the command executed. Conversely, a
resource report may omit a boot-enablement change if it tracks only running status.

**Practice:** write each mutation as observe → validate → apply only if needed →
verify. State exactly what "unchanged" means. A `creates` marker proves only existence;
use a checksum/version/schema check to recognize a completed artifact. Create any
completion marker only after validation succeeds. Define repair behavior for an
interrupted deployment or an existing but corrupt file.

## Use notifications with verified semantics

`file ... on_change => sub { ... }` couples a changed file to a callback. `notify`
selects a named resource and asks it to execute. Register the intended resource
before notifying it; do not treat notification as a general workflow scheduler,
automatic deduplicator, end-of-run queue, or fleet-wide barrier.

The inspected `run` registration for `only_notified` stores options, but its callback
calls `run($option->{command})` without forwarding the full option hash. Do not rely
on queued per-call `env`, `cwd`, `timeout`, or `auto_die` surviving this path. Verify
the installed version or use an explicit application callback whose options are
passed at actual execution time.

## Safe configuration activation pattern

Render deterministic content. Stage it without changing the active configuration.
Validate with the actual application's validator. Compare against the active state.
Replace using the approved filesystem mechanism, then activate only when necessary.
Verify application health, not merely command success. Restore the previous known-good
configuration if activation fails and the rollback is safe for this change.

When several files require one activation, use an explicit task-scoped dirty flag
or a plan that aggregates changes, then execute one validated activation step.
Do not assume multiple callbacks are coalesced. Under parallel host execution, that
flag is host/process-local, not a fleet coordination mechanism.

Tests must include initial apply, unchanged apply, content change, invalid content,
failed activation, interrupted write, and resume. Document non-idempotent exceptions,
such as a deliberate restart or a mutable `latest` package target.

## Evidence and scope

- [lib/Rex/Commands/Run.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Commands/Run.pm)
- [lib/Rex/Commands/Service.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Commands/Service.pm)
- [Rex::Commands::File (release documentation)](https://metacpan.org/pod/Rex::Commands::File)
- [Rex::Commands::Notify (release documentation)](https://metacpan.org/pod/Rex::Commands::Notify)
