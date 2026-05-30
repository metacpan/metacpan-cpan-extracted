# Net::Async::Crawl4AI

## Language

Erbt von `WWW::Crawl4AI`: **Strategy Chain**, **Strategy**, **Classification**, **Attempt**, **Result**, **DeepCrawl**, **Error**, **Action Endpoints** — alle definiert in der WWW::Crawl4AI CONTEXT.md.

Async-spezifische Begriffe:

**Future Contract**: Jede Endpoint-Methode gibt ein `Future` zurück. `crawl`/`markdown` lösen nie für per-strategy Fehler — failed strategy = Attempt in history, all-failed = Result mit `ok == 0`. `transport`/`api` Errors failed die Future direkt mit `WWW::Crawl4AI::Error`. `content` Errors landen im Result, nicht in der Future.

**Retry Policy**: `max_attempts`, `retry_backoff`, `retry_statuses`, `on_retry` leben auf dem unterljegenden `WWW::Crawl4AI::Client`. Net::Async::Crawl4AI teilt diese Policy via `_do_request_with_retry`.

**Concurrency Knob**: `deep_crawl` crawlt jede depth level concurrent. Default 4, einstellbar via `concurrency => N`. Async-only Parameter — sync WWW::Crawl4AI hat kein Equivalent.

**delay_sub**: Test-Hook. Ersetzt `loop->delay_future`. Ermöglicht isolierte Tests der retry/polling Logik ohne echte Timeouts.

**poll_interval**: Sekunden zwischen job_status polls. Default 2. Per-call überschreibbar via `crawl_job_and_wait($url, poll_interval => 5)`.

## Relationships

- `Net::Async::Crawl4AI` wrappt ein `WWW::Crawl4AI` via `crawl4ai` attribute
- `crawl()` / `markdown()` nutzen `_run_strategy_future` für async dispatch
- `crawl_once` via `_parsed` dispatch → Future
- `deep_crawl` nutzt `Future::Utils::fmap_void` für concurrent frontier crawling
- `_poll_job` via `Future::Utils::repeat` für polling loop

## Example dialogue

> **Dev:** "Ich rufe `deep_crawl` auf und kriege eine Failed Future — was ist passiert?"
> **Docs:** "`deep_crawl` failed nur bei echten Problemen — kein Crawl4AI erreichbar oder async Job Fehler. Wenn eine einzelne Seite `ok == 0` hat, wird sie im Result-array zurückgegeben, nicht als Failed Future. Schau ins `result->attempts` um zu sehen welche Strategie fehlgeschlagen hat und warum."

> **Dev:** "Kann ich den retry backoff ändern?"
> **Docs:** "Nicht zur Laufzeit — die Policy ist auf dem unterljegenden WWW::Crawl4AI::Client konfiguriert. Override `client` mit deiner eigenen Instance die `max_attempts` / `retry_backoff` gesetzt hat."