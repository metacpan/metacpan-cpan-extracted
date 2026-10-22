# Rex skill — source-reviewed edition

Version **2.0.0**, researched **2026-10-09**. An English, setup-neutral agent skill for
Perl Rex. The core is portable; transport and application extensions are opt-in.
This package is an instructional and diagnostic resource, not an upstream Rex release.

## Installation

Place the entire `rex/` directory in the skill directory supported by your agent host.
Keep `SKILL.md`, `references/`, `examples/`, `scripts/`, and the other subdirectories
together. Install only one active copy named `rex`; archive the older copy outside
active skill directories. Do not install the archived baseline as another skill.
The folder may live under a repository browsing category such as
`system-and-network-administration/rex/`; that category is not a runtime dependency.

No model is forced and no agent-specific tool allowlist is imposed. The original
`model: sonnet`, read-only `allowed-tools`, and `user-invocable: false` settings are
not carried into the portable frontmatter. Apply invocation and tool permissions in
your agent host's configuration if needed. Removing those keys does not authorize
execution: the host's permissions and the user's change scope still control actions.
No network services, plugins, packages, credentials, or MCP servers are configured
by installing this folder.

## What to load

Start with [SKILL.md](SKILL.md); it routes to focused references rather than one large
manual. [references/INDEX.md](references/INDEX.md) covers every reference.
The [source map](references/research/source-map.md) distinguishes release documentation,
source implementation, and original operational recommendations. The
[claim audit](references/research/claim-audit.md) explains corrections to the old skill.
The unchanged original is [audit/original-skill.md](audit/original-skill.md), for audit
only; it contains superseded statements and must not be used as guidance.

## Local tooling

From this folder, using Python 3.10+ and a standard Perl installation:

```sh
python3 scripts/validate_package.py .
python3 -B -m unittest discover -s tests -v
perl scripts/inspect_rex.pl
python3 scripts/audit_rexfile.py examples/Rexfile.remote --json
```

These commands do not connect to managed hosts or install dependencies. The inspector
scans module text; it does not load or execute Rex. The audit script is deliberately
heuristic and cannot certify safety, detect all top-level side effects, or replace
review of called modules. A zero-finding audit is not permission to run a Rexfile.

The examples using Rex require an installed Rex release and appropriate dependencies;
see [examples/README.md](examples/README.md). Do not mistake `perl -c` or `rex -T` on
an unknown project for sandboxed inspection: loading code may execute BEGIN blocks
and imports. Integration examples were not executed during this build.

## Evidence boundaries

Source review covered specific files and ranges, not every Rex provider, extension,
platform, or upstream test. GitHub development version literals differ from CPAN
versions; [SOURCE_LOCK.json](SOURCE_LOCK.json) records both. No vendored source archive
or working clone is claimed. [VALIDATION.md](VALIDATION.md) records build checks,
missing runtime dependencies, and tests that still need disposable infrastructure.

This package does not contain real hosts, account paths, credentials, or site policy.
Names ending in `.example.test` and bracketed placeholders are illustrative only.
Default references to GPU and Rancher do not enable those integrations.
