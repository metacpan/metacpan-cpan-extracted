---
name: net-async-websearch-core
description: "Architecture and internals of the Net::Async::WebSearch distribution — the provider-strategy mesh, the collect/stream/race orchestrator, RRF merge, URL-normalized dedup, the Result contract, and the recipe for adding a provider. Load when implementing, debugging or extending anything under lib/Net/Async/WebSearch/."
---

# Net::Async::WebSearch — distribution core

`Net::Async::WebSearch` is an `IO::Async::Notifier` subclass that takes a query,
fans it out to every registered provider in parallel, and either merges, streams,
or races the results. Every public method returns a `Future`.

## Layout

- `lib/Net/Async/WebSearch.pm` — the orchestrator (~870 lines): registration,
  selection, the three search modes, RRF merge, URL normalization, fetch.
- `lib/Net/Async/WebSearch/Provider.pm` — provider base class (hand-rolled
  `bless`-based OO, **not Moo**; `strict`/`warnings`).
- `lib/Net/Async/WebSearch/Provider/*.pm` — one module per backend, each a
  subclass of the base.
- `lib/Net/Async/WebSearch/Result.pm` — the result value object / contract.
- `ex/search.pl` — example CLI; `ex/searxng/` + `docker-compose.searxng.yml` for
  a local SearxNG. `.env.example` documents the provider API-key env vars.

## The provider-strategy mesh

Providers are strategy objects registered on the orchestrator. Key mechanics, all
in the base class and `add_provider`:

- A provider's **`search($http, $query, \%opts)`** is abstract and MUST be
  implemented; it returns a `Future` of an arrayref of `Result` objects **in
  provider-native rank order**. `$http` is the orchestrator's shared
  `Net::Async::HTTP` — providers must NOT build their own HTTP pipeline.
- **One shared HTTP client** per orchestrator: lazily built in `http`, added as a
  child notifier, `max_in_flight => 0` (uncapped), `max_connections_per_host`
  seeded from `fetch_concurrency_per_target_ip` (default 5).
- **Identity & selection**: `name` defaults to the lowercased leaf package
  (`default_name`). `matches($sel)` is true when `$sel` equals the provider's
  `name`, its **class leaf**, or one of its **`tags`**. `enabled` (default 1)
  is a hard gate — a disabled provider is skipped regardless of `only`/`exclude`.
- **Stacking**: register many instances of one class (five SearxNG mirrors, two
  Serper keys). `add_provider` auto-renames a colliding name to `name#2`,
  `name#3`, … so selectors stay unambiguous. Group stacked instances with shared
  `tags` (`free`, `paid`, `private`) to select/deselect them together.
- `_select_providers` = enabled ∧ (no `only`, or matches an `only`) ∧ (matches no
  `exclude`). Per-provider options resolve **exact name > class leaf > tag**.

## Three search modes

`$ws->search(mode => ..., query => $q, ...)` returns a `Future`; the resolution
shape depends on `mode`:

- **`collect`** (default) → `Future[\%out]`. `Future->needs_all` over every
  selected provider, dedup by normalized URL, score with RRF, trim to `limit`.
  Output: `{ results => [Result…], errors => [{provider,error}…], stats => {…} }`.
  `$r->score` is set **only** here.
- **`stream`** → `Future[\%out]`. Fires `on_result => sub { $r }` as each
  provider settles, deduping on the fly via a `seen_key` hash. Resolves when every
  provider has settled; `results` is still populated. `on_fetch` fires per body
  when `fetch => N`.
- **`race`** → `Future[\%out]`. First provider to return **successfully** wins;
  only falls through to `{ errors }` when every provider fails. `only => [...]`
  restricts racers.

## RRF merge (collect)

Reciprocal Rank Fusion, keyed by normalized URL in `%agg`:

- `score += 1 / ($k + $rank)` summed across every provider that returned the URL,
  where `$k = rrf_k` (package default `$RRF_K = 60`, per-instance configurable via
  the `rrf_k` attribute / constructor). `$rank` is the provider-native rank.
- **Snippet preference**: the retained `Result` is the first seen, but is replaced
  by a later duplicate if the first had no snippet and the later one does.
- Each merged result gets `$r->score($score)` and
  `$r->extra->{providers} = { provider => rank, … }` recording every contributor.
