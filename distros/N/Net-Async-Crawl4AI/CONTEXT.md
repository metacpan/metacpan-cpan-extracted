# Net::Async::Crawl4AI

## Language

Inherits from `WWW::Crawl4AI`: **Strategy Chain**, **Strategy**, **Classification**, **Attempt**, **Result**, **DeepCrawl**, **Error**, **Action Endpoints** — all defined in the WWW::Crawl4AI CONTEXT.md.

Async-specific terms:

**Future Contract**: Every endpoint method returns a `Future`. `crawl`/`markdown` never fail for per-strategy errors — failed strategy = Attempt in history, all-failed = Result with `ok == 0`. `transport`/`api` errors fail the Future directly with `WWW::Crawl4AI::Error`. `content` errors end up in the Result, not in the Future.

**Retry Policy**: `max_attempts`, `retry_backoff`, `retry_statuses`, `on_retry` live on the underlying `WWW::Crawl4AI::Client`. Net::Async::Crawl4AI shares this policy via `_do_request_with_retry`.

**Concurrency Knob**: `deep_crawl` crawls each depth level concurrently. Default 4, adjustable via `concurrency => N`. Async-only parameter — sync WWW::Crawl4AI has no equivalent.

**delay_sub**: Test hook. Replaces `loop->delay_future`. Allows isolated tests of the retry/polling logic without real timeouts.

**poll_interval**: Seconds between job_status polls. Default 2. Overridable per call via `crawl_job_and_wait($url, poll_interval => 5)`.

## Relationships

- `Net::Async::Crawl4AI` wraps a `WWW::Crawl4AI` via the `crawl4ai` attribute
- `crawl()` / `markdown()` use `_run_strategy_future` for async dispatch
- `crawl_once` via `_parsed` dispatch → Future
- `deep_crawl` uses `Future::Utils::fmap_void` for concurrent frontier crawling
- `_poll_job` via `Future::Utils::repeat` for the polling loop

## Example dialogue

> **Dev:** "I call `deep_crawl` and get a failed Future — what happened?"
> **Docs:** "`deep_crawl` only fails on real problems — no Crawl4AI reachable or an async job error. If a single page has `ok == 0`, it is returned in the result array, not as a failed Future. Look into `result->attempts` to see which strategy failed and why."

> **Dev:** "Can I change the retry backoff?"
> **Docs:** "Not at runtime — the policy is configured on the underlying WWW::Crawl4AI::Client. Override `client` with your own instance that has `max_attempts` / `retry_backoff` set."