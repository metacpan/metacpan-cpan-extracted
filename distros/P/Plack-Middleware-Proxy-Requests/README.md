# NAME

Plack::Middleware::Proxy::Requests - Forward proxy server

# SYNOPSIS

    # In app.psgi
    use Plack::Builder;
    use Plack::App::Proxy;

    builder {
        enable "Proxy::Connect";
        enable "Proxy::AddVia";
        enable "Proxy::Requests";
        Plack::App::Proxy->new->to_app;
    };

    # From shell
    plackup -s Twiggy -E Proxy -e 'enable q{AccessLog}' app.psgi

    # or
    twiggy -MPlack::App::Proxy \
           -e 'enable q{AccessLog}; enable q{Proxy::Connect}; \
               enable q{Proxy::AddVia}; enable q{Proxy::Requests}; \
               Plack::App::Proxy->new->to_app'

# DESCRIPTION

This module handles HTTP requests as a forward proxy server.

Its job is to set a `plack.proxy.url` environment variable based on
`REQUEST_URI` variable.

The HTTP responses from the Internet might be invalid. In that case it
is required to run the server without [Plack::Middleware::Lint](http://search.cpan.org/perldoc?Plack::Middleware::Lint) module.
This module is started by default and disabled if `-E` or
`--no-default-middleware` option is used when starting [plackup](http://search.cpan.org/perldoc?plackup)
script. Note that this disable also [Plack::Middleware::AccessLog](http://search.cpan.org/perldoc?Plack::Middleware::AccessLog) so
it have to be enabled explicitly if needed.

The default server [Plack::Server::PSGI](http://search.cpan.org/perldoc?Plack::Server::PSGI) alias `Standalone` can hang
up on stalled connection. It is better to run proxy server with
[Starlet](http://search.cpan.org/perldoc?Starlet), [Starman](http://search.cpan.org/perldoc?Starman) or [Twiggy](http://search.cpan.org/perldoc?Twiggy).

# SEE ALSO

[Plack](http://search.cpan.org/perldoc?Plack), [Plack::App::Proxy](http://search.cpan.org/perldoc?Plack::App::Proxy), [Plack::Middleware::Proxy::Connect](http://search.cpan.org/perldoc?Plack::Middleware::Proxy::Connect),
[Plack::Middleware::Proxy::AddVia](http://search.cpan.org/perldoc?Plack::Middleware::Proxy::AddVia), [Starlet](http://search.cpan.org/perldoc?Starlet), [Starman](http://search.cpan.org/perldoc?Starman), [Twiggy](http://search.cpan.org/perldoc?Twiggy).

# BUGS

If you find the bug or want to implement new features, please report it at
[https://github.com/dex4er/perl-Plack-Middleware-Proxy-Requests/issues](https://github.com/dex4er/perl-Plack-Middleware-Proxy-Requests/issues)

The code repository is available at
[http://github.com/dex4er/perl-Plack-Middleware-Proxy-Requests](http://github.com/dex4er/perl-Plack-Middleware-Proxy-Requests)

# AUTHOR

Piotr Roszatycki <dexter@cpan.org>

# LICENSE

Copyright (c) 2012-2013 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See [http://dev.perl.org/licenses/artistic.html](http://dev.perl.org/licenses/artistic.html)
