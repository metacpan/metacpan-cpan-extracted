# NAME

Plack::Middleware::Static::OpenFileCache - Plack::Middleware::Static with open file cache

# SYNOPSIS

    use Plack::Middleware::Static::OpenFileCache;

    builder {
        enable "Plack::Middleware::Static",
            path => qr{^/(images|js|css)/},
            root => './htdocs/',
            max  => 100,
            expires => 60,
            buf_size => 8192,
            cache_errors => 1;
        $app;
    };

# DESCRIPTION

Plack::Middleware::Static::OpenFileCache enables Plack::Middleware::Static 
to cache open file like nginx. This middleware cache opened file handles and their
sizes and modification times for faster contents serving. 

# CONFIGURATIONS

- max

    Maximum number of items in cache. If cache is overflowed, items are removed by LRU.
    (100 by default)

- expires

    Expires seconds. 60 by default

- buf\_size

    If content size of static file is smaller than buf\_size. 
    Plack::Middleware::Static::OpenFileCache reads all to memory. 8192 byte by default.

- cache\_errors

    If enabled, this middleware cache response if status is 40x. Disabled by default.

# BENCHMARK

benchmark with ApacheBench and [Monoceros](http://search.cpan.org/perldoc?Monoceros)

- benchmark on larger file

        Document Path:          /static/jquery-1.10.2.min.js
        Document Length:        93107 bytes
        

        Static                Requests per second:    1219.47 [#/sec] (mean)
        Static::OpenFileCache Requests per second:    1483.52 [#/sec] (mean)
- benchmark on small file

        Document Path:          /static/cpanfile
        Document Length:        160 bytes
        

        Static                 Requests per second:    2018.13 [#/sec] (mean)
        Static::OpenFileCache  Requests per second:    2813.08 [#/sec] (mean)

# LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masahiro Nagano <kazeburo@gmail.com>
