# Net-Async-Crawl4AI House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

IO::Async Crawl4AI client with an async strategy chain. Read first: the target method, the
retry loop (`_do_request_with_retry`) and how `$self->crawl4ai` / `$self->client` are used —
a change that forks the sync building blocks diverges the Result.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `net-async-crawl4ai-worker` (default) |
| Write/extend tests | `net-async-crawl4ai-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `net-async-crawl4ai-release-manager` |
| Read-only research, audit, gap analysis | `net-async-crawl4ai-worker` ("read-only, change nothing") |

Behavior-relevant = runtime behavior, the public Future interface
(crawl/markdown/deep_crawl/crawl_once/md/job_*/action endpoints), the retry and poll dispatch,
the strategy-chain walk, error classification and tests. Pure prose docs and Changes notes
are not. An unbriefed hand inside `lib/` breaks exactly the invariants the agents must hold.

## Release

This family releases together (`WWW::Crawl4AI` + `Net::Async::Crawl4AI`); a dep pin ahead of
CPAN is never a blocker either.

## Hazards

- **The sister repo owns the sync side.** Work that belongs to `WWW::Crawl4AI` is a ticket on
  **that** repo's board (`cd ../p5-www-crawl4ai`), never a direct edit.
- **The sync building blocks are shared, not forked.** Request building, page normalization,
  classification, `Result`/`Attempt` history all come from `WWW::Crawl4AI` via
  `$self->crawl4ai`/`$self->client`; the async path must produce the *same*
  `WWW::Crawl4AI::Result` as the sync facade. Downstream apps consume the ASYNC client at runtime,
  so any header/backend exposure that regresses here breaks a real consumer — mirror the sync
  path and lock it with a test (see the response_headers ticket).
- **`!ok` Result is data, not a failed Future.** `crawl`/`markdown`/`deep_crawl` succeed even
  when every strategy fails — the failure lives in the attempt history and `ok => 0`. Only
  transport/api/job errors fail the Future. Code (and tests) that treat a `!ok` Result as an
  exception are wrong.
- **One retry policy, mirrored.** Backoff/max_attempts/retry_statuses live on the underlying
  `WWW::Crawl4AI::Client`; the async side re-applies them in `_do_request_with_retry`. Don't
  add a second retry layer on top of built-in retries.
- **`$loop->add($crawler)` before use.** It's a Notifier — without a loop the internal
  `Net::Async::HTTP` never resolves and Futures hang. Tests add to an `IO::Async::Loop` and
  pass `delay_sub => sub { Future->done }` to skip real timeouts.

## Perl specifics — reference, don't restate

The async strategy chain, Future contracts, retry/poll dispatch, deep_crawl concurrency and
action endpoints live in skill `net-async-crawl4ai-core`; chain semantics and the sync client
in `perl-www-crawl4ai`; Future lifetime rules in `perl-io-async-future`; the
`IO::Async::Notifier` pattern and house style in `getty-perl-core`; Moo value objects in
`getty-perl-moo`; releases in `perl-release-dist-ini`.
