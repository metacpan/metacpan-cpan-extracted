## NAME

Mojolicious::Plugin::Buffer - Optimise, compress and validate Mojolicious responses

## VERSION

Version 0.001.0

## SYNOPSIS

### 1. The smallest set-up

One line gives every page compression, an `ETag`, a `Last-Modified`
header and `304 Not Modified` answers:

```perl
use Mojolicious::Lite;

plugin 'Buffer';

get '/' => sub {
    my $c = shift;
    $c->render(template => 'index');
};

app->start;
```

### 2. Smaller HTML

Also remove extra white space from HTML pages.  Install [HTML::Packer](https://metacpan.org/pod/HTML%3A%3APacker) to
remove comments and shrink embedded CSS as well:

```perl
plugin 'Buffer' => {optimise_content => 1};
```

### 3. A server-side cache for slow pages

Keep finished pages in a cache, so a slow action runs once and later
visitors get the stored copy.  Call the helper _first_ in the action, but
_after_ any check that decides who may see the page:

```perl
use CHI;

plugin 'Buffer' => {cache => CHI->new(driver => 'File', root_dir => '/var/cache/myapp')};

get '/report' => sub {
    my $c = shift;

    # Access checks come first: a cached page is sent without them
    return $c->reply->not_found unless $c->session('user');

    return if $c->buffer_is_cached;    # sent from the cache: stop here

    $c->render(text => slow_report());  # only runs on a miss
};
```

### 4. Several workers on one machine

With [hypnotoad](https://metacpan.org/pod/hypnotoad) there are several worker processes.  Share the cache
between them, and give them a lock directory, so only one worker builds a
missing page:

```perl
plugin 'Buffer' => {
    cache          => CHI->new(driver => 'File', root_dir => '/var/cache/myapp'),
    cache_lock_dir => '/var/lib/myapp/buffer-locks',
};
```

For workers on several machines, see ["Multiple hosts"](#multiple-hosts).

### 5. One response is different

Put a `buffer` value in the stash.  `0` leaves the response alone; a hash
changes some options for this response only:

```perl
get '/download' => sub {
    my $c = shift;
    $c->stash(buffer => 0);    # already compressed: do not touch it
    $c->render(data => $zip_file, format => 'zip');
};

get '/raw' => sub {
    my $c = shift;
    $c->stash(buffer => {optimise_content => 0});
    $c->render(template => 'raw');
};
```

### 6. A whole section is different

Some options can be set once for a group of routes:

```perl
my $docs = app->routes->under('/docs')->to(optimise_content => 1);
$docs->get('/intro' => sub { shift->render(template => 'docs/intro') });
```

### 7. Pages in several languages

Add `Accept-Language` to the cache key, so each language is stored
separately:

```perl
plugin 'Buffer' => {
    cache   => $cache,
    vary_by => ['cookie', 'accept-language'],
};
```

### 8. Translate the "busy" message

While one request builds a page, a request that waits too long gets
`503 Service Unavailable` with a short text.  Change the text with
`messages`:

```perl
plugin 'Buffer' => {
    cache    => $cache,
    messages => {retry_later => "Bitte versuchen Sie es gleich noch einmal.\n"},
};
```

### 9. A full application

```perl
package MyApp;
use Mojo::Base 'Mojolicious';
use CHI;

sub startup {
    my $self = shift;

    $self->plugin('Buffer', {
        optimise_content => 1,
        cache            => CHI->new(driver => 'File', root_dir => '/var/cache/myapp'),
        cache_lock_dir   => '/var/lib/myapp/buffer-locks',
        cache_duration   => '10 minutes',
        vary_by          => [],    # these pages are the same for everyone
    });

    $self->routes->get('/')->to('pages#home');
}

1;
```

## DESCRIPTION

`Mojolicious::Plugin::Buffer` makes the pages of a [Mojolicious](https://metacpan.org/pod/Mojolicious)
application smaller and faster to deliver, without changes to your actions.
It is the Mojolicious version of [CGI::Buffer](https://metacpan.org/pod/CGI%3A%3ABuffer) and [FCGI::Buffer](https://metacpan.org/pod/FCGI%3A%3ABuffer).

### What it does

After your action has made a page, and before the page is sent, the plugin
can:

- **make HTML smaller** by removing extra white space and, with
[HTML::Packer](https://metacpan.org/pod/HTML%3A%3APacker), comments and extra characters in embedded CSS and
JavaScript.  It also shortens links to your own site;
- **compress the page** with Brotli, Zstandard or gzip, whichever the
browser accepts and the server has installed;
- **add headers that let browsers reuse a copy they already have**
(`ETag` and `Last-Modified`), and answer "you already have this" with a
short `304 Not Modified` reply instead of the whole page;
- **set the correct `Content-Length`** after all of these changes;
- **keep finished pages in a server-side cache**, if you ask it to, so
that a slow action does not have to run again for the next visitor (see
["buffer\_is\_cached"](#buffer_is_cached)).

### How it works, in plain words

- 1. When the application starts, ["register"](#register) checks your options and
installs a _hook_: a small function that Mojolicious calls for every
response, after the action has finished (`after_dispatch`).
- 2. A request arrives and your action runs.  If the action calls
["buffer\_is\_cached"](#buffer_is_cached) and a fresh copy of the page is in the cache, the copy
is sent and the action stops early.
- 3. Otherwise the action makes the page as usual.
- 4. The hook looks at the finished response.  It leaves alone anything
it should not touch: streamed responses, static files, empty bodies,
statuses that have no body (1xx, 204, 206, 304), responses that are already
compressed, and media types listed in ["excluded\_types"](#excluded_types).
- 5. For an HTML page it removes white space, if ["optimise\_content"](#optimise_content)
is on.
- 6. It compresses the page for this browser, if the media type is in
["compressible\_types"](#compressible_types).
- 7. It stores the _uncompressed_ page in the cache, if the action
called ["buffer\_is\_cached"](#buffer_is_cached) and the page may be stored.
- 8. It adds the `ETag` and `Last-Modified` headers.  If the browser
already has this version, it sends `304 Not Modified` with no body and
stops.
- 9. Otherwise it puts the compressed (or plain) page into the
response, sets `Content-Length`, and the page is sent.

Error pages such as `404` go through the same steps, but only `200`
responses get an `ETag` or are stored in the cache.

The plugin works through a hook, so it also sees responses built with
`$c->res->body` rather than `$c->render`.  Unlike the CGI modules
it needs no source filter and no `END` block.

### Words used in this document

- cache

    A store that keeps finished pages for a while, for example [CHI](https://metacpan.org/pod/CHI).  The
    plugin needs an object with `get`, `set` and `remove` methods.

- cache key

    The name under which a page is kept in the cache.  By default it is made
    from the host, path, query string and the request headers listed in
    ["vary\_by"](#vary_by).

- ETag

    A short fingerprint of the page, sent in a header.  A browser that has a
    copy sends the fingerprint back; if it still matches, the server answers
    `304`.

- 304 Not Modified

    A reply with no body that means "the copy you have is still correct".

- content coding

    The compression method of a response, such as `gzip` or `br` (Brotli).
    The browser lists what it accepts in `Accept-Encoding`.

- worker

    One of several copies of the application that a server such as
    [hypnotoad](https://metacpan.org/pod/hypnotoad) runs at the same time.  Workers do not share memory.

- single-flight

    When many requests ask for the same missing page at once, only one of them
    builds it; the others wait and then get the result.

- stash

    Mojolicious's per-request hash of values, `$c->stash`.  The plugin
    reads its per-response options from `$c->stash('buffer')`.

## OPTIONS

All options can be given to `plugin()` and, except where noted, overridden
per request through the `buffer` stash value.  Options given to `plugin()`
are validated when the plugin is registered; values in the `buffer` stash
are not, and an unusable one falls back to its default where that is safe.
A few options describe a section of a site rather than one page and can be
declared once for it; see ["Declaring options for a group of pages"](#declaring-options-for-a-group-of-pages).

### Declaring options for a group of pages

```perl
# one route
$r->get('/about' => {optimise_content => 1} => sub {...});

# everything beneath an under route
my $docs = $r->under('/docs')->to(optimise_content => 1);
$docs->get('/intro' => sub {...});

# a controller, and through a base class its whole namespace
package MyApp::Controller::Docs;
use Mojo::Base 'Mojolicious::Controller';
has buffer_optimise_content => 1;
```

A route default is an ordinary stash value, so `$app->defaults(...)` and
a `before_action` that sets one work as well.  The controller form is a
method named `buffer_` followed by the option name, and is only consulted
when the stash says nothing: `has` is the declarative way to write it, and a
plain `sub buffer_optimise_content { 1 }` covers a value that depends on the
request.  A controller method that dies is logged at debug level and
ignored, so the plugin option stays in force.

The most specific declaration wins:

- 1. the `buffer` stash, for a single response
- 2. a route default, which includes one an `under` route sets
- 3. the controller declaration
- 4. the plugin option

A route default of `0` therefore opts one page back out of a group that has
the option on, and the `buffer` stash overrides both.

Only the options that describe the content of a section are declarable:

- ["compress\_content"](#compress_content) - a section serving files that are already
compressed
- ["optimise\_content"](#optimise_content) - a static section that is always minified
- ["rewrite\_links"](#rewrite_links) - a section whose HTML is used elsewhere, so its
absolute links must survive
- ["trust\_last\_modified"](#trust_last_modified) - a section that renders templates and nothing
else

Everything else, including ["generate\_etag"](#generate_etag) and ["generate\_304"](#generate_304), stays a
per-response or per-application decision; those sections say why.  Any option
can still be set for one response through the `buffer` stash.

`examples/grouped-sections` is a runnable site with one section declared on
an `under` route and one declared in a controller.

### compress\_content

Compress eligible responses, defaults to 1.  Set to 0 to only optimise (and
remember that the plugin turns off ["compress" in Mojolicious::Renderer](https://metacpan.org/pod/Mojolicious%3A%3ARenderer#compress), so a
response will then not be compressed at all).  The encodings offered to
clients are controlled by ["encodings"](#encodings).

It can be declared for a group of pages (see
["Declaring options for a group of pages"](#declaring-options-for-a-group-of-pages)), which is the point of a section
that serves files it has already compressed.

### optimise\_content

How hard to optimise HTML, defaults to 0 (off).  Registration rejects any
value other than 0, 1 or 2:

- 0 - leave the HTML alone
- 1 - remove superfluous white space, rewrite same-site links and, when
[HTML::Packer](https://metacpan.org/pod/HTML%3A%3APacker) is installed, remove comments and minify embedded CSS
- 2 - as 1, plus aggressive JavaScript minification when [HTML::Packer](https://metacpan.org/pod/HTML%3A%3APacker)
is installed, which can break scripts that rely on the
`<!-- ... -->` hiding technique

Optimisation only applies to `text/html` and `application/xhtml+xml`
responses.  The content of `<pre>`, `<textarea>`,
`<script>` and `<style>` elements is never touched by the
white-space squashing, because white space there is significant.
[HTML::Packer](https://metacpan.org/pod/HTML%3A%3APacker) is optional: without it the white-space squashing and link
rewriting still run, but comments and embedded CSS and JavaScript are left
alone, as they are by [CGI::Buffer](https://metacpan.org/pod/CGI%3A%3ABuffer) and [FCGI::Buffer](https://metacpan.org/pod/FCGI%3A%3ABuffer).  Install
[HTML::Packer](https://metacpan.org/pod/HTML%3A%3APacker) for the full effect.

It can be declared for a group of pages (see
["Declaring options for a group of pages"](#declaring-options-for-a-group-of-pages)), for a static section that is
always minified.

### rewrite\_links

When optimising, rewrite `<a href>` and `<img src>` links that
point at the current site as absolute URLs into root-relative links, and
links to the current script with a query string into just the query string.
Defaults to 1.  Has no effect unless ["optimise\_content"](#optimise_content) is enabled.  Only
double-quoted attribute values are recognised.

It can be declared for a group of pages (see
["Declaring options for a group of pages"](#declaring-options-for-a-group-of-pages)), which matters for a section
whose HTML is not used in place: a preview of a newsletter or a page rendered
for another site needs its absolute URLs kept while still being optimised
elsewhere.

### generate\_etag

Add an `ETag` header to `200` responses to `GET` and `HEAD` requests,
defaults to 1.  The tag is the MD5 of the response body before compression,
with a suffix for the content coding, so a gzip and an identity
representation of the same page have different tags.  An `ETag` set by the
action is kept.

It is not declarable for a group of pages (see
["Declaring options for a group of pages"](#declaring-options-for-a-group-of-pages)): whether a digest is worth
computing is a decision for one endpoint, not a policy for a section.  Skip
the digest for one response with `$c->stash(buffer => {generate_etag => 0})`, or for the whole application with the plugin option.

### generate\_304

Answer "you already have this page" with `304 Not Modified`, defaults to
1\.  A browser that has a copy of a page asks the server whether its copy is
still correct.  It can ask in two ways:

- `If-None-Match`: "my copy has this `ETag`".  This is exact,
because the `ETag` is a fingerprint of the page itself.
- `If-Modified-Since`: "my copy is from this date".  This is only a
guess, because the date (see ["last\_modified"](#last_modified)) describes your _code and
templates_, not the data shown on the page.

The plugin uses them like this:

- 1. If the request has `If-None-Match`, only the `ETag` decides.  The
date is ignored, as RFC 7232 requires.
- 2. If the page has an `ETag` (["generate\_etag"](#generate_etag) is on, the default),
`If-Modified-Since` alone is _not_ trusted.  A database row can change
while the template stays the same, and a `304` would then keep showing the
browser old data.  Browsers send `If-None-Match` once they have seen an
`ETag`, so they are not affected.
- 3. If the page has no `ETag`, or ["trust\_last\_modified"](#trust_last_modified) is on, the
date is used.

It is not declarable for a group of pages (see
["Declaring options for a group of pages"](#declaring-options-for-a-group-of-pages)).  It decides whether a browser is
told that its copy is correct, and a section that could also turn it off
would contradict ["trust\_last\_modified"](#trust_last_modified).  Use
`$c->stash(buffer => {generate_304 => 0})` where one endpoint must always
send a body.

### last\_modified

Add a `Last-Modified` header, defaults to 1.  The header says when the page
last changed.  The value may be:

- 0 - do not add the header
- 1 - the newest modification time of the application script (`$0`)
and of every file and directory under the renderer's template paths.
Symbolic links are followed, each directory is read once, and the scan
stops 32 directories below a template path, which also ends a symbolic
link that points back up the tree.
- a number - a Unix epoch (seconds since 1970)
- a date string - anything [Mojo::Date](https://metacpan.org/pod/Mojo%3A%3ADate) can read, such as
`'Sun, 06 Nov 1994 08:49:37 GMT'`
- a code reference - called with the controller; it returns one of the
values above (a code reference that returns another code reference counts
as 0)

Some rules:

- The header is only added to `200` responses to `GET` and `HEAD`.
A `Last-Modified` header that the action set itself is kept.
- With the default (1), editing a template changes the date.
(Separately, and whatever this option says, the server-side cache throws
away entries built before the newest change to the script or a template;
see ["buffer\_is\_cached"](#buffer_is_cached).)
- The date describes the _code_, not your data.  A change in the
database does not move it.  For pages built from data, use a code reference
that returns the data's own date, or set `last_modified => 0` and rely
on the `ETag` (see ["generate\_304"](#generate_304) for why that is safe).
- The default looks at every template file on every request, unless
["template\_mtime\_cache"](#template_mtime_cache) is set.  For a large template tree, or an
application without templates, an epoch or a code reference is cheaper.
A server-side cache lookup also looks at the template files, whatever this
option says; see ["Last-Modified performance"](#last-modified-performance).
- `morbo` and `hypnotoad` set `$0` to your application script.
Under PSGI or another wrapper, `$0` may be the wrapper instead; pass an
epoch or a code reference there.

### trust\_last\_modified

Also answer `If-Modified-Since` when the page has an `ETag`, defaults to 0.

By default the plugin does not trust the date when it has a fingerprint
(see ["generate\_304"](#generate_304)).  Turn this on only for pages that are built from the
application and its templates _and nothing else_: no database, no session,
no other input that can change while the templates stay the same.  Then the
date is accurate, and clients that only send `If-Modified-Since` can get a
`304` too.  `If-None-Match` still comes first, so a browser that sends the
`ETag` is always answered correctly.

```perl
plugin 'Buffer' => {
    trust_last_modified => 1,   # this application only renders templates
};
```

Use it for one response with
`$c->stash(buffer => {trust_last_modified => 1})`, or declare it for a
group of pages (see ["Declaring options for a group of pages"](#declaring-options-for-a-group-of-pages)), for a
section that renders templates and nothing else.  It has no effect when
["generate\_304"](#generate_304) is off.  It cannot make a page safe; it only tells the
plugin that the templates really are the only input.

### Last-Modified performance

The scan costs one `stat()` per file and directory under the renderer's
paths.  On a tree of 10,000 templates in 100 directories, a request using the
default scan took about 40 milliseconds of CPU on the machine used for these
measurements, against about 1 millisecond for the same request with an
explicit epoch; that is roughly 4 microseconds per tree entry.  With
["template\_mtime\_cache"](#template_mtime_cache) in front of it, the same request also took about 1
millisecond, the cache lookup adding only a few tens of microseconds, so the
middle ground gives up roughly 2% of the scan's cost to keep template
awareness.  The numbers are indicative, not a promise, and a faster or slower
filesystem will move them.  Run `benchmarks/last_modified.pl` with your own
tree size to measure all three variants.

Use an explicit epoch or a coderef when template changes do not need to move
`Last-Modified`.  This removes the scan from ordinary responses, but not
from server-side cache lookups: ["buffer\_is\_cached"](#buffer_is_cached) still scans, so that an
entry built from an old template is thrown away.  Use
["template\_mtime\_cache"](#template_mtime_cache) when you need template awareness but not a scan on
every request: it costs one cache lookup per request, covers both uses, and
bounds how long a template edit can be missed by its duration.

### template\_mtime\_cache

An optional cache object understanding `get()` and `set()`, such as a
[CHI](https://metacpan.org/pod/CHI) instance, used to remember the result of the template mtime scan.
Defaults to undef, which scans the renderer's template paths on every
request.  A per-worker cache avoids the scan without sharing anything:

```perl
use CHI;
plugin 'Buffer' => {
    template_mtime_cache => CHI->new(driver => 'Memory', datastore => {}),
};
```

A shared cache, such as CHI's File or Memcached driver, also avoids the scan
for every worker.  Entries are keyed by the application class, the
application script and its mtime, and the renderer's template paths, and are
stored with ["template\_mtime\_cache\_duration"](#template_mtime_cache_duration).  A cache failure is logged at
debug level and the scan runs as usual, so a broken cache cannot stop a
response.

For a large tree this is the middle ground: it avoids the per-request scan
described under ["Last-Modified performance"](#last-modified-performance) while still noticing template
changes, at the cost of up to one duration of staleness.

The cached value is only refreshed when the entry expires.  A template edit
therefore is not noticed until then, and neither `Last-Modified` nor the
cache invalidation described under ["last\_modified"](#last_modified) sees it immediately.
Keep ["template\_mtime\_cache\_duration"](#template_mtime_cache_duration) short if templates change often.

This option and ["template\_mtime\_cache\_duration"](#template_mtime_cache_duration) are read when the plugin is
registered; they cannot be overridden through the `buffer` stash.

### template\_mtime\_cache\_duration

How long a template mtime is kept, defaults to 10 seconds.  It is passed to
the cache's `set()`, so for [CHI](https://metacpan.org/pod/CHI) it may be a number of seconds or a
human-readable duration.

### min\_compress\_size

Do not compress bodies smaller than this many bytes, defaults to 32.  Must be
a non-negative integer.  Compression is also skipped if it would not make the
body smaller.

### encodings

An arrayref of the content codings to offer, in server preference order.
Defaults to `[qw(br zstd gzip)]`.  `br` is only offered if
[IO::Compress::Brotli](https://metacpan.org/pod/IO%3A%3ACompress%3A%3ABrotli) is installed and `zstd` only if [Compress::Zstd](https://metacpan.org/pod/Compress%3A%3AZstd)
is installed; gzip is always available.  `x-gzip` is accepted as a synonym
for `gzip`.  Clients pick with the usual quality values, and `identity` is
used when nothing acceptable is offered.

### compressible\_types

An arrayref of media types to compress, defaults to `text/*`,
`application/json`, `application/javascript`, `application/xml`,
`application/xhtml+xml`, `image/svg+xml` and a few close relatives.
Entries may be strings (matched exactly, case-insensitively) or regular
expressions.

### excluded\_types

An arrayref of media types that are never buffered, defaults to
`text/event-stream`.  Entries may be strings or regular expressions.

### cache

An optional cache object understanding `get()`, `set()` and `remove()`,
such as a [CHI](https://metacpan.org/pod/CHI) instance.  Defaults to undef, which disables the
server-side cache.  See ["buffer\_is\_cached"](#buffer_is_cached) for the rules about what is
cached and how keys are made.

### cache\_duration

How long entries are kept in the cache, defaults to `'10 minutes'`.  It is
passed to the cache's `set()`, so for [CHI](https://metacpan.org/pod/CHI) it may be a number of seconds
or a human-readable duration.

### cache\_key

A string, or a coderef called with the controller, that overrides the
generated cache key.  Useful when several URLs should share one entry, or
when the response depends on something the default key does not cover.  An
empty string, or a coderef returning nothing, falls back to the generated
key.

### cache\_single\_flight

Only let one request at a time build a missing entry, defaults to 1.  When a
request misses the cache while another request in the same worker is already
building the same key, the second request waits for the first one to finish
and is then served the finished entry, without running the action.  This
matters for asynchronous actions: a synchronous action runs to completion
without the event loop doing anything else, so it cannot overlap with
another request in the same worker.

If the first request fails, produces a response that cannot be cached (for
example one that sets a cookie), or takes longer than ["cache\_lock\_timeout"](#cache_lock_timeout),
the waiting request is answered with `503 Service Unavailable` and
`Retry-After: 1` rather than running the action itself.  Set to 0 to let
every concurrent miss run the action independently.

By default the in-flight table is per worker process, so with N [hypnotoad](https://metacpan.org/pod/hypnotoad)
workers a cold entry can still be built up to N times.  Set ["cache\_lock"](#cache_lock) or
["cache\_lock\_dir"](#cache_lock_dir) to elect a single builder across processes instead.

### cache\_lock

An optional object that elects one process to build a missing entry, for
workers that cannot share a directory.  It must implement:

- acquire

    ```perl
    my ($guard, $error) = $lock->acquire($key);
    ```

    Return a truthy guard if the lock was acquired, `(undef, undef)` if another
    process holds it, and `(undef, $error)` if the backend failed.  On an error
    the plugin logs the message and continues with a per-worker flight, so a
    cache miss is still built.  An exception thrown by `acquire` is treated as
    an error.

    The call is synchronous and runs before the action is allowed to continue.
    A backend must therefore be quick and must not depend on the event loop; an
    asynchronous Redis client is not suitable.

- release

    ```
    $lock->release($guard);
    ```

    Release a guard returned by `acquire`.  The guard is opaque to the plugin.
    Releasing a lock that has already expired is allowed.  If release fails, the
    lock should expire on its own; the backend can return `(0, $error)` so the
    failure is logged.  A backend that returns nothing is treated as having
    released the lock.

The cache itself must still be shared between the workers.  The built-in
backends are [Mojolicious::Plugin::Buffer::Lock::File](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ABuffer%3A%3ALock%3A%3AFile), selected with
["cache\_lock\_dir"](#cache_lock_dir), and [Mojolicious::Plugin::Buffer::Lock::Redis](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ABuffer%3A%3ALock%3A%3ARedis).
`cache_lock` cannot be combined with ["cache\_lock\_dir"](#cache_lock_dir), and is read when
the plugin is registered rather than per response.

### cache\_lock\_timeout

How long a request may wait for another request, in this worker or another
one, to build the same entry.  Defaults to 10 seconds.  It also bounds how
long a key is considered to be in flight when the request building it never
finishes.  Fractional seconds are allowed, so `0.5` is valid; zero and
negative values are rejected.

### cache\_lock\_dir

A directory in which to keep lock files used to coalesce cache misses across
worker processes, defaults to undef, which limits single-flight to one worker.
This selects the built-in [Mojolicious::Plugin::Buffer::Lock::File](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ABuffer%3A%3ALock%3A%3AFile) backend
and is a shorthand for `cache_lock =>
Mojolicious::Plugin::Buffer::Lock::File->new(dir => $dir)`.  The
plugin creates the directory if necessary.  It cannot be combined with
["cache\_lock"](#cache_lock).

The workers must share this directory and the cache itself.  A per-worker
cache such as CHI's `Memory` driver cannot be used, because a request in one
worker cannot see the entry built in another; disable any per-worker `L1`
cache in front of a shared cache for the same reason.  Locks are non-blocking
`flock`s on one small, empty file per cache key, so they are released
automatically if a worker dies.  The files are not removed, although they are
tiny and can be deleted while the application is stopped.  Use a private
directory.

This works for [hypnotoad](https://metacpan.org/pod/hypnotoad) workers on the same host, or on a shared
filesystem that implements `flock` reliably.  For workers on different
hosts, use ["cache\_lock"](#cache_lock) with
[Mojolicious::Plugin::Buffer::Lock::Redis](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ABuffer%3A%3ALock%3A%3ARedis) instead.  It is read when the
plugin is registered, not per response.

### vary\_by

An arrayref of request header names that become part of the generated cache
key.  Defaults to `['cookie']`, which keeps one client's session from being
served to another.  Set it to `[]` for URL-only caching of pages that are
identical for every visitor, or add e.g. `'accept-language'` when the
response varies by language.  Header names are case-insensitive.  Headers
listed here may also appear in the response's `Vary` header; a response
that varies on anything else is not stored.

### messages

A hash reference of message overrides, keyed by message key, used for every
error, log line and client-facing text the plugin produces, including the
body of the `503` sent to a request that gave up waiting.  See
[Mojolicious::Plugin::Buffer::I18N](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ABuffer%3A%3AI18N) for the keys, the placeholder syntax
and plural and gender variants:

```perl
plugin 'Buffer' => {
    messages => {
        retry_later => "Die Seite wird gerade erstellt, bitte versuchen Sie es gleich noch einmal.\n",
    },
};
```

It is passed to the lock backend built from ["cache\_lock\_dir"](#cache_lock_dir).  It is read
when the plugin is registered, not per response.

## METHODS

`Mojolicious::Plugin::Buffer` inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious%3A%3APlugin) and implements the following new ones.  It also adds
the ["buffer\_is\_cached"](#buffer_is_cached) helper to the application.

### register

```perl
$plugin->register(Mojolicious->new, {optimise_content => 1});
```

#### Purpose

Validate the options, install the `after_dispatch` hook that reworks every
response, and add the ["buffer\_is\_cached"](#buffer_is_cached) helper.  It is normally called for
you by `$app->plugin('Buffer', ...)`.

#### Arguments

- `$app` (positional, required)

    The [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

- `\%options` (positional, optional)

    The options described under ["OPTIONS"](#options), as a hash reference or a flat list.

#### Returns

The plugin object, so calls can be chained.

#### Side effects

- Turns off ["compress" in Mojolicious::Renderer](https://metacpan.org/pod/Mojolicious%3A%3ARenderer#compress), because this plugin does
the compression; see ["Interaction with the renderer"](#interaction-with-the-renderer).
- Adds an `after_dispatch` hook and a `buffer_is_cached` helper.
- Creates ["cache\_lock\_dir"](#cache_lock_dir) if it is given and missing.
- Loads the optional compression modules named by ["encodings"](#encodings), and
logs at debug level when ["optimise\_content"](#optimise_content) is on without [HTML::Packer](https://metacpan.org/pod/HTML%3A%3APacker).

#### Example

```perl
use Mojolicious::Lite;
use CHI;

plugin 'Buffer' => {
    optimise_content => 1,
    cache            => CHI->new(driver => 'File', root_dir => '/var/cache/myapp'),
    cache_lock_dir   => '/var/lib/myapp/buffer-locks',
    vary_by          => [],     # pages are the same for everyone
};

get '/' => sub {
    my $c = shift;
    return if $c->buffer_is_cached;
    $c->render(text => 'Hello');
};

app->start;
```

#### API SPECIFICATION

##### Input

```perl
# Params::Get::get_params(undef, @_) after $app, then one
# Params::Validate::Strict::validate_strict call per option
{
    app                           => { type => 'object', can => [qw(hook helper renderer log)] },
    compress_content              => { type => 'scalar', optional => 1 },
    optimise_content              => { type => 'integer', min => 0, max => 2, optional => 1 },
    rewrite_links                 => { type => 'scalar', optional => 1 },
    generate_etag                 => { type => 'scalar', optional => 1 },
    generate_304                  => { type => 'scalar', optional => 1 },
    trust_last_modified           => { type => 'scalar', optional => 1 },
    last_modified                 => [ { type => 'scalar' }, { type => 'coderef' } ],
    template_mtime_cache          => { type => 'object', can => [qw(get set)], optional => 1 },
    template_mtime_cache_duration => { type => 'string', min => 1, optional => 1 },
    min_compress_size             => { type => 'integer', min => 0 },
    encodings                     => { type => 'arrayref' },   # of br|zstd|gzip|x-gzip
    compressible_types            => { type => 'arrayref' },   # of strings or qr//
    excluded_types                => { type => 'arrayref' },   # of strings or qr//
    cache                         => { type => 'object', can => [qw(get set remove)], optional => 1 },
    cache_duration                => { type => 'string', min => 1, optional => 1 },
    cache_key                     => [ { type => 'string' }, { type => 'coderef' } ],
    cache_single_flight           => { type => 'scalar', optional => 1 },
    cache_lock_timeout            => { type => 'number', optional => 1 },   # > 0
    cache_lock                    => { type => 'object', can => [qw(acquire release)], optional => 1 },
    cache_lock_dir                => { type => 'string', min => 1, optional => 1 },
    vary_by                       => { type => 'arrayref' },   # of non-empty strings
    messages                      => { type => 'hashref', optional => 1 },
}
```

##### Output

```perl
# Return::Set schema
{ type => 'object', isa => 'Mojolicious::Plugin::Buffer' }
```

#### MESSAGES

Every message croaks, from the caller's point of view.  The key is the
[Mojolicious::Plugin::Buffer::I18N](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ABuffer%3A%3AI18N) key that can be overridden.

When several options are wrong, only one is reported: the first one when
the option names are sorted in ASCII order (for example `cache` comes
before `encodings`, and `generate_304` before `generate_etag`).  An
unknown option name is reported in the same way, at its place in that
order.  Fix it and register again to see the next problem.  The order is
fixed, so the same mistake always gives the same message.  The checks
that look at more than one option (`cache_lock` together with
`cache_lock_dir`, and unknown `encodings` names) come after all of
these.

```perl
Key                             Message (after "Mojolicious::Plugin::Buffer: ")     Resolution
------------------------------  --------------------------------------------------  ---------------------------------
options_not_hash                options must be a hash reference                    Pass {...} or a key/value list
unknown_option                  unknown option 'NAME'                               Check the spelling in OPTIONS
option_flag                     NAME must be a true or false value                  Pass 0 or 1, not a reference
option_optimise_content         optimise_content must be 0, 1 or 2                  Use one of the documented levels
option_last_modified            last_modified must be 0, 1, an epoch, a date        Pass a scalar or a coderef
                                string or a code reference
option_min_compress_size        min_compress_size must be a non-negative integer    Pass e.g. 32
option_encodings                encodings must be an array reference                Pass [qw(br gzip)]
unknown_encoding                unknown encoding 'NAME'                             Use br, zstd, gzip or x-gzip
option_compressible_types       compressible_types must be an array reference       Pass [qr{^text/}, ...]
option_excluded_types           excluded_types must be an array reference           Pass [qr{^text/event-stream$}]
option_vary_by                  vary_by must be an array reference of header names  Pass e.g. ['cookie']
option_cache_key                cache_key must be a string or a code reference      Pass a string or sub
option_cache                    cache must be an object understanding get(), set()  Pass a CHI object
                                and remove()
option_cache_duration           cache_duration must be a duration                   Pass e.g. '10 minutes'
option_template_mtime_cache     template_mtime_cache must be an object              Pass a CHI object
                                understanding get() and set()
option_template_mtime_cache_duration
                                template_mtime_cache_duration must be a duration    Pass e.g. 10
option_cache_lock_timeout       cache_lock_timeout must be a positive number of     Pass e.g. 10 or 0.5
                                seconds
option_cache_lock               cache_lock must be an object with acquire() and     See cache_lock
                                release() methods
option_cache_lock_dir           cache_lock_dir must be a directory path             Pass a non-empty string
lock_options_combined           cache_lock and cache_lock_dir cannot be combined    Use one of the two
option_messages                 messages must be a hash reference                   Pass {key => 'text'}
lock_dir_create_failed          cannot create cache_lock_dir 'DIR': OS ERROR        See Lock::File
lock_dir_not_writable           cache_lock_dir 'DIR' is not a writable directory    See Lock::File
```

A failure to validate `$app` itself is reported by [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict)
and is not translated.

#### PSEUDOCODE

```
accept the options as a hash reference or a key/value list
check the application object
adopt the messages option first, so later errors can be reworded
start from the defaults
for each option given, in sorted order:
    croak if it is unknown
    croak with its own message if its value does not fit its schema
croak if both cache_lock and cache_lock_dir were given
build the lock backend: the given object, or a file backend for the dir
canonicalise encodings, croak on unknown ones, drop unavailable ones
log once if optimisation is on without HTML::Packer
turn off the renderer's own compression
hook after_dispatch to rework every response
add the buffer_is_cached helper
return the plugin
```

### buffer\_is\_cached

```perl
get '/expensive' => sub {
    my $c = shift;
    return if $c->buffer_is_cached;
    # ... expensive work ...
    $c->render(template => 'expensive');
};
```

#### Purpose

A helper, added to the application by ["register"](#register), that lets an action skip
its work when a finished copy of the page is already cached, or when another
request is already building it.

Look for a cached response and, if there is one, replay its status, headers
and body, add `X-Cache: HIT`, finish the response and return true.  The
action only has to return; no rendering is needed on a hit.  On a miss it
adds `X-Cache: MISS`, returns false, and the response is stored when it is
complete.

Only `200` responses to `GET` and `HEAD` requests are cached.  Requests
with an `Authorization` header or a `Cache-Control` header containing
`no-store`, `no-cache`, `private` or `max-age=0` bypass the cache, as do
requests made while the `NO_CACHE` or `NO_STORE` environment variable is
set.  Responses that set a cookie, that are marked `no-store` or
`private`, or that vary on something not listed in ["vary\_by"](#vary_by), are not
stored.  Entries created before the application script or any template file
or directory was last modified are treated as misses and removed.

The stored body is the optimised but uncompressed entity, so every hit is
compressed for the requesting client, gets its own `ETag` and can still be
answered with `304 Not Modified`.  The cache key is a digest of the
application class, host, path, query string and the values of the headers
listed in ["vary\_by"](#vary_by); use ["cache\_key"](#cache_key) to replace it.  Query argument order
is significant.

Concurrent misses for the same key are coalesced within a worker, or across
workers when ["cache\_lock"](#cache_lock) or ["cache\_lock\_dir"](#cache_lock_dir) is set: while one request
is building an entry, later requests wait for it and replay the result
instead of running the action again.  The waiting requests are held
asynchronously, so this works for actions that themselves use the event
loop.  See ["cache\_single\_flight"](#cache_single_flight) for the failure and timeout behaviour.

Calling the helper more than once is harmless, but only the first call can
hit.  To disable the cache for one response, use
`$c->stash(buffer => {cache => undef})` before calling it.

#### Arguments

- `$c` (implicit)

    The controller the helper is called on.

#### Returns

True when the response has been, or will be, sent by the plugin: a cache
hit, or a request now waiting for another one to build the entry.  False
when the action must do its work: a miss, a bypassed request, no cache, or a
cache that failed.

#### Side effects

- On a hit: sets the status, headers and body and finishes the
response.
- On a miss: sets `X-Cache: MISS`, and the response is stored in the
cache when it is complete.
- When waiting: calls `render_later`; the response is finished later
from the event loop, with the entry or with `503 Service Unavailable`.
- May take a shared lock through ["cache\_lock"](#cache_lock), released when the
response is complete or after ["cache\_lock\_timeout"](#cache_lock_timeout).

#### Example

```perl
use Mojolicious::Lite;
use CHI;

plugin 'Buffer' => {cache => CHI->new(driver => 'Memory', global => 1)};

get '/report' => sub {
    my $c = shift;
    return if $c->buffer_is_cached;

    # Only reached on a miss
    $c->render(text => expensive_report());
};
```

#### API SPECIFICATION

##### Input

```perl
{ c => { type => 'object', isa => 'Mojolicious::Controller' } }
```

##### Output

```perl
# Return::Set schema
{ type => 'boolean' }
```

#### MESSAGES

The helper never croaks.  It logs:

```
Key                     Level  Meaning
----------------------  -----  -------------------------------------------------
log_cache_hit           debug  The response was replayed from the cache
log_cache_get_failed    error  The cache's get() died; the action runs normally
log_stale_entry         debug  The entry predates the application or a template
log_building            debug  This request will build the entry
log_waiting             debug  This request waits for another one in the worker
log_waiting_worker      debug  This request waits for another worker
log_lock_failed         error  The lock backend failed; a local flight is used
log_gave_up             debug  The wait timed out; a 503 was sent
log_finish_waiter_failed error Replaying to a waiting request failed
```

#### PSEUDOCODE

```perl
if the plugin is off for this response, return false
if this request was already replayed or is already waiting, return true
if this request is already building an entry, return false
if there is no cache or the request may not use it, return false
mark the request so the finished response is stored
work out the key and look the entry up
if the cache failed, return false
if there is no fresh entry:
    set X-Cache: MISS
    if single-flight is off, return false
    if this worker is already building the key, wait for it, return true
    if a lock backend says another worker is building it, poll, return true
    start a flight for the key (holding the lock if one was taken)
    return false
replay the entry and return true
```

### i18n

```perl
my $text = $plugin->i18n('retry_later');
```

#### Purpose

Look a message up in the catalog, applying the ["messages"](#messages) option.  It is
the method from [Mojolicious::Plugin::Buffer::I18N](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ABuffer%3A%3AI18N), imported so that the
plugin and its backends share one implementation; that module documents it
in full.

#### Arguments

`$key`, a message key, and an optional hash of placeholder values.

#### Returns

The text of the message, or the key itself if it is unknown.

#### Side effects

None.

#### Example

```perl
my $plugin = $app->plugin('Buffer', messages => {log_cache_hit => 'HIT %{key}'});
say $plugin->i18n('log_cache_hit', {key => 'buffer:abc'});   # HIT buffer:abc
```

#### API SPECIFICATION

##### Input

```perl
{
    key  => { type => 'string', min => 1 },
    args => { type => 'hashref', optional => 1 },
}
```

##### Output

```perl
# Return::Set schema
{ type => 'string' }
```

#### MESSAGES

See ["i18n" in Mojolicious::Plugin::Buffer::I18N](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ABuffer%3A%3AI18N#i18n).

## DEPLOYMENT

### Hypnotoad

[hypnotoad](https://metacpan.org/pod/hypnotoad) preloads the application before forking the workers, so the
plugin is registered once and every worker inherits the same cache object
and lock backend.  The cache storage, and the storage used by the lock
backend, must be shared and writable by the user that runs the workers.  The
example below uses [CHI](https://metacpan.org/pod/CHI), which must be installed in the application's
environment.

A complete application:

```perl
package MyApp;
use Mojo::Base 'Mojolicious';

use CHI;

sub startup {
    my $self = shift;

    $self->config(hypnotoad => {
        listen   => ['http://*:8080'],
        workers  => 4,
        pid_file => '/var/lib/myapp/hypnotoad.pid',
    });

    $self->plugin('Buffer' => {
        optimise_content => 1,
        cache => CHI->new(
            driver    => 'File',
            root_dir  => '/var/cache/myapp/buffer',
            namespace => 'pages',
        ),
        cache_lock_dir => '/var/lib/myapp/buffer-locks',
        cache_duration => '10 minutes',
    });

    $self->routes->get('/expensive' => sub {
        my $c = shift;
        return if $c->buffer_is_cached;

        # ... expensive work ...

        $c->render(template => 'expensive');
    });
}

1;
```

A runnable copy of this example, with its paths under `examples/hypnotoad`,
is included as `examples/hypnotoad`.

`script/my_app` is the usual launcher:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use MyApp;

MyApp->new->start;
```

Create the directories as the deployment user and start the server:

```
install -d -o www-data -g www-data -m 0750 /var/cache/myapp/buffer
install -d -o www-data -g www-data -m 0750 /var/lib/myapp /var/lib/myapp/buffer-locks
hypnotoad script/my_app
```

Replace `www-data` with the unprivileged user that runs the workers; do not
run hypnotoad as root.  The plugin creates `cache_lock_dir` if necessary,
but pre-creating it as the deployment user sets its ownership and
permissions.  The cache directory must be writable by that user too.  Use
`hypnotoad -f script/my_app` in the foreground while testing, and
`hypnotoad -s script/my_app` to stop it.

### Cache and lock requirements

For workers on the same host, [CHI](https://metacpan.org/pod/CHI)'s `File` driver and the built-in file
lock backend work.  Do not use `Memory`, and do not put a per-worker `L1`
cache in front of the shared cache: a waiting worker would not see the entry
built by another worker and would eventually receive `503 Service
Unavailable`.  A shared filesystem with reliable `flock` can also be used
on several hosts.

### Multiple hosts

Workers on different hosts need a shared cache and a lock backend that does
not rely on `flock`.  This example uses CHI's Memcached driver for the cache
and [Mojolicious::Plugin::Buffer::Lock::Redis](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ABuffer%3A%3ALock%3A%3ARedis) for the lock, with the
[Redis](https://metacpan.org/pod/Redis) client:

```perl
use CHI;
use Mojolicious::Plugin::Buffer::Lock::Redis;
use Redis;

my $redis = sub {
    Redis->new(
        server        => 'redis://redis.internal:6379',
        cnx_timeout   => 1,
        read_timeout  => 1,
        write_timeout => 1,
    );
};

$app->plugin('Buffer' => {
    cache => CHI->new(
        driver    => 'Memcached',
        servers   => ['cache1.internal:11211', 'cache2.internal:11211'],
        namespace => 'pages',
    ),
    cache_lock => Mojolicious::Plugin::Buffer::Lock::Redis->new(
        redis     => $redis,
        namespace => 'myapp:buffer:',
        ttl       => 60,
    ),
    cache_duration => '10 minutes',
});
```

The `ttl` must be longer than ["cache\_lock\_timeout"](#cache_lock_timeout) and longer than the
slowest cached action.  If it expires while the builder is still working,
another worker can start building the same entry.  The Redis client is
called synchronously, so set short connect, read and write timeouts.  The
code reference is called once per worker, after the fork; a connection
created in `startup` would be shared by every worker and must not be used.
CHI's Memcached driver needs [Cache::Memcached::Fast](https://metacpan.org/pod/Cache%3A%3AMemcached%3A%3AFast).

Only cache pages that are identical for every visitor.  The default key
includes the `Cookie` header, not the contents of the session, so a page
that depends on the session needs ["cache\_key"](#cache_key) or a suitable ["vary\_by"](#vary_by)
list.  Entries are discarded when the application script or a template
changes, and otherwise expire after ["cache\_duration"](#cache_duration).

## NOTES

### Testing

The Redis lock backend has an optional live integration test.  It skips when
`MPB_REDIS_URL` (or `REDIS_SERVER`) is not set, or when neither [Redis](https://metacpan.org/pod/Redis) nor
[Redis::Fast](https://metacpan.org/pod/Redis%3A%3AFast) is installed.  Redis::Fast is used when it is the only client
available.  CI runs the test against a live Redis service with each client,
once with [Redis](https://metacpan.org/pod/Redis) and once with only [Redis::Fast](https://metacpan.org/pod/Redis%3A%3AFast) available ([Redis](https://metacpan.org/pod/Redis)
hidden with [Test::Without::Module](https://metacpan.org/pod/Test%3A%3AWithout%3A%3AModule)), and each run proves from the test
output which client it used, so both paths include the three-process crash
check described below rather than merely being wired up.  When either
variable is set, the test expects that server to be reachable; the value may
be a `redis://` URL or a bare `host:port`, so `REDIS_SERVER` already in
the environment needs no rewriting:

```
MPB_REDIS_URL=redis://127.0.0.1:6379 prove -Ilib t/76-live-redis.t
REDIS_SERVER=127.0.0.1:6379 prove -Ilib t/76-live-redis.t
```

A server named by either variable must answer.  The variable says a live
Redis is there for this test, so an unreachable one fails the file, naming
the variable and the connection error, rather than skipping and looking like
a checkout with no Redis configured.  Unset both to skip the test.

That includes a three-process check of the crash path: a worker takes the
lock and is killed, another process stays blocked until the TTL expires,
takes the lock over, and a third process is blocked until that owner
releases it.  The crash test uses a two second lock TTL and waits for it to
run out rather than sleeping a fixed margin; set `MPB_REDIS_TTL` to widen
that further on a heavily loaded machine.  The normal test suite does not
require a Redis server.

The private routines are guarded by [Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate) in `enforce` mode and
[Sub::Protected](https://metacpan.org/pod/Sub%3A%3AProtected).  Both stand aside while `HARNESS_ACTIVE` is set, so the
white-box tests can reach them under `prove`; `t/16-encapsulation.t` turns
that bypass off to check the guards themselves.

### Why a plugin?

[CGI::Buffer](https://metacpan.org/pod/CGI%3A%3ABuffer) replaces `STDOUT` with an in-memory buffer and does its work
in an `END` block, and [FCGI::Buffer](https://metacpan.org/pod/FCGI%3A%3ABuffer) buffers each FastCGI request and does
its work in `DESTROY`.  Neither trick is needed in Mojolicious: the response
already exists as an object before it is written, so the plugin can simply
hook `after_dispatch` and rewrite it.  That gives the same effect without a
source filter, without reading `$_`, and without depending on a specific
server or environment.

### Interaction with the renderer

`Mojolicious::Renderer` compresses rendered output with gzip by default
(`compress` is on and `min_compress_size` is 860 bytes).  That happens
before ["after\_dispatch" in Mojolicious](https://metacpan.org/pod/Mojolicious#after_dispatch) is emitted, which would leave this
plugin with nothing to optimise and no `ETag` to generate on any page
larger than 860 bytes.  Registering this plugin therefore calls
`$app->renderer->compress(0)`, and the plugin does the compression
instead - with gzip, Brotli or Zstandard as negotiated, and with the header
work the renderer does not do.  If you enable `$app->renderer->compress`
after loading the plugin, those responses will be skipped by the plugin.

### What is not implemented

`save_to`, which rewrites dynamic pages into static ones, is a site
generation feature rather than a response filter and is not part of this
plugin.  The server-side cache is available as the opt-in
["buffer\_is\_cached"](#buffer_is_cached) helper described above.

## COMMON PITFALLS

### The `buffer` stash: what each value means

- `buffer => 0` and `buffer => ''` turn the plugin
**off** for this response.
- `buffer => undef` does **not** turn it off.  undef means
"nothing set here", so the plugin options are used.
- `buffer => {}` keeps the plugin **on** and changes nothing.

### The `buffer` stash is merged one level deep only

The hash you put in the stash is laid over the plugin options one key at a
time.  A key you give replaces the whole plugin value for that key; nothing
inside it is merged.  So lists are replaced, not added to:

```perl
plugin 'Buffer' => {encodings => [qw(br gzip)]};

# This response may ONLY use br.  If Brotli is not installed, it is
# not compressed at all, and an error is logged.
$c->stash(buffer => {encodings => ['br']});
```

Values in the stash are not checked the way `plugin()` options are, and
they are not filtered by which compression modules are installed.

### undef in options

- In the `buffer` stash, an undef value is a real value.
`{compress_content => undef}` turns compression **off** for that
response, and `{cache => undef}` turns the cache off.
- In a group declaration (a route default or `buffer_NAME`
controller method), undef means "not declared", so the plugin option is
used.
- In `plugin()` options, undef is accepted only where it means "use
the default" or "off":

    ```
    optimise_content and the true/false   off
      flags (compress_content,
      rewrite_links, generate_etag,
      generate_304, trust_last_modified,
      cache_single_flight)
    last_modified                         no Last-Modified header
    cache, cache_lock, cache_lock_dir,    not used
      template_mtime_cache
    cache_key                             the generated key
    cache_duration, cache_lock_timeout,   their default values
      template_mtime_cache_duration
    messages                              the built-in English texts
    ```

    For `encodings`, `compressible_types`, `excluded_types`, `vary_by` and
    `min_compress_size`, undef is refused when the plugin is registered.  This
    matters most for `vary_by`: an undef there would have silently removed the
    `Cookie` header from the cache key.

- In `messages`, undef does **not** restore the built-in text.
`messages => {retry_later => undef}` makes visitors see the
word `retry_later`.  Leave the key out instead.  See
["COMMON PITFALLS" in Mojolicious::Plugin::Buffer::I18N](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ABuffer%3A%3AI18N#COMMON-PITFALLS).

### Using the server-side cache safely

- **Check access before ["buffer\_is\_cached"](#buffer_is_cached).**  A cached page is sent
straight away and the rest of the action does not run.  Any login or
country check that comes later in the action is skipped on a hit.
- **Personal pages need a personal key.**  `vary_by => []`
makes the key the same for every visitor.  A page that shows a name, a
basket or anything else from the session is then shown to other visitors.
Keep the default `['cookie']`, or set ["cache\_key"](#cache_key).
- **The cache must be shared by all workers.**  With several workers,
a per-worker cache such as CHI's `Memory` driver means a waiting request
never sees the entry another worker built; after ["cache\_lock\_timeout"](#cache_lock_timeout)
it gets `503 Service Unavailable`.
- **Waiting requests get 503, not a second build.**  If the request
that is building a page fails, makes something that cannot be stored (for
example, it sets a cookie), or is slower than ["cache\_lock\_timeout"](#cache_lock_timeout), the
requests waiting for it get `503` with `Retry-After: 1`.
- **A Redis lock TTL must be longer than the slowest action**, or a
second worker starts building the same page.
- **Template edits can be missed for a while** when
["template\_mtime\_cache"](#template_mtime_cache) is set: until its entry expires.

### Other pitfalls

- **Do not turn the renderer's compression back on.**  The plugin turns
off `$app->renderer->compress`.  If you turn it on again, the renderer
compresses first, and the plugin then skips those responses: no
optimisation and no `ETag`.
- **Do not stream through the plugin.**  Responses written with
`$c->write` are not buffered and are left alone.
- **`$c->stash(buffer => ...)` must be set before the action
ends.**  The plugin reads it in `after_dispatch`.  To turn the cache off for
one request, set `{cache => undef}` _before_ calling
["buffer\_is\_cached"](#buffer_is_cached).

## ENCODING

This section says which text may contain non-ASCII characters, such as
accented letters, other scripts and emoji.

- Response bodies

    Any encoding works.  Pages rendered by Mojolicious are already UTF-8 bytes
    when the plugin sees them.  A body that is still a Perl character string is
    encoded to UTF-8 first.  Bodies in another character set, such as
    ISO-8859-1 or Shift\_JIS, are passed through unchanged; the plugin does not
    convert them.

- HTML optimisation

    Safe for every UTF-8 character, including emoji.  The optimiser only
    changes ASCII white space (space, tab, carriage return, line feed, form
    feed) and ASCII markup.  A non-breaking space (U+00A0) is kept.

- The `ETag`

    Made from the bytes of the body, so any content is fine.

- Cache keys

    A custom ["cache\_key"](#cache_key) may contain any characters, including emoji.  Keys
    are encoded to UTF-8 before they are hashed for the lock backends.  The
    generated key is an ASCII MD5 digest.  The cache itself receives a custom
    key as it is; [CHI](https://metacpan.org/pod/CHI)'s File and Memory drivers accept any characters, but
    check this for other cache objects.

- Request headers in ["vary\_by"](#vary_by)

    Header _names_ are ASCII.  Header _values_ are used as raw bytes, so any
    value is fine.

- The `503` text (`retry_later`) and other messages

    May contain any characters.  The `503` body is sent as UTF-8 with
    `Content-Type: text/plain; charset=UTF-8`.  Log lines go through
    [Mojo::Log](https://metacpan.org/pod/Mojo%3A%3ALog), which writes them as UTF-8.

- Error messages

    The plugin's `croak` messages are Perl character strings.  If you
    translate them into a non-ASCII language and print them to `STDERR`, give
    `STDERR` an encoding layer, or Perl warns "Wide character".

- File paths (`cache_lock_dir`)

    Paths go to the operating system as bytes.  ASCII paths are always safe.
    For a non-ASCII path, pass bytes that are already encoded the way your file
    system expects, usually UTF-8.

- Option names, encoding names and media types

    These are ASCII words.

## LIMITATIONS

- Only in-memory responses are processed.  Static files
(`Mojo::Asset::File`) and streaming responses are left alone.
- The whole response is held in memory, more than once while it is
being optimised and compressed.  There is no size limit; a very large
generated body costs several times its size in a worker.
- Responses that already have a `Content-Encoding`, for example from
`$app->renderer->compress`, are not compressed again.
- Gzip, Brotli, Zstandard and identity representations have different
`ETag`s, because the tag identifies the selected representation.  A client
that switches between content codings will therefore download the page once
for each coding.
- Because the body is buffered, the plugin must not be used for
responses that are streamed with `$c->write` (server-sent events,
long-polling and so on).  `text/event-stream` is excluded by default.
- The HTML optimiser is a set of regular expressions inherited from
[CGI::Buffer](https://metacpan.org/pod/CGI%3A%3ABuffer), not an HTML parser.  It protects the content of
`<pre>`, `<textarea>`, `<script>` and
`<style>`, but white space made significant by CSS
(`white-space: pre` on another element) is still collapsed, and some rules
(for example merging adjacent `<center>` blocks) change the
document slightly.  Use `optimise_content => 0` on pages where every
byte matters, or disable it per response with
`$c->stash(buffer => {optimise_content => 0})`.  Link rewriting
only recognises double-quoted attributes.
- The server-side cache is opt-in: a page is only stored if its action
calls ["buffer\_is\_cached"](#buffer_is_cached).  An action that forgets to call it is never
cached, and an action that calls it for a personalised page must supply a
["cache\_key"](#cache_key) that distinguishes users (the default key only includes the
`Cookie` header, not the session contents).
- The default key includes the `Cookie` header, so each session gets
its own set of entries and anonymous visitors share them.  Sites that set an
analytics cookie on every visit will get little sharing; use
`vary_by => []` for genuinely public pages, or ["cache\_key"](#cache_key).
- Single-flight is per worker by default.  Each `hypnotoad` worker
keeps its own in-flight table, so a cold entry can be built once per worker;
set ["cache\_lock"](#cache_lock) or ["cache\_lock\_dir"](#cache_lock_dir) to coalesce across workers, with a
shared cache.  A request waiting on an in-flight response is answered with
`503` if that response fails, cannot be cached, or exceeds
["cache\_lock\_timeout"](#cache_lock_timeout), rather than running the action a second time.  A
waiter in another worker polls the cache every 100 milliseconds, so it can
be answered up to that much later than the builder finishes.
- Entries are invalidated when the application script or a template
path changes, but not when data or configuration changes.  The TTL is the
backstop for those.
- Options in the `buffer` stash and group declarations are not
validated the way `plugin()` options are.  A bad `cache_lock_timeout`
there falls back to the default; other bad values are used as given.
- The lock backend protocol returns two-element lists rather than
references.  That is the documented interface third-party backends already
implement, so it was kept.
- Every private routine is wrapped by [Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate) or
[Sub::Protected](https://metacpan.org/pod/Sub%3A%3AProtected), which costs a `caller` check on each call.  The plugin
makes a few hundred such calls per response, which is small next to MD5,
compression and template rendering, but it is not free.  The modules also
add [Readonly](https://metacpan.org/pod/Readonly), [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict) and their dependencies to what
was a Mojolicious-only plugin, and `use autodie qw(:all)` requires
[IPC::System::Simple](https://metacpan.org/pod/IPC%3A%3ASystem%3A%3ASimple) even though the plugin never runs an external
command.
- The `503` text is chosen per application through ["messages"](#messages); it
is not negotiated from `Accept-Language`.

## SEE ALSO

[CGI::Buffer](https://metacpan.org/pod/CGI%3A%3ABuffer), [FCGI::Buffer](https://metacpan.org/pod/FCGI%3A%3ABuffer), [CHI](https://metacpan.org/pod/CHI), [HTML::Packer](https://metacpan.org/pod/HTML%3A%3APacker),
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious%3A%3APlugin), [Mojolicious::Plugin::Buffer::Lock::File](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ABuffer%3A%3ALock%3A%3AFile),
[Mojolicious::Plugin::Buffer::Lock::Redis](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ABuffer%3A%3ALock%3A%3ARedis),
[Mojolicious::Plugin::Buffer::I18N](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ABuffer%3A%3AI18N)

## FORMAL SPECIFICATION

This section describes the plugin in the Z notation, for readers who want
an exact model.  You do not need it to use the plugin.  `now` is the
current time and `mtime` is the newest modification time of the
application script and its templates.  `Schema` maps each option name to
its [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict) rule.

```
[OPTION, VALUE, APP, KEY, Controller, Entry, Guard, Response]

Known == dom Schema
Valid == { o : Known; v : VALUE | v ∈ Schema(o) }

Flight == [ waiters : ℙ Controller ; deadline : ℝ ; guard : Guard ∪ {⊥} ]

┌─ Plugin ────────────────────────────────────
│ options : OPTION ⇸ VALUE
│ inflight : KEY ⇸ Flight
│ polling : Controller ⇸ (KEY × ℝ)
│ lock : LockBackend ∪ {⊥}
├─────────────────────────────────────────────
│ dom options = Known
│ ∀ o : dom options • (o, options o) ∈ Valid
│ ∀ k : dom inflight • (inflight k).deadline ≤ now + timeout
└─────────────────────────────────────────────

┌─ Cache ─────────────────────────────────────
│ store : KEY ⇸ Entry
│ created : KEY ⇸ ℝ
├─────────────────────────────────────────────
│ dom created = dom store
└─────────────────────────────────────────────

fresh : ℙ KEY
fresh = { k : dom store | created k ≥ mtime }
```

### register

```
┌─ Register ──────────────────────────────────
│ ΔPlugin
│ app? : APP ; conf? : OPTION ⇸ VALUE ; result! : Plugin
├─────────────────────────────────────────────
│ dom conf? ⊆ Known
│ ∀ o : dom conf? • (o, conf? o) ∈ Valid
│ ∀ o : dom conf? • conf? o = ⊥ ⇒ undefAllowed(o)
│ ¬(cache_lock ∈ dom conf? ∧ cache_lock_dir ∈ dom conf?)
│ ran (conf? encodings) ⊆ {br, zstd, gzip, x-gzip}
│ options′ = Defaults ⊕ conf?
│ inflight′ = ∅ ∧ polling′ = ∅
│ compress(renderer app?)′ = false
│ after_dispatch ∈ hooks(app?)′ ∧ buffer_is_cached ∈ helpers(app?)′
│ result! = θPlugin′
└─────────────────────────────────────────────
-- Any violated predicate: croak, and app? is unchanged
```

### buffer\_is\_cached

`cacheable(c)` holds when the plugin is on for this response, a cache is
configured, the method is `GET` or `HEAD`, and the request carries no
`Authorization` header, no `no-store`, `no-cache`, `private` or
`max-age=0` directive, and `NO_CACHE` and `NO_STORE` are not set.
`busy(k)` holds when the lock backend says another process holds `k`.

```
┌─ BufferIsCached ────────────────────────────
│ ΔPlugin ; ΔCache
│ c? : Controller ; result! : 𝔹 ; response! : Response
├─────────────────────────────────────────────
│ let k == key(c?) •
│   ¬cacheable(c?) ⇒ result! = false
│   cacheable(c?) ∧ k ∈ fresh ⇒
│       response! = replay(store k) ∧ result! = true
│   cacheable(c?) ∧ k ∉ fresh ⇒ store′ = {k} ⩤ store ∧ (
│     ¬singleFlight ⇒ result! = false
│     singleFlight ∧ k ∈ dom inflight ⇒
│       (inflight′ k).waiters = (inflight k).waiters ∪ {c?}
│       ∧ result! = true
│     singleFlight ∧ k ∉ dom inflight ∧ busy(k) ⇒
│       polling′ = polling ⊕ {c? ↦ (k, now + timeout)}
│       ∧ result! = true
│     singleFlight ∧ k ∉ dom inflight ∧ ¬busy(k) ⇒
│       k ∈ dom inflight′ ∧ (inflight′ k).waiters = ∅
│       ∧ result! = false )
└─────────────────────────────────────────────
```

The building request finishes (the `after_dispatch` hook), or its time
runs out.  `e?` is the stored entry, or `⊥` when the response could not be
stored or the build timed out.

```
┌─ FinishFlight ──────────────────────────────
│ ΔPlugin
│ k? : KEY ; e? : Entry ∪ {⊥}
├─────────────────────────────────────────────
│ k? ∈ dom inflight
│ ∀ w : (inflight k?).waiters •
│     (e? ≠ ⊥ ⇒ response(w)′ = replay(e?))
│   ∧ (e? = ⊥ ⇒ response(w)′ = 503)
│ inflight′ = {k?} ⩤ inflight
│ (inflight k?).guard ≠ ⊥ ⇒ released((inflight k?).guard)
└─────────────────────────────────────────────

ExpireFlight == [ FinishFlight | now ≥ (inflight k?).deadline ∧ e? = ⊥ ]
```

Every 0.1 seconds, each request waiting for another worker looks again:

```
┌─ PollTick ──────────────────────────────────
│ ΔPlugin
│ c? : dom polling
├─────────────────────────────────────────────
│ let (k, d) == polling c? •
│   k ∈ fresh ⇒ response(c?)′ = replay(store k)
│                ∧ polling′ = {c?} ⩤ polling
│   k ∉ fresh ∧ now ≥ d ⇒ response(c?)′ = 503
│                ∧ polling′ = {c?} ⩤ polling
│   k ∉ fresh ∧ now < d ∧ busy(k) ⇒ polling′ = polling
│   k ∉ fresh ∧ now < d ∧ ¬busy(k) ⇒
│       response(c?)′ = 503 ∧ polling′ = {c?} ⩤ polling
└─────────────────────────────────────────────
-- In the last case the lock is taken and the cache read once more
-- before the 503, so an entry stored at that moment is still replayed
```

### i18n

The same operation as ["i18n" in Mojolicious::Plugin::Buffer::I18N](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ABuffer%3A%3AI18N#i18n), where
`overrides` is the ["messages"](#messages) option.

## STATE DIAGRAM

There are three pictures.  The numbers on the arrows are explained below
each picture.  In each explanation, the text in `[ ]` is the condition and
the text after `/` is what happens.

### A. One page in the server-side cache

This is the life of one cache key, seen by all workers together.

```perl
             +---------------------+
             |        EMPTY        |<-----------------------+
             |  nothing is stored  |                        |
             +---------------------+                        |
               |        ^       ^                           |
            (1)|     (3)|    (4)|                           |
               v        |       |                           |
             +---------------------+      (5)               |
             |      BUILDING       |-----------+            |
             | one request builds; |           |            |
             | others wait         |           v            |
             +---------------------+    +--------------+    |
               |                        |    CACHED    |    |
            (2)+----------------------->| fresh entry  |    |
                                        +--------------+    |
                                          |    ^      |     |
                                       (6)|    |(7)   |(8)  |
                                          v    |      v     |
                                        +--------------+    |
                                        |    STALE     |----+
                                        |  too old     | (9)
                                        +--------------+

(1) a request calls buffer_is_cached  [no fresh entry, single-flight
    on, nobody else building]
    / X-Cache: MISS; this request becomes the builder; it takes the
      shared lock if one is configured; a timer of
      cache_lock_timeout starts
(2) the builder's response is finished  [200, may be stored]
    / the uncompressed page is stored with cache_duration; every
      waiting request is answered from it; the lock is released
(3) the builder's response is finished  [error, or not storable:
    it sets a cookie, is marked private or no-store, or varies on a
    header not in vary_by]
    / every waiting request gets 503 with Retry-After: 1; the lock
      is released
(4) cache_lock_timeout passes before the builder finishes
    / waiting requests get 503; the lock is released.  If the
      builder finishes later and its page may be stored, it is still
      stored: that is arrow (5).
(5) a late builder finishes  [200, may be stored]
    / the page is stored
(6) the application script or a template file is changed
    / nothing happens yet; the entry is now older than the code
(7) a request reads the entry  [it is fresh]
    / the stored page is replayed with X-Cache: HIT; it is
      compressed for this client and gets its own ETag
(8) cache_duration passes
    / the cache forgets the entry
(9) a request reads the entry  [it is older than the code]
    / the entry is removed; the request goes on as at (1)

While BUILDING, a second request for the same key:
  - in the same worker: waits for (2), (3) or (4);
  - in another worker, with a shared lock: looks in the cache every
    0.1 seconds until the page appears, the lock is free, or
    cache_lock_timeout passes;
  - with cache_single_flight => 0: does not wait, and builds the page
    too.
```

### B. One request that calls buffer\_is\_cached

```
                     buffer_is_cached
                            |
                            v
 +--------------+  (1)  +--------+  (5)  +-----------------+
 |  RUN ACTION  |<------| DECIDE |------>|     BUILDER     |
 |  not cached  |       +--------+       | the action runs;|
 +--------------+        |   |   |       | see picture C   |
                      (2)|   |   |(3)    +-----------------+
                         v   |   v
                  REPLAYED   |  +----------------+  (8)
                             |  | WAITING_REMOTE |------> REPLAYED
                             |  | polls the cache|  (9)
                             |  | 10 times a sec |------> 503
                             |  +----------------+
                             |     |        ^
                          (4)|     +--(10)--+
                             v
                    +----------------+  (6)
                    | WAITING_LOCAL  |------> REPLAYED
                    | same worker    |  (7)
                    +----------------+------> 503

(1) [the plugin is off, no cache, method not GET or HEAD, an
    Authorization header, Cache-Control no-store, no-cache, private
    or max-age=0, NO_CACHE or NO_STORE set, or the cache's get() died]
    / returns false: the action runs normally
(2) [a fresh entry exists]
    / status, headers and body are replayed; X-Cache: HIT; the
      response is finished; returns true
(3) [no entry; another worker holds the shared lock]
    / render_later; X-Cache: MISS; returns true
(4) [no entry; a request in this worker is building it]
    / render_later; X-Cache: MISS; returns true
(5) [no entry; nobody is building it, or single-flight is off]
    / X-Cache: MISS; returns false.  If the lock backend failed, the
      error is logged and this worker builds without a shared lock.
(6) the builder in this worker stored the page
    / the page is replayed with X-Cache: HIT
(7) the builder failed, made something not storable, or
    cache_lock_timeout passed
    / 503 with Retry-After: 1 and the retry_later text
(8) a poll finds the page in the cache
    / the page is replayed
(9) a poll finds [cache_lock_timeout has passed], or [the lock is free
    but there is still no page], or [the lock backend failed]
    / 503 with Retry-After: 1
(10) a poll finds [no page yet, and the lock is still held]
    / wait another 0.1 seconds

Calling buffer_is_cached again in the same request returns the same
answer and changes nothing.
```

### C. What the after\_dispatch hook does with every response

```perl
 response finished by the action
      |
      v
 +-----------------+  (1)
 | 1. CHECK        |-----------------------------------> sent as it is
 +-----------------+
      |
      v
 +-----------------+  [HTML and optimise_content on, and the result
 | 2. OPTIMISE     |   is smaller]  / white space removed, links
 +-----------------+   shortened.  Skipped for a replayed entry.
      |
      v
 +-----------------+  [compress_content on and type in
 | 3. COMPRESS     |   compressible_types] / Vary: Accept-Encoding;
 +-----------------+   then [client accepts a coding, body >=
      |                min_compress_size, result smaller]
      |                / body compressed, Content-Encoding set
      |
      v
 +-----------------+  [buffer_is_cached ran, it was not a hit, the
 | 4. STORE        |   status is 200, the response may be stored]
 +-----------------+   / the uncompressed page goes into the cache
      |
      v
 +-----------------+  (2)
 | 5. VALIDATE     |-----------------------------------> 304, no body
 +-----------------+
      |
      v
 +-----------------+
 | 6. SEND         |  the compressed or plain body; Content-Length
 +-----------------+
      |
      v
 if this request was the builder: answer every waiting request and
 release the shared lock (arrows (2) and (3) of picture A).  This
 also happens when a step above dies.

(1) [the stash says buffer => 0, or the body is empty, streamed or a
    file, or the status is 1xx, 204, 206 or 304, or a
    Content-Encoding is already set, or the media type is unknown or
    in excluded_types]
(2) [GET or HEAD, status 200, generate_304 on, and If-None-Match
    matches the ETag; or there is no ETag (or trust_last_modified is
    on) and If-Modified-Since is not older than Last-Modified]
    / 304 Not Modified is sent with no body
```

## AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

## LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
