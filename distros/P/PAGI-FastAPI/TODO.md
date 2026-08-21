# TODO - Features requiring actual core changes

These three Python-FastAPI-parity gaps were investigated alongside the five
modules in this companion package and found to be genuinely **not**
implementable from userland - each has a specific, verified blocker inside
`PAGI::FastAPI` core itself. Documenting them here rather than attempting a
workaround that would be fragile or misleading.

## 1. File uploads / `multipart/form-data`

**Blocker (verified by reading `PAGI/FastAPI.pm`'s body-parsing code
directly):** for any request body whose `Content-Type` isn't
`application/x-www-form-urlencoded`, core unconditionally attempts
`decode_json($raw_body)` and hard-rejects with a `422` if that fails -
**before any dependency or handler runs.** A multipart body will always fail
`decode_json`, so the raw bytes never reach user code at all. There is no
extension point downstream of this that could recover them.

**What core would need:** skip the JSON-decode attempt for content types
the framework doesn't recognize (or explicitly detect
`multipart/form-data`), and expose the raw body/boundary-parsed parts to
handlers and dependencies - likely a new `$c->form_data` /
`$c->uploaded_files` accessor, mirroring how `$c->body` already works for
JSON.

## 2. Per-route OpenAPI metadata (`tags`, `summary`, `description`,
   `deprecated`, custom status-code docs)

**Blocker (verified by reading the request-dispatch entry point):**
`/docs` and `/openapi.json` are intercepted unconditionally at the very top
of the dispatcher, before the app's own registered routes are even matched
- a user cannot register a route at either path to override them. The
OpenAPI generator itself also hardcodes `summary => "$method $path"` and
only documents `200`/`422` responses, with no per-route options consumed
for anything else.

**What core would need:** accept `tags`, `summary`, `description`,
`deprecated`, and a `responses => {...}` map as recognized keys in
`_register_route`'s `%opts`, and thread them into the `$route_doc` hash
that already gets built for each route (the plumbing to attach it to
`$openapi->{paths}` already exists - it's specifically the *route options*
and *hardcoded summary* that would need to change).

## 3. `BackgroundTasks` (fire-and-forget work queued after the response is sent)

**Not strictly blocked, but not a clean fit either.** Unlike #1 and #2,
there's no single hard blocker - in principle a handler could spawn an
unawaited `Future` via the underlying event loop (reachable through
`$c->pagi_context`) and let it run after returning. What makes this not a
"just build it in userland" item, unlike the five modules above: getting
`Future` retention right (an unawaited `Future` can be garbage-collected or
cancelled before completion if it isn't explicitly retained by the loop)
is a subtle, easy-to-get-wrong pattern to hand to users as a companion
module, and doing it *safely* really wants a first-class, tested primitive
inside the framework itself - e.g. `$c->background(async sub {...})` that
core owns the retention lifecycle for, the same way it owns the request
lifecycle. A companion-package attempt at this was deliberately not
included here for that reason, rather than ship something that "usually
works."

---

If/when any of these move up the priority list, #1 and #2 are the more
mechanical (and more valuable) ones to tackle first - both are narrow,
well-understood changes to existing code paths in `PAGI::FastAPI.pm`, not
new subsystems.
