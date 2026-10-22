# Configuration, CMDB, and template inputs

## Keep three namespaces separate

Inventory answers where work may run. Connection configuration answers how to
connect and escalate. Desired-state data answers what the target should look like.
A CMDB provider does not replace an authorization policy or secret store.

The documented CMDB interface defaults to YAML under the relevant feature bundle.
An explicit provider configuration can specify host/default paths and a merge
behavior. Do not assume that a list of paths means "last file wins"; select and test
the provider's merge policy. `cmdb(...)` returns a Rex::Value; `get cmdb(...)` is the
documented form for obtaining the value when assigning it.

```perl
set cmdb => {
    type => 'YAML',
    path => ['cmdb/{hostname}.yml', 'cmdb/default.yml'],
    merge_behavior => 'LEFT_PRECEDENT',
};
# Inside a task, after target identity is established:
my $application = get cmdb('application');
```

## Schema before mutation

**Practice:** resolve the effective data once, validate it, then create an immutable
plan. Validate required fields, enums, absolute paths, integer ranges, duplicate
identities, and incompatible combinations. Reject an unknown environment rather
than falling back to production. Distinguish missing, null, empty, and false values;
`||` defaults often erase valid zero/false settings where `//` is more appropriate.

Do not pass arbitrary CMDB keys through to backend constructors or shell arguments.
Use an explicit allowlist of supported application options. Keep secret references
in the plan, not secret values. Record a digest of the non-secret desired state in
the run report so later diagnosis can reproduce the decision without exposing keys.

## Cache and rendering lifecycle

CMDB data can be cached per host/provider. A change to the input file does not prove
that a long-lived process reread it. Define when configuration is loaded, when cache
is invalidated, and whether a task can observe a changed value halfway through a
run. Avoid global cache toggles as a substitute for a documented lifecycle.

Pass explicit template variables for application configuration. Templates can also
receive automatically exposed context; do not treat the template engine as a
sandbox. Unit-test rendering with missing and malicious values, distinguish text
encoding from binary content, and validate the resulting application configuration
before replacing the active file. Put one owner in charge of each managed file.

## Evidence and scope

- [Rex::CMDB (release documentation)](https://metacpan.org/pod/Rex::CMDB)
- [lib/Rex.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex.pm)
- [Rex::Commands::File (release documentation)](https://metacpan.org/pod/Rex::Commands::File)
