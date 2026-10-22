# Reusable module authoring and exports

## Separate the library from the Rex adapter

**Practice:** put schema validation, planning, parsing, and rendering in pure Perl
modules. Put target observation and mutation in a thin Rex adapter. Put host groups,
credentials, environment selection, and rollout policy in the Rexfile or application
configuration. This gives reusable modules without personal paths or infrastructure
assumptions and allows meaningful tests without a remote host.

Avoid network connections or target mutations in `use`, import, BEGIN, or module
initialization. A module may be loaded just to inspect tasks. Validate all options
before the first state-changing call and reject unknown or contradictory fields.
Use explicit configuration arguments for library functions; do not turn every helper
into a task that depends on ambient global values.

## Export behavior

The inspected Rex::Exporter copies symbols from `@EXPORT`, optionally excluding
names with `-no => [...]`, and can redirect registration with `register_in`.
Its import takes option-style pairs, not the familiar `qw(function_a function_b)`
selection list. Do not write that syntax for Rex command modules unless their
specific API explicitly supports it.

A module that needs Rex's registration semantics can follow the framework pattern:

```perl
package Example::RexAdapter;
use strict;
use warnings;
use Rex::Commands::Run;
use base 'Rex::Exporter';
our @EXPORT = qw(inspect_kernel_name);
sub inspect_kernel_name {
    die "Remote context required\n" if Rex::is_local();
    return run 'uname', ['-s'], auto_die => 1;
}
1;
```

A pure helper can use ordinary `Exporter 'import'` and `@EXPORT_OK`. There is no
blanket rule that every module used by a Rex project must inherit Rex::Exporter.
Avoid task names that collide with imported DSL or helper names.

## Interface contracts and extension safety

Document side effects, supported option types, return shape, exception categories,
required capabilities, and version bounds. Inject observation/execution collaborators
when unit tests benefit, but do not label mocked execution as a deployment test.
Preserve raw backend failure information for diagnosis instead of converting every
failure into an empty list or false "already absent" result.

For plugins and subclass hooks, define which steps can be overridden and how
preconditions remain enforced. Treat experimental extension points as pinned
implementation contracts, not a stable universal Rex plugin ABI.

## Evidence and scope

- [lib/Rex/Exporter.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Exporter.pm)
- [lib/Rex.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex.pm)
- [lib/Rex/GPU.pm](https://github.com/Getty/rex-gpu/blob/bded1977b558c2fb6a46ae09ad2379acc5287775/lib/Rex/GPU.pm)
- [lib/Rex/Rancher.pm](https://github.com/Getty/rex-rancher/blob/cb4df5cbaf6f62ff1de943cd54f0ed5c8ddc652e/lib/Rex/Rancher.pm)
