# Execution model and locality

## What executes where

A Rexfile is Perl running on the controller. Defining a task registers code; running
the task establishes an execution context and dispatches DSL operations through it.
Perl built-ins such as `open`, backticks, and `system` still execute on the controller.
They do not become remote merely because they appear in a remote task. In contrast,
`run`, `file`, and resource helpers resolve Rex interfaces for the current context.
A template is rendered by controller-side Perl before content is managed remotely.

The inspected `get_current_connection` creates a Local context when no connection
exists. Therefore an accidental top-level resource call can mutate the controller,
including during another operation that loads the file. Task listing is not a
sandbox. Neither is `perl -c`: compile-time blocks and imports execute.

## Resolve context before doing work

Record the controller's OS and Perl, task name, resolved host, login user, configured
backend, effective backend, and sudo state. Do not log complete connection objects:
they can contain authentication material. `Rex::is_local()` is useful as an explicit
remote-task guard. `Rex::is_ssh()` returns a transport object in inspected code and
is not a detailed capability negotiation API.

```perl
task 'inspect_target', sub {
    die "A remote target is required\n" if Rex::is_local();
    my $kernel = run 'uname', ['-s'], auto_die => 1;
    print "$kernel\n";
};
```

A Local backend is a legitimate deployment target, not merely a test double. Put
controller-only build steps and target-only deployment steps in separately named
tasks. Keep desired-state calculations pure where possible; pass their results to
mutation functions instead of mixing local filesystem access and remote commands.

## Review procedure

First read the whole entrypoint and its imports statically. Identify top-level
expressions, BEGIN/INIT/END blocks, module search-path changes, plugin loading,
subprocess calls, and task registration. Next trace only the selected task and
its callees. Mark each operation `controller`, `current target`, or `explicit target`.
Finally verify transitions: `LOCAL`, `run_task`, nested tasks, and sudo contexts need
independent attention. A task label such as `remote` proves nothing by itself.

**Practice:** fail closed when a remote-only task has no approved target. Do not
silently choose localhost or a default production group to make an example run.

## Evidence and scope

- [lib/Rex.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex.pm)
- [Rex::Commands (release documentation)](https://metacpan.org/pod/Rex::Commands)
