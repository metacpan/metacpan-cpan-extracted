# Grouped sections example

A small site that declares two response-shaping options once for a whole
section, rather than once for every page in it. Each section uses a different
declaration form, so both are visible side by side:

- `/docs/*` is an optimised static section, declared on an `under` route.
- `/assets/*` is an assets section, declared in its controller.

## Run it

From the distribution root:

    perl examples/grouped-sections/script/grouped_sections daemon -l http://127.0.0.1:3000

Or with `morbo` if it is installed, remembering that its options come before
the application:

    morbo -l http://127.0.0.1:3000 examples/grouped-sections/script/grouped_sections

## The optimised section

`/docs/intro` and `/docs/install` share one template, which is written with
readable indentation and a comment. The whole namespace is optimised by:

    my $docs = $r->under('/docs')->to(optimise_content => 1);

Requesting either page returns the same document with the indentation
squashed and, when `HTML::Packer` is installed, the comment removed:

    curl -s http://127.0.0.1:3000/docs/intro

The declaration is a default, not a rule: `$c->stash(buffer => ...)` or a route
default of `0` still opts one page back out.

## The assets section

`/assets/app.css` and `/assets/app.js` are built by the application rather than
streamed from disk, so they are ordinary actions and the plugin would compress
them. They are already minified, and the reverse proxy in front of the app
compresses them, so the application leaves the bytes alone:

    package GroupedSections::Controller::Assets;

    has buffer_compress_content => 0;

Comparing the two sections with the same request headers shows the difference:

    curl -sI -H 'Accept-Encoding: gzip' http://127.0.0.1:3000/docs/intro   # Content-Encoding: gzip
    curl -sI -H 'Accept-Encoding: gzip' http://127.0.0.1:3000/assets/app.css   # no Content-Encoding

The assets are still processed: they get an `ETag`, and the section keeps its
own `Cache-Control`. Only compression is skipped, and because the response is
never encoded it has no `Vary: Accept-Encoding` either, which is what lets the
proxy cache a single copy per URL.

## Testing

`t/86-grouped-example.t` runs this example and asserts both sections, so the
declarations above are exercised rather than merely shown.

## Where the rules are documented

`Mojolicious::Plugin::Buffer` documents the declaration forms and their
precedence once, in "Declaring options for a group of pages", with a table of
the options that support it.
