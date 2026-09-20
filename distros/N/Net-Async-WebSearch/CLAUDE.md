# CLAUDE.md — Net::Async::WebSearch

IO::Async-based multi-provider web-search aggregator. One query fans out in parallel to
DuckDuckGo, SearxNG, Brave, Serper, Google CSE, Yandex, Reddit, Tavily, Exa, Marginalia and
Mojeek, is deduplicated by normalized URL, and merged via Reciprocal Rank Fusion. Every provider is a strategy object
over one shared `Net::Async::HTTP`; the orchestrator (`lib/Net/Async/WebSearch.pm`) offers
`collect` / `stream` / `race` modes and an additive `fetch => N` body-retrieval step.

Build and test: `dzil test` (full suite, mock-driven, no network); `prove -lv t/NN-name.t`
for a single file. `t/50-live.t` hits real providers and stays skipped unless
`TEST_WEBSEARCH_LIVE=1` (plus per-provider `TEST_WEBSEARCH_*` keys) is set. Never
`dzil release` without explicit permission.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself — the
principle, the lanes and this repo's hazards are in
`.claude/rules/net-async-websearch-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug anything under `lib/` or a provider | `net-async-websearch-worker` (default) |
| Pre-release audit | `net-async-websearch-release-checker` |

The agents carry their conventions via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live under `.claude/skills/` —
`net-async-websearch-core` holds the distribution architecture (provider mesh, RRF merge,
URL dedup, add-a-provider recipe), with `perl-io-async-future`, `getty-perl-core`,
`getty-perl-release-author-getty` and `perl-release-dist-ini` alongside. Work is tracked on
the local `karr` board.
