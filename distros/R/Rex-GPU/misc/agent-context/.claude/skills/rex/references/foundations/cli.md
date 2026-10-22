# CLI and safe command selection

## Interpret flags literally

| Intent | Documented form | Operational caveat |
|---|---|---|
| Version | `rex -v` | Check the actual executable and Perl installation. |
| Select file | `rex -f Rexfile ...` | The file is executable code, not inert configuration. |
| List tasks | `rex -f Rexfile -T` | Inspect the file and imports before loading them. |
| Select host | `rex -f Rexfile -H approved-host task_name` | Verify host identity and credentials first. |
| Select group | `rex -f Rexfile -G group_name task_name` | Resolve expansion and exclude unintended hosts. |
| Environment | `rex -f Rexfile -E staging task_name` | This may change inventory/configuration. |
| Parallel count | `rex -f Rexfile -t 1 ...` | Sequential execution is not automatically a rolling strategy. |
| Debug | `rex -f Rexfile -d ...` | Sanitize commands, output, and exceptions. |
| Cache controls | `-c` enables, `-C` disables | Neither is a dry-run switch. |
| Ignore lock | `-F` | Do not use to bypass unexplained active work. |

The CLI documents richer task-list formats and task parameters. Preserve exact task
and option ordering from the installed CLI documentation; do not transfer flags
from Ansible, Fabric, or another automation product.

## No universal preview assumption

Rex executes arbitrary Perl and imperative commands. A preview must be designed by
the application: inspect desired state, calculate a proposed change, and avoid all
mutation paths. Do not advertise `-c`, task listing, `auto_die => 0`, or a function
named `plan` as proof that the whole pipeline is non-mutating.

For an unknown project, use static file review first, then list tasks only in a
restricted controller environment without production credentials. For an approved
project, save the exact invocation, resolved host list, commit, environment, and
non-secret parameters. Review any task-specific parameter parser; a command-line
flag does not automatically become a validated or trusted value.

**Practice:** give read-only diagnostics separate names from applying tasks. Require
explicit target selection and a change authorization for disruptive operations.
Avoid a default task that installs packages, reboots machines, or changes cluster
networking merely because an operator ran `rex` without additional arguments.

## Evidence and scope

- [distribution/Rex/bin/rex (release documentation)](https://metacpan.org/pod/distribution/Rex/bin/rex)
- [Rex::Commands (release documentation)](https://metacpan.org/pod/Rex::Commands)
- [lib/Rex.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex.pm)
