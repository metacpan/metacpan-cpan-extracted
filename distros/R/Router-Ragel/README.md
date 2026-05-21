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

# METHODS

## new

    my $router = Router::Ragel->new;

Constructs a new router. Takes no arguments.

## add

    $router->add($pattern, $data);

Registers a route. `$pattern` is a path string (see ["ROUTE PATTERNS"](#route-patterns));
`$data` is the value returned by `match` on a hit and may be any scalar.
Returns the router, so calls can be chained.

Adding a route after `compile` invalidates the compiled state; the next
`match` will `croak` until `compile` is called again.

## compile

    $router->compile;

Builds and binds the Ragel state machine. Must be called before `match`.
Returns the router. May be called more than once to incorporate routes added
between calls; see ["LIMITATIONS"](#limitations) for the cost of recompiling.

## match

    my ($data, @captures) = $router->match($path);

Matches `$path` against the compiled routes and returns the route data
followed by captured values, in pattern order. Returns the empty list on no
match.

For the lowest call overhead, invoke `match` as a plain function and skip
Perl's method dispatch:

    my ($data, @captures) = Router::Ragel::match($router, $path);

Both forms run the same compiled state machine.

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

Anything else inside `<...>` is passed verbatim to Ragel, so arbitrary
character classes and quantifiers work:

    /code/:c<[0-9]{4}> # exactly four digits
    /file/:name<[a-z0-9\-]+> # slug-like (escape '-' inside a class)

The dialect is **Ragel's**, not Perl/PCRE. Available: character classes,
quantifiers (`*`, `+`, `?`, `{n}`, `{n,m}`), alternation, grouping, and
Ragel keywords (`digit`, `alpha`, `alnum`, `xdigit`, `lower`, `upper`,
`space`, `punct`, `print`, `ascii`, `any`). **Not** available: Perl
shortcuts (`\d`, `\w`, `\s`), anchors, lookaround, and backreferences.
Anchors are unnecessary anyway: segment boundaries are implicit.

A literal `>` cannot appear inside a `<type>` expression (the
parser closes the type at the first `>`); a literal `<` is
rejected at compile time. A literal `-` inside a character class must
be escaped as `\-` (Ragel parses an unescaped `-` as a range
operator and errors out, even at the start or end of the class). For any of
these, match a permissive class and post-process in user code.

## Captures

Captures are returned positionally by `match`, in the order their
placeholders appear in the pattern. Placeholder names are not used at match
time.

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
[Inline::C](https://metacpan.org/pod/Inline%3A%3AC) serializes them on a directory lock and only one process runs
the C compiler -- the rest `dlopen` the resulting `.so`. That avoids the
`cc`/`ragel` stampede but every worker still pays the wait. Compiling in
the parent before fork eliminates the wait too.

For deterministic startup, populate the [Inline::C](https://metacpan.org/pod/Inline%3A%3AC) cache at build/deploy
time and ship the warmed directory with the artifact (e.g., bake `_Inline/`
into your Docker image). Pin the cache location for reproducibility:

    use Inline Config => DIRECTORY => '/opt/myapp/inline';
    use Router::Ragel;

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

- Patterns and paths are byte strings. Wide-character (utf8-flagged) strings
are matched against their UTF-8 byte representation.
- Patterns must start with `/` and must not be empty, contain a NUL byte,
contain consecutive slashes, use a bare `:` placeholder name, or contain an
empty or unterminated `<type>`. `compile` `croak`s on any of these.
- Matching is exact: `/users` matches only `/users`, not `//users`,
`/users/`, or `/users//`. `/users` and `/users/` are distinct routes.
Normalize input ahead of `match` to fold repeated or trailing slashes.
- Adding a route after `compile` invalidates the compiled matcher; `match`
`croak`s until you re-run `compile`. Each `compile` `dlopen`s a new
shared library; the previous one stays loaded for the lifetime of the
process. See ["DEPLOYMENT"](#deployment) for the implications under pre-forking servers.
- Calling `match` before `compile` `croak`s.

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
