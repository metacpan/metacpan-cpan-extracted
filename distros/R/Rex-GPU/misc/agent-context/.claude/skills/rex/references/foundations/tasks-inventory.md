# Tasks, inventory, composition, and hooks

## Define targets as data, not accidental ambient state

```perl
use Rex -feature => ['1.4'];
group 'staging_app', 'app-01.example.test', 'app-02.example.test';

desc 'Inspect the explicitly configured staging application group';
task 'inspect_app', group => 'staging_app', sub {
    die "Remote context required\n" if Rex::is_local();
    print run('uname', ['-s'], auto_die => 1), "\n";
};
```

Keep credentials separate from host identity. The documented `auth for => ...` can
configure tasks or groups; declaration order and enabled features matter. Per-server
auth data has its own feature (`use_server_auth`). CLI locality/auth options can
have precedence. Do not invent one universal configuration precedence across every
provider, group, environment, backend, and command-line override.

## Composition choices are not interchangeable

The documented `run_task` defaults to local execution unless an explicit target is
provided; calling it from a remote task does not automatically retain that target.
Use its documented `on` and parameter options and test host routing. `needs` operates
on the current server but does not execute the dependent task's before/around/after
hooks. A policy enforced only by a skipped hook is therefore not a sufficient guard.
Batching tasks does not itself produce health-gated per-host rolling orchestration.

**Practice:** put essential precondition validation inside the mutation function,
not exclusively in orchestration hooks. Use hooks for instrumentation or optional
wrapping only when their call path is established. For a shared helper, accept an
explicit desired-state object rather than resolving global group state repeatedly.

## Namespace and parallelism

Rex exposes tasks as callable symbols under relevant feature behavior. Avoid naming
a task `run`, `file`, `service`, `template`, or a helper imported into the same package.
Use descriptive task names and separate packages for reusable code. Do not assume
Rex task functions behave like ordinary Perl exports in every namespace.

Forked or parallel execution does not give shared in-memory state, global ordered
logs, or a single transaction. Never coordinate a fleet using a mutable package
variable. Use explicit per-host results and an orchestration barrier, or a durable
coordinator with a specified failure policy. Test that a failed canary stops later
hosts; merely setting parallelism to one does not establish that behavior.

## Evidence and scope

- [Rex::Commands (release documentation)](https://metacpan.org/pod/Rex::Commands)
- [lib/Rex/Commands.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Commands.pm)
- [lib/Rex.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex.pm)
