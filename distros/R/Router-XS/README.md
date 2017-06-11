# NAME

Router::XS - Fast URI path to value lookup

# SYNOPSIS

    use Router::XS ':all';

    my $user_home_page = sub  { ... };

    add_route('/user/*', $user_home_page);
    my ($sub, @captures) = check_route('/user/foobar');

    # or use HTTP method verbs to add routes
    get '/user/*' => sub { ... };

    my ($sub, @captures) = check_route('GET/user/foobar');

# FUNCTIONS

## add\_route ($path, $sub)

Adds a new route associated with a subroutine to the router. Will `die` if a
matching route has already been added. Accepts asterisks (`*`) as wildcards
for captures. `$path` may be prepended with an HTTP method:

    add_route('POST/some/path', $sub);

## check\_route ($path)

Checks a URI path against the added routes and returns `undef` if no match is
found, otherwise returning the associated subroutine reference and any captures
from wildcards:

    my ($sub, @captures) = check_route('POST/some/path');

## get/post/put/patch/del/head/conn/options/any

Sugar for `add_route`: adds a route using `$path` for the associated HTTP
method:

    put '/product/*' => sub { ... };

The `any` function accepts any HTTP method. When an incoming request is
received, `check_route` must still be called.

See the test file included in this distribution for further examples.

# THREAD SAFETY

Router::XS is not thread safe: however if you add all routes at the startup of
an application under a single thread, and do not call `add_route` thereafter,
it should be thread safe.

# BENCHMARKS

On my machine Router::XS performs well against other fast Routers. The test
conditions add 200 routes, and then check how fast the router can match the
path '/interstitial/track':

                       Rate  Router::Boom  Router::R3  Router::XS
    Router::Boom   344536/s            --        -85%        -93%
    Router::R3    2235343/s          549%          --        -54%
    Router::XS    4860641/s         1311%        117%          --

## DEPENDENCIES

This module uses [uthash](http://troydhanson.github.com/uthash/) to build a
n-ary tree of paths. `uthash` is a single C header file, included in this
distribution. uthash is copyright (c) 2003-2017, Troy D. Hanson.

# INSTALLATION

    perl Makefile.PL
    make
    make test
    make install

# AUTHOR

© 2017 David Farrell

# LICENSE

The (two-clause) FreeBSD License

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com) for letting their employees contribute to Open Source.

# SEE ALSO

There are many routers on [CPAN](https://metacpan.org/search?size=20&q=Router) including:

- [HTTP::Router](https://metacpan.org/pod/HTTP::Router)
- [Path::Router](https://metacpan.org/pod/Path::Router)
- [Router::Boom](https://metacpan.org/pod/Router::Boom)
- [Router::R3](https://metacpan.org/pod/Router::R3)
