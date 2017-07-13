# NAME

Routes::Tiny - Routes

# SYNOPSIS

    my $routes = Routes::Tiny->new;

    # Constraints
    $routes->add_route('/articles/:id', constraints => {id => qr/\d+/});

    # Optional placeholders
    $routes->add_route('/archive/:year/(:month)?');

    # Defaults
    $routes->add_route('/articles/:id',
        defaults => {controller => 'bar', action => 'foo'});

    # Grouping (matches 'hello-bar')
    $routes->add_route('/(:foo)-bar');

    # Globbing (matches 'photos/foo/bar/baz')
    $routes->add_route('/photos/*other');

    # Path building
    $routes->add_route('/:foo/:bar', name => 'default');
    $routes->build_path('default', foo => 'hello', bar => 'world');

    # Matching
    my $match = $routes->match('/hello/world');
    my $captures_hashref = $match->captures;

    # Matching with method
    $routes->add_route('/hello/world', method => 'GET');
    my $match = $routes->match('/hello/world', method => 'GET');

    # Subroutes
    my $subroutes = Routes::Tiny->new;
    $subroutes->add_route('/article/:id');
    $routes->mount('/admin/', $subroutes);

# DESCRIPTION

[Routes::Tiny](https://metacpan.org/pod/Routes::Tiny) is a lightweight routes implementation.

[Routes::Tiny](https://metacpan.org/pod/Routes::Tiny) aims to be easy to use in any web framework.

# FEATURES

## `Constraints`

    $routes->add_route('/articles/:id', constraints => {id => qr/\d+/});

    $match = $routes->match('/articles/1');  # Routes::Tiny::Match object
    $match = $routes->match('/article/foo'); # undef

It is possible to specify a constraint that a placeholder must match using a
normal Perl regular expression.

Constraints can be passed as array references:

    $routes->add_route('/articles/:action',
        constraints => {action => [qw/add update/]});

    $match = $routes->match('/articles/add');    # Routes::Tiny::Match object
    $match = $routes->match('/articles/delete'); # undef

## `Optional placeholders`

    $routes->add_route('/admin/:service(/:action)?', defaults => {action => 'list'});

    my $match = $routes->match('/admin/foo');
    # $m->captures is {service => 'foo', action => 'list'}

It is possible to specify an optional placeholder with a default value.

## `Grouping`

    $routes->add_route('/(:foo)-bar');

    $match = $routes->match('/hello-bar');
    # $match->captures is {foo => 'hello'}

It is possible to create a placeholder that doesn't occupy all the space between
slashes.

## `Globbing`

    $routes->add_route('/photos/*other');
    $routes->add_route('/books/*section/:title');
    $routes->add_route('/*a/foo/*b');

    $match = $routes->match('photos/foo/bar/baz');
    # $match->captures is {other => 'foo/bar/baz'}

    $match = $routes->match('books/some/section/last-words-a-memoir');
    # $match->captures is {section => 'some/section', title => 'last-words-a-memoir'}

    $match = $routes->match('zoo/woo/foo/bar/baz');
    # $match->captures is {a => 'zoo/woo', b => 'bar/baz'}

It is possible to specify a globbing placeholder.

## `Passing arguments AS IS`

    $routes->add_route('/', arguments => {one => 'two'});

    $match = $routes->match('/');
    # $match->arguments is {one => 'two'}

It is possible to pass arguments to the match object AS IS.

## `Matching with methods`

    # Exact HTTP method definition
    $routes->add_route('/articles', method => 'GET', defaults => {action => 'list'});

    # Sweeter method definition
    # METHOD => PATTERN should go as first parameters to add_route()
    $routes->add_route(PUT => '/articles', defaults => {action => 'create'});

    $match = $routes->match('/articles', method => 'GET');
    # $m->captures is {action => 'list'}

    $match = $routes->match('/articles', method => 'PUT');
    # $m->captures is {action => 'create'}

## `Subroutes`

    $subroutes = Routes::Tiny->new;
    $subroutes->add_route('/articles/:id', name => 'admin-article');
    $routes->mount('/admin/', $subroutes);

    $match = $routes->match('/admin/articles/3/');
    # $match->captures is {id => 3}

It is possible to capture params in mount routes

    $subroutes = Routes::Tiny->new;
    $subroutes->add_route('/comments/:page/', name => 'comments');
    $routes->mount('/:type/:id/', $subroutes);

    $match = $routes->match('/articles/3/comments/5/');
    # $match->captures is {page => 5}
    # $match->parent->captures is {type => 'articles', id => 3}

Parent routes mounts names of children routes, so it's possible to buil path

    $path = $routes->build_path('admin-article', id => 123);
    # $path is '/admin/articles/123'
    $path = $routes->build_path('comments', type => 'articles', id => 123, page => 5);
    # $path is '/articles/123/comments/5/'

## `Path building`

    $routes->add_route('/articles/:id', name => 'article');

    $path = $routes->build_path('article', id => 123);
    # $path is '/articles/123'

It is possible to reconstruct a path from route's name and parameters.

# WARNINGS

## `Trailing slash issue`

Trailing slash is important.

    $routes->add_route('/articles');

    # is different from

    $routes->add_route('/articles/');

If you don't want this behaviour pass `strict_trailing_slash` to the constructor:

    my $routes = Routes::Tiny->new(strict_trailing_slash => 0);

## `Case sensitivity`

Routes::Tiny is case sensitive by default (since 0.20).

It means that

    $routes->add_route('/admin/');

will NOT match both `/admin/` and `/ADMIN/`.

If you don't want this behaviour pass `strict_case` to the constructor:

    my $routes = Routes::Tiny->new(strict_case => 0);

# METHODS

## `new`

    my $routes = Routes::Tiny->new;

## `add_route`

    $routes->add_route('/:service/:action');

Add a new route.

## `mount`

    $routes->mount('/admin/', $subroutes)

Includes one Routes::Tiny instance into another with given prefix.

## `match`

    $routes->match('/hello/world');

Match against a path.

## `build_path`

    $pattern->build_path('name', {foo => 'bar'});

Build path from a given name and params.

# DEVELOPMENT

## Repository

    http://github.com/vti/routes-tiny

# CREDITS

Sergey Zasenko (und3f)

Roman Galeev (jamhed)

Dmitry Smal (mialinx)

Dinar (ziontab)

Jonathan R. Warden

Alexander Batyrshin

Konstantin Cherednichenko

# AUTHOR

Viacheslav Tykhanovskyi, `vti@cpan.org`.

# COPYRIGHT AND LICENSE

Copyright (C) 2011-2017, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.
