# Sweep: whole repo, after the checksum URL change (2026-10-22)

What this code does: a Mojolicious plugin. A template helper writes a `<script>` tag for a component; a route serves
that script with a rendered template spliced in. The tag's URL carries a checksum of the served script so browsers can
cache it. Load assumed: a web app with many users at once, each page view calling the helper for a handful of
components. Read: `lib/Mojolicious/Plugin/WebComponent.pm` end to end, `t/`, `cpanfile`, `Build.PL`, `META.json`,
`Changes`, the CI workflow, ADR 0001. Ran: `prove -lr t`, the guard-it scanner, and four small scripts against the
plugin (quote injection through request parameters, layout use, repeated parameters, reverse-proxy base paths). Not
read: the browser harness fixtures in `t/browser/public`, the older audit report.

## Findings

### Must
None. The earlier Must items (path traversal, script injection, the lazy route, unstable URLs) are fixed and tested.
One thing was tried and held: a request parameter containing `'` cannot break out of the tag, because
`Mojo::Parameters` encodes it as `%27`.

### Should
1. **The proxy base path and `requestId` go into the tag unescaped** (`WebComponent.pm:157-158`, `:173`, `:181-184`)
   - **What this is:** Behind a reverse proxy the app is told its path prefix, often from a request header (the
     Mojolicious cookbook shows `X-Forwarded-Path`). The helper puts that prefix, and the `requestId` option, straight
     into `<script src='...'>`.
   - **Problem:** A prefix containing `'` ends the attribute. With a header such as `/x'onload='alert(1)` the tag
     gets an `onload` handler. If a shared cache stores the page without keying on that header, every visitor gets
     the poisoned page. I ran base paths `/prefix`, `/prefix/` and `/a b` and all three were written as given.
   - **Fix:** Escape the finished `$path` for an attribute (`xml_escape`), and percent-encode `requestId`.
   - **If we skip it:** Safe only while the prefix comes from trusted config; the 0.07 reverse-proxy support makes the
     header case common.
   - **Test:** TR-1.

### Nice
2. **A prefix ending in `/` gives `//component/...`** (`WebComponent.pm:157-158`). Run: base `/prefix/` gave
   `/prefix//component/<checksum>/my-component.js`. Fix: strip a trailing slash from the prefix.
3. **Personalised templates are cached as `public`** (`:58`). A template that prints session data matches its own
   checksum, so the response is `public, immutable`. A shared cache that stores it would hold one user's page under
   a URL only that user's page contains, so exposure needs the URL. Fix: document it, or send `private` when the
   template reads the session. ADR 0001 notes the mismatch case but not this one.
4. **A missing or misspelled script leaves no log line** (`:167-177`): the tag points at
   `/component/unavailable/<name>.js` and the fetch gives 404. A render error does log. Fix: log at debug level when
   `_content` returns undef.
5. **Test gaps, no test would fail if these broke:** the duplicate-registration return with a custom helper name
   (`:29-31`); a script that is not valid UTF-8 (`:80`); a `helper` name that is not a word (`:27`, unvalidated).
   Tests: TR-2, TR-3.
6. **Metadata drift until release:** `Build.PL` says `use 5.008_001` and `META.json` says `"Mojolicious": "0"`, while
   the module and `cpanfile` need Perl 5.20 and Mojolicious 9.27. Minilla regenerates both at release.
7. **A template is looked up on disk on every script request** (`_templateExists`, `:105-111`, one stat per handler).
   Fine at this load because browsers now cache the script; note it if the route sees heavy traffic.

0 smaller findings left out.

## Not confirmed
- A layout or `content_for` block being broken by the helper's render inside a page: my script's layout was not
  applied even without a component, so the test said nothing. `t/register.t` covers a component inside a layout.

## Test recommendations

| ID | Target | Level | Why | Effort |
|----|--------|-------|-----|--------|
| TR-1 | Base path with `'`, a trailing `/`, and `requestId` with `'` or `/` | integration (`Test::Mojo`, `before_dispatch` hook) | Finding 1 and 2 have no test | S |
| TR-2 | Duplicate registration with a custom helper name | integration | Finding 5 | S |
| TR-3 | Script that is not valid UTF-8 returns 500 | integration | Finding 5 | S |

## Shortcut ledger

No `shortcut:` markers in the repo.

## Architecture notes

- `WebComponent.pm` is one module with a small public surface (`register`, one helper, one route) over the route,
  the checksum and the injection. The deletion test moves nothing out of it. Nothing worth `/deepen-it`.

Verdict: healthy. Fix 1 before relying on header-driven reverse-proxy prefixes.
Lean: -0 lines, -0 dependencies possible.
Not checked: Perl 5.20 to 5.36 (CI covers them), Firefox and WebKit, hypnotoad, a layout with `content_for` around the
helper, a real CDN or proxy in front of the app.