- Sort descending by score, `splice` to `limit`.

## URL normalization / dedup

`_normalize_url` is the dedup key for all three modes:

1. `URI->new($url)->canonical` (falls back to `lc $url` if URI construction dies),
2. strip the fragment (`#…`),
3. strip trailing slashes,
4. lowercase the whole thing.

Empty/undef URLs produce an empty key and are dropped from aggregation.

## Result contract

`Net::Async::WebSearch::Result` **guarantees**: `url`, `title`, `snippet`,
`provider`, `rank`, `domain` (auto-derived from the URL host).

**Optional** (may be `undef`): `published_at`, `language` (BCP-47), `nsfw`.

**Mode/feature-specific**: `score` set only in `collect`; `fetched` set only when
`fetch => N` ran. Provider-specific extras (subreddit, sitelinks, engine name)
live in `$r->extra`; the raw upstream payload, if retained, in `$r->raw`.

## `fetch => N` — additive body retrieval

Passing `fetch => N` GETs the top N result URLs **after** ranking and attaches the
response to `$r->fetched`. Fetch is **additive, never filtering** — the full
results list is always returned; non-fetched results simply lack `$r->fetched`.
Knobs (on the instance, per-call overridable): `fetch_concurrency` (global
in-flight cap, default 100) and `fetch_concurrency_per_target_ip` (per-host cap,
default 5, wired to `max_connections_per_host` — **per-hostname, not per-resolved
IP**; the name is aspirational). `fetch_max_bytes` is enforced on the **decoded
body** in `_fetch_one` — `Net::Async::HTTP` does not cap the on-the-wire length.

## Providers

| Class (`::Provider::…`) | Auth | Transport |
|---|---|---|
| `DuckDuckGo` | none | HTML scrape (`HTML::TreeBuilder`) |
| `SearxNG` | optional Bearer | JSON (instance must enable `format=json`) |
| `Brave` | `X-Subscription-Token` | JSON |
| `Serper` | `X-API-KEY` | JSON (Google proxy) |
| `Google` | API key + `cx` | JSON, 10-result cap per call |
| `Yandex` | Cloud API key + `folderid` | XML via `XML::LibXML` |
| `Reddit` | none | JSON `/search.json` |
| `Reddit::OAuth` | OAuth2 (four grant types) | JSON vs `oauth.reddit.com` |

## Adding a provider

1. `lib/Net/Async/WebSearch/Provider/Foo.pm`, `use parent
   'Net::Async::WebSearch::Provider'`.
2. Implement `sub search { my ($self,$http,$query,$opts)=@_; … }`: build an
   `HTTP::Request`, dispatch via the **shared** `$http->do_request`, and resolve a
   `Future->done([ Result… ])` in provider-native rank order. Optionally override
   `_init` for construction-time setup.
3. Honour the `Result` contract — always a normalized-ish `url`, `title`,
   `snippet`, `provider` (your name), `rank` (1-based provider order). `domain` is
   auto-derived; don't fight it.
4. Respect `%opts` where they map (`limit`, `language`, `region`, `safesearch`)
   plus any provider-specific overrides the caller passed via `provider_opts`.
5. Test with **mocked** responses under `t/`; a live call goes no further than the
   `t/50-live.t` pattern (key-gated, normally skipped).

## Common pitfalls

- Forgetting `$loop->add($ws)` → Futures hang (it is a Notifier; children are
  added with the parent).
- Expecting `$r->score` in `stream`/`race`, or `$r->fetched` without `fetch => N`.
- Selecting by class leaf when several instances of that class exist — all match;
  use the exact `name` for one.
- SearxNG returning HTML → the instance didn't enable `format=json`.
- Google CSE `limit > 10` needs multiple API calls (10-result cap per call).
- Yandex needs `folderid` **and** a service account with role
  `search-api.executor` — missing either returns opaque auth errors.

## When NOT to load this skill

- Generic `IO::Async` / `Future` lifecycle, cancellation, retention → skill
  `perl-io-async-future`.
- Perl module/house style, dependency pinning → skill `getty-perl-core`.
- Release workflow / `dist.ini` → skills `getty-perl-release-author-getty`,
  `perl-release-dist-ini`.
