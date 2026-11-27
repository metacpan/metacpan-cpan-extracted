# PRAXO-CORE Perl Registry Introduction

**Status:** published on CPAN; README.pod indexed. Source version `0.8.1`, source
tag `perl/v0.8.1`. Published registry version: `0.8.0`. Registry
pages are release snapshots; verify the published version before relying on a
feature.

## Positioning

PRAXO-CORE is an embeddable, MIT-licensed AI agent framework. This distribution is its native Perl Core: an agent loop with tool registration and dispatch, policy hooks, human-in-the-loop interrupt decisions, typed events, memory, checkpoints, context budgets, middleware, OTel and Harmovela sinks, MCP, retriever and synchronous delegation seams, JSON Schema validation, and plugin manifest parsing.

## Package

| Field | Value |
| --- | --- |
| Package | `Praxo::Core` |
| Registry | [CPAN (MetaCPAN index)](https://metacpan.org/dist/Praxo-Core) |
| Source version | `0.8.1` |
| Published registry version | `0.8.0` |
| Install (published) | `cpanm Praxo::Core@0.8.1` |
| Install (source/release prepared) | `cpanm ./language/perl` |
| Source tag | `perl/v0.8.1` |
| Tier | Core |
| Contract | `SPEC_VERSION` `0.2.0` |
| Documentation | https://axisvela.github.io/praxo-core/languages/perl/ |

## Capabilities and Status

| Adapter | Status | Detail |
| --- | --- | --- |
| OpenAI-compatible model | native | `Praxo::Adapters::OpenAICompatible`; `generate_stream` reassembles SSE content, tool calls, usage, and finish reason |
| Anthropic model | native | `Praxo::Adapters::Anthropic`; `generate_stream` reassembles Anthropic SSE |
| Gemini model | native | `Praxo::Adapters::Gemini`; `generate_stream` reassembles Gemini SSE |
| MCP client | native | `Praxo::Adapters::MCP`; stdio, plus `Praxo::Adapters::MCPHTTP` for Streamable HTTP 2025-03-26 |
| Harmovela sink | native | `Praxo::Adapters::Harmovela` |
| OpenTelemetry sink | native (transport seam) | `Praxo::Adapters::Otel`; caller supplies transport |
| Subagent delegation | native (synchronous seam) | `subagent_run`; no asynchronous manager |
| Retriever | native | `document`, `func_retriever`, `retrieve_documents` |

## Coding-agent entry

- [Examples](https://github.com/axisvela/praxo-core/tree/main/language/perl/examples): runnable language-specific examples.
- [Tutorial plan](https://axisvela.github.io/praxo-core/getting-started/tutorial-plan/) ([中文](https://axisvela.github.io/praxo-core/zh-CN/getting-started/tutorial-plan/)): delivery standards and the [reference application portfolio](https://axisvela.github.io/praxo-core/project/roadmap/#reference-application-portfolio).
- [100 candidate agent scenarios](https://axisvela.github.io/praxo-core/getting-started/agent-scenarios/) ([中文](https://axisvela.github.io/praxo-core/zh-CN/getting-started/agent-scenarios/)): candidate business goals and their existing related slices.
- [Unified Tutorial Catalog](https://axisvela.github.io/praxo-core/getting-started/tutorial-catalog/) ([中文](https://axisvela.github.io/praxo-core/zh-CN/getting-started/tutorial-catalog/)): cross-language tutorials, examples, and reference-application paths.
- Scenario tutorials:
  - [community-governance](https://github.com/axisvela/praxo-core/tree/main/language/perl/Tutorial/community-governance): Fixed synthetic issues produce four classified items and a review-only reviewer request. No GitHub API, closure or impersonation.
  - [compliance-tracking](https://github.com/axisvela/praxo-core/tree/main/language/perl/Tutorial/compliance-tracking): Fixed policy versions yield two changed sections and a duplicate removal; Core drafts review-only remediation. No filing, audit conclusion or live source.
  - [localization-draft](https://github.com/axisvela/praxo-core/tree/main/language/perl/Tutorial/localization-draft): Fixed market rules produce a review-only localized text draft. No translation engine, CMS or publication.
  - [log-triage](https://github.com/axisvela/praxo-core/tree/main/language/perl/Tutorial/log-triage): A small operations tutorial using the native Perl Core. The Agent has one fixed tool, `summarize_log`, which reads the tutorial's own log fixture and returns severity counts. Th...
  - [news-factcheck](https://github.com/axisvela/praxo-core/tree/main/language/perl/Tutorial/news-factcheck): A bounded first slice of MD-02, not a truth-verification service. It compares fixed source excerpts for one synthetic article, cites a contradiction and drafts a review-only fac...
- Reference applications: no accepted end-to-end application yet; candidate goals are tracked in the [Reference Application Portfolio](https://axisvela.github.io/praxo-core/project/roadmap/#reference-application-portfolio).
- [llms.txt](llms.txt): compact machine-readable entry for this language.
- [llms.md](llms.md): Markdown version of the same entry.
- [Coding-agent contract](../../docs/getting-started/coding-agents.md): explicit
  scope, final-argument authorization, denial tests, and verification commands.

## Community

- X: <https://x.com/axisvela>
- Weibo: <https://weibo.com/u/1936025761>
- LinkedIn: <https://www.linkedin.com/company/axisvela/>
- Facebook: <https://www.facebook.com/profile.php?id=61596905732406>
- YouTube: <https://www.youtube.com/@axisvela>
- Discord: <https://discord.com/channels/1575163993767809064/1575164343148875977>
- GitHub Discussions: <https://github.com/axisvela/praxo-core/discussions>
- GitHub Issues: <https://github.com/axisvela/praxo-core/issues>
- Documentation: <https://axisvela.github.io/praxo-core/>
- Architect: <https://axisvela.architect.pub>

## Boundaries

- PRAXO-CORE is an embeddable, MIT-licensed execution kernel, not a hosted
  model, workflow engine, identity provider, or safety controller.
- Do not infer exactly-once execution, complete sandbox isolation, production
  security certification, live-provider behavior, or physical safety from this
  package.
- Check the registry page and source tag for the exact version; source READMEs
  and canonical documentation may be newer than a published registry page.
