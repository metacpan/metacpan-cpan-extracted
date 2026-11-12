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

## Registry and Coding-Agent Entry

- Registry introduction: [REGISTRY.md](https://github.com/axisvela/praxo-core/blob/main/language/perl/REGISTRY.md)
- Machine-readable entry: [llms.txt](https://github.com/axisvela/praxo-core/blob/main/language/perl/llms.txt) and [llms.md](https://github.com/axisvela/praxo-core/blob/main/language/perl/llms.md)
- Coding-agent contract: [docs/getting-started/coding-agents.md](https://github.com/axisvela/praxo-core/blob/main/docs/getting-started/coding-agents.md)
- Registry: [CPAN (MetaCPAN index)](https://metacpan.org/dist/Praxo-Core)

## Scope

The Core implements all eleven vector groups: toolcall, JSON Schema, plugin,
memory, event, stream, checkpoint, policy, context, middleware, and the agent
loop. It includes a public API snapshot and a dependency-free test runner.

The distribution root package is `Praxo::Core`; `Praxo::Agent` and the other
modules remain available.

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

## OpenAI-Compatible Model

```perl
use Praxo::Adapters::OpenAICompatible ();

my $model = Praxo::Adapters::OpenAICompatible->new(
    base_url => 'https://api.openai.com/v1',
    model => 'gpt-4o-mini',
    api_key => $ENV{PRAXO_API_KEY},
);
my $options = Praxo::Agent::AgentOptions->new($model);
```

The adapter uses non-streaming `POST /chat/completions`, maps tool calls and
usage, and passes `tool_choice`, `response_format`, and `temperature` through.
It uses core `HTTP::Tiny` and `JSON::PP`; no provider SDK is required.

## Anthropic and Gemini Models

```perl
use Praxo::Adapters::Anthropic ();
use Praxo::Adapters::Gemini ();

my $claude = Praxo::Adapters::Anthropic->new(
    model => 'claude-sonnet-4-5',
    api_key => $ENV{ANTHROPIC_API_KEY},
);
my $gemini = Praxo::Adapters::Gemini->new(
    model => 'gemini-2.5-pro',
    api_key => $ENV{GEMINI_API_KEY},
);
```

Both adapters accept a `transport` callback for deterministic tests and use
core `HTTP::Tiny` otherwise.

## MCP Client

Praxo::Adapters::MCP implements MCP initialize, paginated tool listing, and
tool calls over an injected transport callback.

## Harmovela Event Sink

`Praxo::Adapters::Harmovela` posts each event to `{base_url}/events`.

```perl
use Praxo::Adapters::Harmovela ();

my $sink = Praxo::Adapters::Harmovela->new(
    base_url => 'http://127.0.0.1:8790/aep/api',
);
$options->{events} = $sink;
```

A 2xx status is success; other statuses raise `HARMOVELA_HTTP` with the status
and a bounded body. Inject `transport` (and `clock`) to test without a network.
The sink adds no authentication, retries, buffering, ordering, or exactly-once
delivery. Use HTTPS and filter sensitive event data first.

## Layout

- `lib/Praxo/` package source.
- `conformance/run.pl` vector runner.
- `api-snapshot.pl` and `api/` public API snapshot.
- `tests/run.pl` test suite.

## Release

Tag shape: `perl/v0.1.1`. The tag targets `SPEC_VERSION` `0.2.0`. CPAN
publication uses `.github/workflows/perl-release.yml`; see
[PUBLISHING.md](PUBLISHING.md).
