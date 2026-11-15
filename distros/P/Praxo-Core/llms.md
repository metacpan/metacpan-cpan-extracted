# PRAXO-CORE Perl

> Embeddable, governed agent execution kernel. This file is the language-specific
> registry and coding-agent entry; it does not guarantee discovery, installation,
> or adoption.

## Package

- package: `Praxo::Core`
- registry: [CPAN (MetaCPAN index)](https://metacpan.org/dist/Praxo-Core)
- source_version: `0.5.1`
- published_version: `0.5.0`
- install_published: `cpanm Praxo::Core`
- install_source: `cpanm Praxo::Core`
- source_tag: `perl/v0.5.1`
- tier: Core
- contract: `SPEC_VERSION` `0.2.0`
- documentation: https://axisvela.github.io/praxo-core/languages/perl/

## Capabilities and Status

- OpenAI-compatible model: native (`Praxo::Adapters::OpenAICompatible`)
- Anthropic model: native (`Praxo::Adapters::Anthropic`)
- Gemini model: native (`Praxo::Adapters::Gemini`)
- MCP client: native (`Praxo::Adapters::MCP`; stdio, plus `Praxo::Adapters::MCPHTTP` for Streamable HTTP 2025-03-26)
- Harmovela sink: native (`Praxo::Adapters::Harmovela`)
- OpenTelemetry sink: native (transport seam) (`Praxo::Adapters::Otel`; caller supplies transport)
- Subagent delegation: native (synchronous seam) (`subagent_run`; no asynchronous manager)
- Retriever: native (`document`, `func_retriever`, `retrieve_documents`)

## Start

- README: `README.md`
- Registry introduction: `REGISTRY.md`
- Markdown entry: `llms.md`
- Compact entry: `llms.txt`
- [Examples](https://github.com/axisvela/praxo-core/tree/main/language/perl/examples): runnable language-specific examples.
- Coding-agent contract: ../../docs/getting-started/coding-agents.md

## Community

- X: <https://x.com/axisvela>
- Weibo: <https://weibo.com/u/1936025761>

## Boundaries

- In-process framework; not a model provider, hosted service, workflow engine,
  identity provider, or safety controller.
- No exactly-once, sandbox-isolation, production-security, real-time, or
  physical-safety claim.
- Registry pages are release snapshots. Verify the published version and read the
  canonical documentation for behavior and limits.
