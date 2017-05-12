[![Build Status](https://travis-ci.org/karupanerura/p5-Plack-Middleware-HTMLLint.svg?branch=master)](https://travis-ci.org/karupanerura/p5-Plack-Middleware-HTMLLint)
# NAME

Plack::Middleware::HTMLLint - check syntax with HTML::Lint for PSGI application's response HTML

# VERSION

This document describes Plack::Middleware::HTMLLint version 0.03.

# SYNOPSIS

    use Plack::Builder;

    builder {
        enable_if { $ENV{PLACK_ENV} eq 'development' } 'HTMLLint';
        sub {
            my $env = shift;
            # ...
            return [
                200,
                ['Content-Type' => 'text/plain'],
                ['<html><head>...']
            ];
        };
    };

# DESCRIPTION

This module check syntax with HTML::Lint for PSGI application's response HTML.
to assist you to discover the HTML syntax errors during the development of Web applications.

# DEPENDENCIES

Perl 5.8.1 or later.

# BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

# SEE ALSO

[Plack::Middleware](https://metacpan.org/pod/Plack::Middleware) [Plack::Middleware::HTMLLint::Pluggable](https://metacpan.org/pod/Plack::Middleware::HTMLLint::Pluggable) [HTML::Lint](https://metacpan.org/pod/HTML::Lint) [HTML::Lint::Pluggable](https://metacpan.org/pod/HTML::Lint::Pluggable)

# AUTHOR

Kenta Sato <karupa@cpan.org>

# LICENSE AND COPYRIGHT

Copyright (c) 2012, Kenta Sato. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
