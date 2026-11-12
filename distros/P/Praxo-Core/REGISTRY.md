# PRAXO-CORE Perl Registry Introduction

**Status:** published on CPAN (0.2.0); install smoke not recorded. Source version `0.3.0`, source
tag `perl/v0.3.0`. Published registry version: `0.2.0`. Registry
pages are release snapshots; verify the published version before relying on a
feature.

## Positioning

PRAXO-CORE is an embeddable, MIT-licensed agent framework. This distribution is its native Perl Core: an agent loop with tool registration and dispatch, policy hooks, typed events, memory, checkpoints, context budgets, middleware, JSON Schema validation, and plugin manifest parsing.

## Package

| Field | Value |
| --- | --- |
| Package | `Praxo::Core` |
| Registry | [CPAN (MetaCPAN index)](https://metacpan.org/dist/Praxo-Core) |
| Source version | `0.3.0` |
| Published registry version | `0.2.0` |
| Install (published) | `cpanm Praxo::Core` |
| Install (source/release prepared) | `cpanm Praxo::Core` |
| Source tag | `perl/v0.3.0` |
| Tier | Core |
| Contract | `SPEC_VERSION` `0.2.0` |
| Documentation | https://axisvela.github.io/praxo-core/languages/perl/ |

## Coding-agent entry

- [llms.txt](llms.txt): compact machine-readable entry for this language.
- [llms.md](llms.md): Markdown version of the same entry.
- [Coding-agent contract](../../docs/getting-started/coding-agents.md): explicit
  scope, final-argument authorization, denial tests, and verification commands.

## Boundaries

- PRAXO-CORE is an embeddable, MIT-licensed execution kernel, not a hosted
  model, workflow engine, identity provider, or safety controller.
- Do not infer exactly-once execution, complete sandbox isolation, production
  security certification, live-provider behavior, or physical safety from this
  package.
- Check the registry page and source tag for the exact version; source READMEs
  and canonical documentation may be newer than a published registry page.
