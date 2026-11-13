# The Review Helper HTTP API, standard version 1

The HTTP API the review page (`ux/`) relies on. A backend that serves one
review file over these routes, with the access rules below, runs the page
unchanged, whatever language it is written in. The page is part of the
standard: a backend serves it as shipped.

The standard has three parts, versioned as a whole: the review file
format ([FORMAT.md](FORMAT.md)), the command line the agent skills use
([CLI.md](CLI.md)), and this API. A backend reports the version it
implements as `standard_version` in `GET /api/review`, and the command line
reports it from `version`. When the version changes is in
[CLI.md](CLI.md), "The standard's version".

## Conventions

- One server serves one review file. Routes are relative to the server's
  root; the page addresses them relatively (`api/review`, `static/js/app.js`).
- Request and response bodies are UTF-8 JSON, sent as
  `application/json; charset=utf-8`.
- Field names and values are those of the review file: a field named after a
  column means what that column means in [FORMAT.md](FORMAT.md), "The
  review database", and ranges, revisions, timestamps and paths follow its
  conventions. JSON-text columns (ranges, guide targets) are sent as JSON
  values, not strings.
- Ids, counts, line numbers, positions, timestamps, iteration numbers and
  `standard_version` are JSON numbers; `available`, `pending`, `resolution`
  and `binary` are JSON booleans; a value the review file holds as NULL is
  JSON `null`. Integer columns holding 0 or 1 (a section's `deleted`) stay
  numbers.
- `REV` is a full revision id; `ID` is a row id from the review file.
- An error is an HTTP status with `{"error": "<message for a person>"}`:
  400 for bad input, 403 when refused, 404 for an unknown route, id or file,
  415 for a POST without a JSON body, 500 for an internal error. The page
  shows the message. A request the access layer does not admit gets 401
  with a `text/plain` page instead ("Access").

## Access

Access is a layer in front of every route. The standard fixes what the page
needs from it and leaves how requests are admitted to the backend, so a
local server and a hosted one with user accounts can both run the page.

Required of every access layer:

- The page sends no credentials of its own: no `Authorization` header, no
  token in its API calls. A layer admits a request by what the browser sends
  anyway (its address, cookies, a client certificate) or by a sign-in that
  ends with such a cookie.
- A request that is not admitted gets 401 with a short `text/plain` page
  telling the person how to get in.
- Every admitted request has a **reviewer**: a name the server records on
  the feedback, requests and seen marks that request writes, and reports in
  `identity.reviewer`.
- POST bodies must have `Content-Type: application/json` (415 otherwise),
  and an `Origin` header, when present, must be the server's own origin
  (403 otherwise). A form on another site cannot send a JSON body without a
  CORS preflight, which the server never grants.
- Reviewed content is untrusted: `GET /api/content` responses carry
  `Content-Security-Policy: sandbox` and `X-Content-Type-Options: nosniff`.

### The local access layer

The layer a backend serving a review on the reviewer's own machine uses.

- **Host check.** Every request's `Host` must name `127.0.0.1`,
  `localhost`, `[::1]` or a host name the server was told to allow (any port,
  any case, an IPv6 address in any spelling); anything else gets 403. This
  keeps DNS-rebinding pages out.
- **No token.** The server listens on loopback only and admits every
  request.
- **A token.** The server listens beyond loopback and prints a URL ending in
  `?token=TOKEN`. A loopback client is admitted without it. Any other client
  needs it: a request carrying `?token=TOKEN` is answered with 303 to `/`
  (whatever its path and query), setting the cookie `rh_token_PORT=TOKEN`
  (`HttpOnly`, `SameSite=Lax`, `Path=/`, where PORT is the server's port, so
  servers on different ports keep separate cookies); later requests carry
  the cookie. Tokens are compared in constant time.
- **The reviewer** is the server's one reviewer: as given at start-up, else
  `REVIEW_HELPER_REVIEWER`, else the VCS user's name and email, else the
  login name, else `unknown`.
- **Error details.** A 500 shows its details to loopback clients only.

## Routes

### Page

- `GET /` — the page, `ux/html/index.html`.
- `GET /static/PATH` — a file under `ux/css/`, `ux/js/` or `ux/html/`,
  with a content type by extension; nothing else under `ux/` (its tests and
  agent notes) is served. A path with an empty, `.` or `..` segment, a NUL
  or a backslash, or that names a directory, gets 404.

### `GET /api/review`

The review and one iteration. `?iteration=N` picks the iteration (default:
the latest; 400 for a bad number, 404 for an unknown one).

    {
      "standard_version": 1,
      "review": { "id": "...", "title": "...", "source": "<URL or null>", "state": "open" },
      "identity": { "user": "<login>", "host": "<host name>", "repo": "<repository root>",
                    "reviewer": "Ann <ann@example.com>" },
      "iteration": 2,
      "iterations": [ { "number": 1, "base": "<REV>", "head": "<REV>", "created": 1700000000,
                        "note": null, "available": true } ],
      "summary": { "what": "...", "why": "...", "how": "..." },
      "commits": [ { ...commit } ],
      "flags": [ { ...flag } ],
      "guide": [ { "position": 1, "target": { ... }, "highlight": [ ... ], "commentary": "..." } ],
      "journal": [ { "id": 1, "kind": "note", "path": "lib/Foo.pm", "unit": null,
                     "sentence": "...", "detail": null, "created": 1700000000 } ],
      "content_kinds": { "<REV>:<path>": "perl" },
      "feedback": [ ... ],
      "requests": [ ... ]
    }

- `identity` says whose review this is, so a reader who opened someone
  else's port can tell. A hosted backend may leave `user`, `host` and `repo`
  null.
- `iterations` lists every iteration; `available` is false when its head is
  not in the repository.
- A **commit** has `id`, `revision`, `parent`, `position`, `merge_id`,
  `topic` (null outside a squashed iteration split into topics), `subject`,
  `message`, `author`, `authored`, `what`, `why`, `how`, `order_set`,
  `resolution` (true for a merge with conflict resolutions or other changes
  made in the merge) and `files`.
- A **file** has `id`, `path`, `old_path`, `status`, `kind`, `size_unit`,
  `size_before`, `size_after`, `added`, `removed`, `changed`,
  `read_position`, `split_source`, `what`, `object_system`, `paradigms` and
  `section_names`: `{name, package}` of each section the page shows (those
  the commit changed, "touched" in [FORMAT.md](FORMAT.md)).
- A **flag** has `id`, `note_id`, `commit` (its revision), `entry` (the id of
  the commit entry it is on; topics of a squashed iteration share one
  revision), `path`, `line_start`, `line_end`, `color`, `color_reason`,
  `kind`, `sentence`, `detail`, `pending` (true while the agent has still to
  decide on a flag carried onto changed code) and `seen`: the reviewers who
  have seen it, `[{reviewer, at}]`, oldest first.
- `guide` is the iteration's guide; targets and highlights are as in
  [FORMAT.md](FORMAT.md), "Guide JSON".
- `journal` is the iteration's journal, oldest first.
- `content_kinds` gives, for each file the page may show whole at a commit
  that did not change it (a flag's, a `view` guide step's), the kind a file
  change would get; `binary` for content with a NUL byte in its first 8000
  bytes; null when the file is not at that commit; `text` when it cannot be
  read.
- `feedback` and `requests` are the entries of the feedback export
  ([FORMAT.md](FORMAT.md), "Feedback export") from every iteration, whichever
  is selected.

### `GET /api/file/ID`

A file change and the sections its commit changed.

    { "file": { ...file, without section_names }, "commit": "<REV>", "parent": "<REV or null>",
      "sections": [ { "id": 4, "position": 1, "name": "sub bar", "package": "Foo", "deleted": 0,
                      "added": 2, "removed": 1, "changed": 1, "what": "...",
                      "ranges": [[10, 20]], "doc_ranges": [], "old_ranges": [[10, 19]],
                      "doc_html": "<p>...</p>" } ] }

`doc_html` is optional: a backend may render a section's documentation for
reading beside its summary (Perl's POD, for one). It must be safe to insert
into the page: no raw HTML from the reviewed file, no links that leave the
page, no element ids. 404 for an unknown file.

### `GET /api/diff/ID`

The file change's diff, `{"binary": false, "hunks": [hunk]}`. A hunk is
`{old_start, old_count, new_start, new_count, lines}`; a line is
`{type, text, old, new}` with `type` one of `" "`, `"-"`, `"+"` and `old`
and `new` its line numbers, null on the side it does not exist. The diff
follows [FORMAT.md](FORMAT.md), "Diff convention". An empty diff (a rename
or mode change alone) has no hunks.

`?section=ID` gives that section's diff instead: every line of its `ranges`
and `doc_ranges`, unchanged ones as context, with its added and removed
lines, in file order. Each unbroken run of code or of documentation is a
hunk with a `part` of `code` or `docs`; lines between runs do not appear. A
section with no added or removed line has no hunks. 400 for a bad section
id, 404 for a section not in the file.

### `GET /api/resolution/ID`

A merge's conflict resolutions and other changes made in the merge:
`{"commit": "<REV>", "files": [{path, old_path, status, binary, hunks}]}`,
hunks as in `/api/diff`, within the iteration's path specs. ID is a commit
entry id; 404 when it is unknown, not in the repository, or not a merge. A
clean merge has no files.

### `GET /api/content/REV/PATH`

A file's raw bytes at a revision: an image content type by extension
(`gif`, `ico`, `jpeg`, `jpg`, `png`, `svg`, `webp`), else
`text/plain; charset=utf-8`, or `application/octet-stream` when a NUL byte
is in its first 8000 bytes. 404 for an unsafe path (as for `/static`) or a
file not at that revision. Content fetches name a revision and a path, never
a location on disk, so a backend without a checkout can serve them.

### `GET /api/feedback`

The feedback export ([FORMAT.md](FORMAT.md), "Feedback export"), as
`feedback FILE` prints it.

### `POST /api/feedback`

Add feedback. Body:

    { "iteration": 2, "target": "line", "commit": "<REV>", "topic": null, "path": "lib/Foo.pm",
      "section": { "name": "sub bar", "package": "Foo" }, "line": 42, "side": "new", "body": "..." }

- `iteration` is optional (default: the latest).
- `target` is one of `review`, `commit`, `file`, `section`, `line`, `flag`.
- `review` needs nothing more. The others need `commit`, a revision in the
  iteration. In a squashed iteration split into topics, a `commit` target
  names its `topic` (null for the files not yet in a topic); otherwise
  `topic` is omitted or null.
- `file`, `section` and `line` need `path`, a file the commit changed (in a
  topic split, the topic holding it). `section` needs `section`, a section
  the commit changed; `line` may name one too.
- `line` needs `line`, a positive integer, and `side`, `old` or `new`.
- A `flag` target gives only `flag`, the note id of a flag of the iteration;
  the server stores the flag's sentence, commit and path (and topic, for a
  whole-commit flag) with it, and marks the flag seen by the reviewer.
- `body` is required text.

Returns `{"id": ID}`; 400 for bad input. The feedback records the reviewer.

### `POST /api/feedback/ID`

Edit feedback: `{"body": "...", "status": "addressed"}`, either or both;
`status` is one of `open`, `addressed`, `declined`. Only the reviewer who
wrote it may edit it, or anyone when it has no reviewer (403 otherwise).
Returns `{}`; 404 for an unknown id. There is no route to delete feedback or
to edit a request.

### `POST /api/request`

Add a request: `{iteration, kind, target, commit, topic, path, section,
note}`. `kind` is `debate` or `split`; `target` one of `review`, `commit`,
`file`, `section`, anchored as for feedback. A `split` must target a file
the fill sheet gives a split item: a text file its commit added or changed a
line of (400 otherwise). `note` is optional text. Returns `{"id": ID}`.

### `POST /api/flag/ID`

`{"seen": true}` or `false`: set or remove the reviewer's seen mark on the
flag (a mark already there keeps its time). Returns `{"seen": [{reviewer,
at}]}` as in `/api/review`; 404 for an unknown flag.

### `POST /api/close`

Close the review, as `close FILE` does. Returns `{}`.

## Extensions

A backend may add routes of its own. The standard never defines a route
under `/api/x-<impl>/`, where `<impl>` is the implementation's name as in
`review-helper-<impl>` ([CLI.md](CLI.md)); a route added anywhere else may
collide with one a later version of the standard defines. Likewise a
backend may add fields to responses and request bodies: the standard never
defines a field starting `x_<impl>_`, anything else may collide with a later
version, and the page ignores response fields it does not know.
