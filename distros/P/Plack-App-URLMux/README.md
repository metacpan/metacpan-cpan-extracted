# NAME

Plack::App::URLMux - PSGI/Plack component for dispatching multiple applications based on URL path, host names and patterns.


# DESCRIPTION

Dispatch absolute URL to a PSGI application with additional parameters defined by URL format rules or parameters specified at binding URL to application.
This packge based on Plack::App::URLMap but optimized for multiplexing a lof of URLs and dispatching by URL patterns.

    use Plack::App::URLMux;

    my $app1 = sub { ... };
    my $app2 = sub { ... };
    my $app3 = sub { ... };

    my $urlmap = Plack::App::URLMux->new;
    $urlmap->map("/" => $app1, foo => bar);
    $urlmap->map("/foo/:name/bar" => $app2);
    $urlmap->map("/foo/test/bar"  => $app3);
    $urlmap->map("http://bar.example.com/" => $app4);
    $urlmap->map("/foo/:bar+/:baz*/zoo" => $app4);

    my $app = $urlmap->to_app;

Rule for URL with parameters /foo/:name/bar will dispatch to any URL which contains /foo/some/bar and call $app2 with additional parameters
at Plack environment 'plack.URLMux.params.url' as array of pairs name => 'some'. If you mount /for/test/bar the same time, then for this URL
/for/test/bar dispatching will be exactly to $app3 to this URL without parameters but other URLs contains anything between /foo/ and /bar will be
dispatched to $app2 with parameter 'name'.

Format for parameters ':name', parameter names may be repeated, package returned values as array of pairs name => value in order as they meet in URL.

When mapping URL is it posible to define additional parameters to application as array of pairs name=>value that will be avaialbe in application at
Plack environment 'plack.urlmux.params.map'.

URL pattern may specified in url as ':', after URL path delimiter '/', parameter name as alphanum and regexp quantifier '+|*|{n,m}' and greedy/lazy flag '?'.
Muliplexer transforms patterns in URL into list of named parameters with values as array of parsed parts of URL. This paramaters available to application as
Plack environment 'plack.urlmux.params.map'.

# EXAMPLE PSGI SERVER

Example of psgi application

For testing there is scripts to setup and start example psgi application under standalone web server gazelle

To setup web server in local directory:

    sh ./example/setup

To start web server:

    sh ./example/gazelle

To test web server try this URLs at browser:

* http://localhost:8080/foo/test/baz
* http://localhost:8080/foo/bar/baz
* http://localhost:8080/foo/bar/foo

To try different Plack or AnyEvent based web server look at [AnyEvent-HTTP-Server-II](https://github.com/Mons/AnyEvent-HTTP-Server-II).

# BENCHMARK

Compare performanse of this module with Plack::App::URLMux on over of 300 URLs

    ./benchmark/run

    Benchmark: running url_map, url_tree for at least 10 CPU seconds...
        url_map:  9 wallclock secs (10.05 usr +  0.00 sys = 10.05 CPU) @ 23.78/s (n=239)
        url_tree: 10 wallclock secs (10.61 usr +  0.01 sys = 10.62 CPU) @ 162.62/s (n=1727)

    recalculate real iterations to 345 URLs

                    Rate  url_map url_tree
        url_map   8204/s       --     -85%
        url_tree 56103/s     584%       --

# AUTHOR

Aleksey Ozhigov burnes@cpan.org

# TODO

Extend rules for URL map, add quantifiers for URL parameters to bind relative URLs to application. For example ':path*/bar' bind to URL contains anything between '/' and '/bar', even nothing so '/bar' and '/foo/bar' and '/foo/baz/bar' will be dispathed to one application. This type of bind is supported in original package Plack::App::URLMap.

# COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

# SEE ALSO

The [Plack::App::URLMap](https://metacpan.org/pod/Plack::App::URLMap) package on which this is based.


# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
