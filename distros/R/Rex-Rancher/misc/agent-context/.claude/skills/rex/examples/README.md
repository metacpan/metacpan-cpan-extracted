# Examples and execution boundaries

These are original teaching assets, not vendor source copies. None connects to a
real target merely by being present in the skill. Review the code before loading it.
Rex-dependent examples were not executed in this build; see [validation](../VALIDATION.md).

| Asset | Purpose | Requirements and effects |
|---|---|---|
| [Rexfile.remote](Rexfile.remote) | Minimal explicit-target task | Rex plus approved OpenSSH stack; reads kernel name remotely |
| [Rexfile.status](Rexfile.status) | Observe raw status and effective driver | Rex plus selected backend and POSIX target shell; fixed exit-7 probe, no target writes |
| [Rexfile.libssh](Rexfile.libssh) | Separate exec/metadata probes | Optional Rex::LibSSH dependencies; reads an existing target path |
| [Rexfile.local-smoke](Rexfile.local-smoke) | Two local applies and byte/mode verification | Rex; explicit opt-in; only a new private temporary directory |
| [Plan.pm](module/lib/Example/Plan.pm) and [plan.t](module/t/plan.t) | Pure validation with ordinary Exporter | Standard Perl only; no network or filesystem mutation |
| [RexAdapter.pm](module/lib/Example/RexAdapter.pm) | Thin mutation boundary | Rex plus pure helper; caller-authorized remote file write when invoked |
| [default CMDB](cmdb/default.yml), [host CMDB](cmdb/app-01.example.test.yml) | Non-secret desired-state fixtures | Copy to a reviewed project and test its explicit YAML merge policy |
| [Activation skeleton](config-activation.pl.example) | Application lifecycle design | Deliberately undefined domain functions; not executable as supplied |

## Safe offline helper test

```sh
perl examples/module/t/plan.t
```

This tests only the pure plan helper. Its path policy is lexical: it rejects
traversal and a sibling-root prefix but does not inspect symlinks or grant permission
to write any path. An approved adapter must enforce trusted filesystem ownership.

## Approved runtime checks

After installing trusted Rex dependencies in a disposable controller:

```sh
rex -f examples/Rexfile.remote -H approved-host inspect_kernel
rex -f examples/Rexfile.status -H approved-host inspect_status_contract
```

Configure verified host keys and credentials externally. For the optional status
backend, set `REX_BACKEND` to `OpenSSH`, `SSH`, or `LibSSH` before invocation.
The task does not decode the observed status because it would need a tested contract
for the effective driver, especially under sudo.

For the local smoke example, explicitly set `REX_LAB_WRITE=1`, then run:

```sh
rex -f examples/Rexfile.local-smoke local_file_smoke
```

It creates and cleans up a new private temporary directory through File::Temp. It
refuses a remote context and never writes system configuration. The normal managed
file API's Rex permission argument is `mode => 600`; the Perl stat assertion uses
an actual octal bitmask/value. Do not confuse those two representations.

For a real deployment, adapt the validated-plan pattern, add domain validation and
recovery, and use the [change brief](../templates/change-brief.md). No example is a
production rollout, complete credential setup, or universal configuration validator.
