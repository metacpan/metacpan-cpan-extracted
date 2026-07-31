# NAME

Router::Ragel - High-performance URL router built on a Ragel-generated state machine

# SYNOPSIS

    use Router::Ragel;

    my $router = Router::Ragel->new
        ->add('/users', 'users_list')
        ->add('/users/:id<int>', 'user_show')
        ->add('/blog/:year<int>/:month<int>/:slug', 'blog_post')
        ->compile;

    my ($handler, @captures) = $router->match('/users/42');
    # ('user_show', '42')

    my @no_match = $router->match('/nope');
    # ()

    # Function form, faster than method dispatch:
    my ($h, @c) = Router::Ragel::match($router, '/users/42');

# DESCRIPTION

Router::Ragel compiles a set of URL patterns into a single Ragel finite-state
machine and emits it as C via [Inline::C](https://metacpan.org/pod/Inline%3A%3AC). Matching a path is a fixed-cost
walk over a DFA: there is no per-route loop and no regex engine. For
applications with many routes or high request rates this typically beats
regex- and trie-based routers by a wide margin (see ["PERFORMANCE"](#performance)).

The router supports:

- Static segments (`/users`, `/products`)
- Named placeholders (`/users/:id`, `/blog/:year/:month`)
- Typed placeholders (`/users/:id<int>`, `/code/:c<[0-9]{4}>`)
- Inline placeholders mixed with literal text in a single segment
(`/v/:major<int>.:minor<int>`)
- Multiple independent router instances in the same process

# REQUIREMENTS

`compile` generates Ragel source and builds it through [Inline::C](https://metacpan.org/pod/Inline%3A%3AC), so the
external **`ragel`** binary, a **C compiler** and **`make`** must be present at
**run time**, not just at install time. `Makefile.PL` reports the distribution
as unavailable when `ragel` is not on `PATH`.

Loading the module compiles a small C stub as well, so even `use
Router::Ragel` invokes the compiler against a cold [Inline](https://metacpan.org/pod/Inline) cache. See
["DEPLOYMENT"](#deployment) for keeping that off the request path.

# METHODS

## new

    my $router = Router::Ragel->new;

Constructs a new router. Takes no arguments, and `croak`s if given any.

## add

    $router->add($pattern, $data);

Registers a route. `$pattern` is a path string (see ["ROUTE PATTERNS"](#route-patterns));
`$data` is the value returned by `match` on a hit and may be any scalar.
Returns the router, so calls can be chained. `$data` may be omitted, in which
case the route returns `undef`; passing more than the two arguments is a
mistake and `croak`s rather than silently dropping the rest.

Adding a route after `compile` invalidates the compiled state; the next
`match` will `croak` until `compile` is called again.

## compile

    $router->compile;

Builds and binds the Ragel state machine. Must be called before `match`;
`croak`s if no routes have been added. Returns the router. May be called
more than once to incorporate routes added between calls; see ["LIMITATIONS"](#limitations)
for the cost of recompiling.

## match

    my ($data, @captures) = $router->match($path);

Matches `$path` against the compiled routes and returns the route data
followed by captured values, in pattern order. Returns the empty list on no
match.

For the lowest call overhead, invoke `match` as a plain function and skip
Perl's method dispatch:

    my ($data, @captures) = Router::Ragel::match($router, $path);

Both forms run the same compiled state machine.

Call `match` in list context. In scalar context it yields only the last
value pushed (the last capture, or the route data when the route has none),
which is rarely what you want.

## Route precedence

When more than one route matches the same path, the route added **last**
wins. Overlapping a specific route with a later, more general one shadows the
earlier route:

    my $router = Router::Ragel->new
        ->add('/files/index', 'index')
        ->add('/files/:name', 'show')   # added last
        ->compile;
    my ($h) = $router->match('/files/index');   # 'show', not 'index'

Add the route you want to win **last**, or avoid overlapping patterns.

# ROUTE PATTERNS

A pattern is a string starting with `/`. Each segment between slashes is
either literal text or contains one or more **placeholders**. A placeholder is
`:NAME` optionally followed by a type constraint `<TYPE>`.

## Placeholder names

The name is a run of word characters (`\w+`): letters, digits, and
underscores. With no type, a placeholder matches any non-slash bytes
(`[^/]+`).

The name is greedy, so to follow a placeholder with literal characters that
could otherwise extend the name, terminate the name with an explicit type:

    /:type_extra # one placeholder named "type_extra"
    /:type<string>_extra # placeholder "type" then literal "_extra"

## Type constraints

Built-in aliases:

- `int` = `[0-9]+`
- `string` = `[^/]+` (default; explicit form)
- `hex` = `[0-9a-fA-F]+`

Anything else inside `<...>` is a **Ragel expression**, passed through to
the generated state machine, so arbitrary character classes and quantifiers
work:

    /code/:c<[0-9]{4}> # exactly four digits
    /file/:name<[a-z0-9\-]+> # slug-like (escape '-' inside a class)

The dialect is **Ragel's**, not Perl/PCRE. Available: character classes,
quantifiers (`*`, `+`, `?`, `{n}`, `{n,m}`), alternation, grouping,
quoted literals (`<('ab'|'cd')+>` -- an unquoted word is a _machine
name_, not a literal), and Ragel keywords (`digit`, `alpha`, `alnum`,
`xdigit`, `lower`, `upper`, `space`, `punct`, `print`, `ascii`,
`any`). **Not** available: Perl shortcuts (`\d`, `\w`, `\s`), anchors,
lookaround, and backreferences. Anchors are unnecessary anyway: segment
boundaries are implicit. `^` is Ragel's negation operator rather than an
anchor, so `<^'a'>` matches any one byte except `a`; inside a character
class it keeps its usual sense (`<[^0-9]+>`).

Ragel grammar can also embed C code and start new grammar statements, so
`compile` holds the type expression to the constructs listed above: strings,
character classes and parentheses must balance, `{` may only introduce a
repetition quantifier, and `%`, `$`, `@`, `#`, `;`,
`=`, `}` and control characters (newlines included) are rejected --
but only where they would be grammar. To match one of them, put it in a
character class or a quoted literal, where it is ordinary data
(`<[a-z0-9%]+>`, `<'100%'>`). This catches mistakes; it is **not** a
security boundary, see ["SECURITY"](#security).

A literal `>` cannot appear inside a `<type>` expression (the
parser closes the type at the first `>`, and everything after it is
literal segment text); a literal `<` is rejected at compile time. A
literal `/` cannot appear either, not even inside a character class: the
pattern is cut into segments on `/` before placeholders are parsed, so
`<[^/]+>` reads as a type that never closes. That expression is what the
`string` alias means, so write `<string>` instead. A
literal `-` inside a character class must be escaped as `\-`
(Ragel parses an unescaped `-` as a range operator and errors out, even
at the start or end of the class). For any of these, match a permissive class
and post-process in user code.

If Ragel or the C compiler rejects the generated machine, `compile` `croak`s
naming every pattern that carries a `<type>`: literal segments are quoted
and escaped, so those are the only possible culprits. The `ragel`/compiler
diagnostics themselves go to `STDERR`.

## Captures

Captures are returned positionally by `match`, in the order their
placeholders appear in the pattern. Placeholder names are not used at match
time.

Where a segment puts a placeholder next to something else, the boundary
between them must be decidable as the bytes arrive. The generated machine is
a DFA and cannot backtrack, so a boundary it cannot settle on the spot is
settled greedily and the captures can come back wrong. Two shapes are
affected, both confined to a single segment:

- A placeholder followed by literal text its own type would also accept, where
the literal's first byte occurs again later in the literal. One placeholder is
enough: `/:a<string>ff` on `/xff` reports `a` as `'xf'`, and
`/:a<string>.tar.gz` on `/x.tar.gz` reports `'x.tar'`. Neither is a
reading of the pattern. A literal whose first byte does not recur (`_extra`,
`.json`, `-v2`) splits correctly.
- Placeholders with nothing between them, where the second one's type sets a
minimum length. The greedy split can leave that capture shorter than its own
type allows: `/:a<[0-9]*>:b<[0-9]{2,3}>` on `/90` reports `b` as
`'0'`. A valid reading existed (`a` empty, `b` `'90'`); the machine just
did not take it.

Denser versions of these can leave a capture closed before it opened; `match`
`croak`s naming the pattern rather than returning nonsense. Separate the
placeholders with a literal the preceding type cannot begin with and the split
is exact: `/:a<int>-:b<int>` on `/12-34` gives `12` and `34`,
`/:name<[a-z]+>.:ext<[a-z]+>` on `/img.png` gives `img` and `png`.
A placeholder that occupies its whole segment, the usual case, has no boundary
to get wrong and is never affected.

## Examples

    /users # static
    /users/:id # untyped placeholder, matches any non-slash
    /users/:id<int> # typed: digits only
    /blog/:year<int>/:month<int> # multiple typed placeholders
    /v/:major<int>.:minor<int> # multiple placeholders in one segment
    /file/:name<[a-z0-9\-]+>.:ext<[a-z]+> # inline + raw character classes
    /path/to_:type<string>/id_:id<int>/end # mixed literals and placeholders

## Caveats

Any `:` inside a segment introduces a placeholder; there is no escaping
mechanism. Avoid literal colons in path segments.

# SECURITY

**Route patterns are code.** `compile` turns them into C source and runs a C
compiler over it, so a pattern is closer to `eval` than to a configuration
value. Treat the pattern list with the same trust you give the program text:
never build it from a request parameter, an uploaded file, an untrusted
database row, or a plugin you would not let run arbitrary code.

`compile` rejects the type-expression constructs that most obviously reach the
C compiler (see ["Type constraints"](#type-constraints)), which turns a typo into a clear error.
Ragel is a full grammar language, though, and that check is not a sandbox. If
patterns must come from somewhere less trusted than your codebase, validate
them against your own allowlist, or build the routing table in code and let the
untrusted input only select from it.

Paths passed to `match` are **data**, not code, and need no such care: the
compiled machine only walks bytes. An embedded NUL does not truncate a path and
cannot be used to slip past a route.

# DEPLOYMENT

The compiled Ragel machine lives in a shared library that [Inline::C](https://metacpan.org/pod/Inline%3A%3AC)
`dlopen`s into the process; the function pointer is stored on the router
object. To avoid every worker compiling its own copy, **call `compile`
once in the parent process before forking**:

    # in app.psgi or equivalent startup code
    my $router = MyApp->build_router; # calls Router::Ragel->compile
    # then exec the server with --preload-app or equivalent so children
    # inherit the loaded .so via copy-on-write

If the cache is cold and several workers reach `compile` concurrently,
[Inline::C](https://metacpan.org/pod/Inline%3A%3AC) serializes them on an exclusive lock over the [Inline](https://metacpan.org/pod/Inline)
directory, so the builds run one after another instead of trampling a shared
build directory. Taking turns is not sharing, though: every worker still runs
`ragel` and the C compiler for itself, so N workers cost N builds and the
last one waits out all the others. Compiling in the parent before the fork
avoids the queue entirely.

For deterministic startup, populate the [Inline::C](https://metacpan.org/pod/Inline%3A%3AC) cache at build/deploy
time and ship the warmed directory with the artifact (e.g., bake `_Inline/`
into your Docker image). Pin the cache location for reproducibility:

    use Inline Config => DIRECTORY => '/opt/myapp/inline';
    use Router::Ragel;

The directory must already exist: [Inline](https://metacpan.org/pod/Inline) checks it and will not create it,
and the resulting error names `Router::Ragel` rather than the `Config` line.

The generated machine is named after the route patterns, so a warmed cache
hits regardless of how many routers the process built first, and two routers
sharing a pattern list share one compiled library (their route _data_ still
differs -- that lives on the Perl object). Recompiling a router whose patterns
have not changed costs nothing.

The `use Inline Config` line must be evaluated before `Router::Ragel` is
loaded (place it in the same file above `use Router::Ragel`, or in a
**BEGIN** block that runs first). Once `Router::Ragel` is loaded, the cache
location is fixed.

The compiled `.so` is architecture- and Perl-version-specific; build the
cache on the same target as production.

# PERFORMANCE

Indicative numbers from `eg/bench.pl` (Linux x86\_64, single core; matches
per second across seven mixed routes and six paths):

                       Rate   Mojo R3(method) R3(fun) XS(fun) UR(method) UR(fun) Ragel(method) Ragel(fun)
    Mojo             9166/s     --       -97%    -97%    -99%       -99%    -99%          -99%       -99%
    R3(method)     319956/s  3391%         --     -4%    -55%       -56%    -60%          -68%       -74%
    R3(fun)        332160/s  3524%         4%      --    -53%       -55%    -59%          -66%       -73%
    XS(fun)        713678/s  7686%       123%    115%      --        -3%    -11%          -28%       -42%
    UR(method)     735486/s  7924%       130%    121%      3%         --     -9%          -26%       -41%
    UR(fun)        804357/s  8675%       151%    142%     13%         9%      --          -19%       -35%
    Ragel(method)  988728/s 10687%       209%    198%     39%        34%     23%            --       -20%
    Ragel(fun)    1238754/s 13414%       287%    273%     74%        68%     54%           25%         --

Run `eg/bench.pl` to reproduce locally; routers that aren't installed are
skipped.

# LIMITATIONS

- Matching runs over the bytes Perl currently holds for the SV, so patterns and
paths must be **byte strings**. `compile` `croak`s on a pattern containing
characters above `255`. For paths the difference is invisible at the Perl
level and does matter: `"/caf\x{e9}"` stored as Latin-1 and the same string
after `utf8::upgrade` are `eq` to each other but match differently, and
captures always come back as byte strings with the UTF-8 flag off. Encode
before matching and decode the captures:

        my ($h, @cap) = $router->match(Encode::encode_utf8($path));

    Paths taken straight from a web server (PSGI's `REQUEST_URI`, and
    `PATH_INFO` on most servers) are already byte strings.

- A router holds the address of its compiled matcher, which is meaningful only
inside the process that built it. [Storable](https://metacpan.org/pod/Storable) `freeze`/`dclone` therefore
serialize the routes alone; a thawed router `croak`s `"compile() not
called"` until you call `compile` on it again. Do not pass routers between
processes by any other serializer without doing the same.

    Routers frozen by 0.04 or earlier predate those hooks: their blobs carry the
    raw address, and nothing on the reading side can tell it from a live one.
    Rebuild those from their patterns instead of thawing them.

- Patterns must start with `/` and must not be empty, contain a NUL byte,
contain consecutive slashes, use a bare `:` placeholder name, or contain a
`<type>` that is empty, unterminated, contains a `<` or a `/`, or
uses constructs outside the accepted Ragel subset (see
["Type constraints"](#type-constraints)). `compile` `croak`s on any of these.
- A segment that packs a placeholder against a literal or another placeholder
can have its captures split wrongly, and the densest of those shapes make
`match` `croak`; see ["Captures"](#captures).
- Matching is exact: `/users` matches only `/users`, not `//users`,
`/users/`, or `/users//`. `/users` and `/users/` are distinct routes.
Normalize input ahead of `match` to fold repeated or trailing slashes.
- Adding a route after `compile` invalidates the compiled matcher; `match`
`croak`s until you re-run `compile`. Every distinct route set `dlopen`s a
shared library that stays loaded for the lifetime of the process, so a program
that keeps building routers with new patterns keeps accumulating libraries.
Recompiling an unchanged route set, or compiling a second router with the same
patterns, reuses the library already loaded. See ["DEPLOYMENT"](#deployment) for the
implications under pre-forking servers.
- Calling `match` before `compile` `croak`s.
- When several routes match the same path, the **most recently added** route
wins; see ["Route precedence"](#route-precedence).

# SEE ALSO

- [Router::R3](https://metacpan.org/pod/Router%3A%3AR3)
- [Router::XS](https://metacpan.org/pod/Router%3A%3AXS)
- [URI::Router](https://metacpan.org/pod/URI%3A%3ARouter)
- [Mojolicious::Routes](https://metacpan.org/pod/Mojolicious%3A%3ARoutes)
- [Inline::C](https://metacpan.org/pod/Inline%3A%3AC)
- [Inline::Filters::Ragel](https://metacpan.org/pod/Inline%3A%3AFilters%3A%3ARagel)

# AUTHOR

vividsnow

# LICENSE AND COPYRIGHT

Copyright (c) 2026 vividsnow.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.
