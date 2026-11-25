# Net::Async::Crawl4AI

Async `IO::Async` client for [Crawl4AI](https://github.com/unclecode/crawl4ai). A
single class, `Net::Async::Crawl4AI` (`parent IO::Async::Notifier`), wraps a
`WWW::Crawl4AI` orchestrator, dispatches its request builders through
`Net::Async::HTTP`, and returns `Future`s throughout — including a fully async run
of the **same visible strategy chain** the sync client uses. Sister of the
synchronous `WWW::Crawl4AI` (`../p5-www-crawl4ai`, its own team + board): the pure
building blocks are reused from there, never forked.

## Build / test

```bash
prove -l t/    # full suite, no live server (the HTTP layer is mocked end to end)
dzil test      # full distribution ([@Author::GETTY] bundle)
dzil build
ex/live_example.pl   # the only thing that hits a real Crawl4AI server
```

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
the delegation lock and the publish gate are shared house rules (skilletor bundle
`getty-cpan-dist@getty`); lanes and hazards are in `.claude/rules/net-async-crawl4ai-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `net-async-crawl4ai-worker` (default) |
| Write/extend tests | `net-async-crawl4ai-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `net-async-crawl4ai-release-manager` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. The async strategy chain, Future contracts,
retry/poll dispatch, deep_crawl concurrency and action endpoints live in skill
`net-async-crawl4ai-core` (`.claude/skills/`, tracked — the repo's own skill). The shared
skills beside it are installed by skilletor from `.claude/skilletor.json` (gitignored build
artifacts — edit them in their source repo, then `skilletor sync`). General Perl / Dist::Zilla / style
conventions are in `getty-perl-core`. The delegation lock is a shared house rule (bundle
`getty-cpan-dist@getty`); repo-specific house rules: `.claude/rules/net-async-crawl4ai-rules.md`.

## Coordination

Issues and PRDs live on the **karr** board (git-native kanban, `refs/karr/*`) — run
`karr board`, not TODO comments or the domain docs under `docs/agents/`. Work that
belongs to the sync `WWW::Crawl4AI` is a ticket on that repo's board, never a direct
edit. Domain model: `CONTEXT.md` + `docs/adr/`.
