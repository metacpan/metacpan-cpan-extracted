# NAME

Plack::Middleware::BetterStackTrace - Displays better stack trace when your app dies

# SYNOPSIS

    enable 'BetterStackTrace',
        application_caller_subroutine => 'Amon2::Web::handle_request';

# DESCRIPTION

This middleware catches exceptions (run-time errors) happening in your
application and displays nice stack trace screen. The stack trace is
also stored in the environment as a plaintext and HTML under the key
`plack.stacktrace.text` and `plack.stacktrace.html` respectively, so
that middleware futher up the stack can reference it.

You're recommended to use this middleware during the development and
use [Plack::Middleware::HTTPExceptions](http://search.cpan.org/perldoc?Plack::Middleware::HTTPExceptions) in the deployment mode as a
replacement, so that all the exceptions thrown from your application
still get caught and rendered as a 500 error response, rather than
crashing the web server.

Catching errors in streaming response is not supported.

This module is based on [Plack::Middleware::StackTrace](http://search.cpan.org/perldoc?Plack::Middleware::StackTrace) and Better Errors for Ruby [https://github.com/charliesome/better\_errors](https://github.com/charliesome/better\_errors).

# LICENSE

Perl

Copyright (C) Tasuku SUENAGA a.k.a. gunyarakun.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

HTML/CSS/JavaScript

Copyright (C) 2012 Charlie Somerville

MIT License

# AUTHOR

Tasuku SUENAGA a.k.a. gunyarakun <tasuku-s-github@titech.ac>

# TODO

\- REPL
\- JSON response

# SEE ALSO

[Plack::Middleware::StackTrace](http://search.cpan.org/perldoc?Plack::Middleware::StackTrace) [Devel::StackTrace::AsHTML](http://search.cpan.org/perldoc?Devel::StackTrace::AsHTML) [Plack::Middleware](http://search.cpan.org/perldoc?Plack::Middleware) [Plack::Middleware::HTTPExceptions](http://search.cpan.org/perldoc?Plack::Middleware::HTTPExceptions)
