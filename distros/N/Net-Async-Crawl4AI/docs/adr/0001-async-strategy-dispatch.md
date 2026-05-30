# Async strategy chain via Future-based dispatch

`Net::Async::Crawl4AI` wraps `WWW::Crawl4AI` as an `IO::Async::Notifier`. The
strategy chain runs via `_run_strategy_future` which dispatches each strategy
through `Net::Async::HTTP` and returns a `Future`. The shared `_attempt_for`
from the underlying WWW::Crawl4AI builds identical Attempt objects — the async
and sync paths produce the same Result shape.

The `crawl` / `markdown` methods use `Future::Utils::repeat` to walk the chain
serially (one strategy at a time) but each resolution is non-blocking. The
`deep_crawl` method uses `fmap_void` with a `concurrent` knob to crawl each
frontier level in parallel.

Retry policy (backoff, max_attempts, retry_statuses, on_retry callback) lives
on the underlying `WWW::Crawl4AI::Client` and is applied in `_do_request_with_retry`
before the request hits the HTTP layer.