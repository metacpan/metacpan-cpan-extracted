[![Build Status](https://travis-ci.org/tarao/perl5-Plack-Middleware-StackTrace-RethrowFriendly.svg?branch=master)](https://travis-ci.org/tarao/perl5-Plack-Middleware-StackTrace-RethrowFriendly)
# NAME

Plack::Middleware::StackTrace::RethrowFriendly - Display the original stack trace for rethrown errors

# SYNOPSIS

    use Plack::Builder;
    builder {
        enable "StackTrace::RethrowFriendly";
        $app;
    };

# DESCRIPTION

This middleware is the same as [Plack::Middleware::StackTrace](https://metacpan.org/pod/Plack::Middleware::StackTrace) except
that additional information for rethrown errors are available for HTML
stack trace.

If you catch (`eval` or `try`-`catch` for example) an error and
rethrow (`die` or `croak` for example) it, all the errors including
rethrown ones are visible through the throwing point selector at the
top of the HTML.

For example, consider the following code.

    sub fail {
        die 'foo';
    }

    sub another {
        fail();
    }

    builder {
        enable 'StackTrace';

        sub {
            eval { fail() }; # (1)
            another();       # (2)

            return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ];
        };
    };

[Plack::Middleware::StackTrace](https://metacpan.org/pod/Plack::Middleware::StackTrace) blames (1) since it is the first
place where `'foo'` is raised.  This behavior may be misleading if
the real culprit was something done in `another`.

`Plack::Middleware::StackTrace::RethrowFriendly` displays stack
traces of both (1) and (2) in each page and (1) is selected by
default.

# SEE ALSO

[Plack::Middleware::StackTrace](https://metacpan.org/pod/Plack::Middleware::StackTrace)

# LICENSE

Copyright (C) TOYAMA Nao and INA Lintaro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

TOYAMA Nao <nanto@moon.email.ne.jp>

INA Lintaro <tarao.gnn@gmail.com>
