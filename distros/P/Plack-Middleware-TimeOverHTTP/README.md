# NAME

Plack::Middleware::TimeOverHTTP - time over HTTP middleware

# VERSION

version v0.1.2

# SYNOPSIS

```perl
use Plack::Builder;

my $app = sub { ... };

builder {

  enable "TimeOverHTTP";

  $app;
};
```

# DESCRIPTION

This middleware adds a simplified implementation of the Time
over HTTP specification at the URL “/.well-known/time”.

It does not enforce any restrictions on the request headers.

This middleware does not implement rate limiting or restrictions based
on IP address. You will need to use additional middleware for that.

# SEE ALSO

The "Time Over HTTPS specification" at
[http://phk.freebsd.dk/time/20151129/](http://phk.freebsd.dk/time/20151129/).

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
