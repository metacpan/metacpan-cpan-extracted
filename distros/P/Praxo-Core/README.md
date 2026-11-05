# PRAXO-CORE Perl Core

PRAXO-CORE is an embeddable, MIT-licensed agent framework. This distribution is
its native Perl Core: an agent loop with tool registration and dispatch, policy
hooks, typed events, memory, checkpoints, context budgets, middleware, JSON
Schema validation, and plugin manifest parsing.

The normative contract is [`spec/`](../../spec/README.md); Go remains the
reference implementation.

- `SPEC_VERSION`: `0.2.0`
- Core version: `0.1.1`
- Tier: core
- License: MIT
- Dependencies: Perl core modules only (`JSON::PP`, `File::Spec`, `Cwd`)

## Scope

The Core implements all eleven vector groups: toolcall, JSON Schema, plugin,
memory, event, stream, checkpoint, policy, context, middleware, and the agent
loop. It includes a public API snapshot and a dependency-free test runner.

## Build and test

```bash
perl language/perl/conformance/run.pl
perl language/perl/api-snapshot.pl --check
perl language/perl/tests/run.pl
```

## Quickstart

```perl
use lib 'language/perl/lib';
use Praxo::Models ();
use Praxo::Agent ();

my $model = Praxo::Agent::StaticModel->new('hello');
my $options = Praxo::Agent::AgentOptions->new($model);
my $result = Praxo::Agent::run_agent(
    $options,
    Praxo::Models::session(id => 'demo'),
    'hello',
);
print $result->{output};
```

Tools register on the options object:

```perl
use Praxo::Agent ();

my $registry = Praxo::Agent::ToolRegistry->new;
$registry->register(Praxo::Agent::FuncTool->new('echo', 'Echo arguments', sub {
    return $_[0];
}));

my $options = Praxo::Agent::AgentOptions->new($model);
$options->{tools} = $registry;
$options->{max_steps} = 8;
```

## Layout

- `lib/Praxo/` package source.
- `conformance/run.pl` vector runner.
- `api-snapshot.pl` and `api/` public API snapshot.
- `tests/run.pl` test suite.

## Release

Tag shape: `perl/v0.1.1`. The tag targets `SPEC_VERSION` `0.2.0`. CPAN
publication uses `.github/workflows/perl-release.yml`; see
[PUBLISHING.md](PUBLISHING.md).
