[![Build Status](https://travis-ci.org/dex4er/perl-Plack-Middleware-Proxy-Connect-IO.svg?branch=master)](https://travis-ci.org/dex4er/perl-Plack-Middleware-Proxy-Connect-IO)[![CPAN version](https://badge.fury.io/pl/Plack-Middleware-Proxy-Connect-IO.svg)](https://metacpan.org/release/Plack-Middleware-Proxy-Connect-IO)

# NAME

Plack::Middleware::Proxy::Connect::IO - CONNECT method

# SYNOPSIS

    # In app.psgi
    use Plack::Builder;
    use Plack::App::Proxy;

    builder {
        enable "Proxy::Connect::IO";
        enable "Proxy::Requests";
        Plack::App::Proxy->new->to_app;
    };

# DESCRIPTION

This middleware handles the `CONNECT` method. It allows to connect to
`https` addresses.

The middleware runs on servers supporting `psgix.io` and provides own
event loop so does not work correctly with `psgi.nonblocking` servers.

The middleware uses only Perl's core modules: [IO::Socket::INET](https://metacpan.org/pod/IO::Socket::INET) and
[IO::Select](https://metacpan.org/pod/IO::Select).

# SEE ALSO

[Plack](https://metacpan.org/pod/Plack), [Plack::App::Proxy](https://metacpan.org/pod/Plack::App::Proxy), [Plack::Middleware::Proxy::Connect](https://metacpan.org/pod/Plack::Middleware::Proxy::Connect).

# BUGS

If you find the bug or want to implement new features, please report it at
[https://github.com/dex4er/perl-Plack-Middleware-Proxy-Connect-IO/issues](https://github.com/dex4er/perl-Plack-Middleware-Proxy-Connect-IO/issues)

The code repository is available at
[http://github.com/dex4er/perl-Plack-Middleware-Proxy-Connect-IO](http://github.com/dex4er/perl-Plack-Middleware-Proxy-Connect-IO)

# AUTHOR

Piotr Roszatycki <dexter@cpan.org>

# LICENSE

Copyright (c) 2014, 2016 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See [http://dev.perl.org/licenses/artistic.html](http://dev.perl.org/licenses/artistic.html)
