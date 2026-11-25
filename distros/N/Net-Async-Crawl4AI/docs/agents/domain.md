# Domain Docs

How the engineering skills should read this repo's domain docs when they
explore the code.

## Read before exploring

- **`CONTEXT.md`** at the repo root — the glossary / the domain language.
- **`docs/adr/`** — the ADRs that touch the area currently being worked on.

This is a **single-context** repo: one `CONTEXT.md` plus `docs/adr/` at the root.

If one of these files does not exist, **proceed silently**. Do not report its absence
and do not suggest creating it up front. The producer skills only create
them once terms or decisions actually get fixed.

## File structure

```
/
├── CONTEXT.md
├── docs/adr/
│   ├── 0001-….md
│   └── 0002-….md
└── lib/
```

## Use the glossary vocabulary

When the output names a domain concept (issue title, refactor proposal,
hypothesis, test name), use the term defined in `CONTEXT.md`. Do not drift to
synonyms the glossary deliberately avoids.

## Async-specific domain

`Net::Async::Crawl4AI` inherits the domain language of `WWW::Crawl4AI` — the terms
Strategy Chain, Attempt, Result, Classification, DeepCrawl apply here just the same.
The async sphere adds: Future contract, retry policy, concurrency knob,
delay_sub (test hook), poll_interval (job polling).

## Report ADR conflicts

If the output contradicts an existing ADR, call that out explicitly instead of
silently passing over it.