# NAME

Plack::Middleware::TrafficAdvice - handle requests for /.well-known/traffic-advice

# VERSION

version v0.1.0

# SYNOPSIS

```perl
use JSON::MaybeXS;
use Plack::Builder;

builder {

  enable "TrafficAdvice",
    data => [
      {
          user_agent => "prefetch-proxy",
          disallow   => JSON::MaybeXS->true,
      }
    ];

  ...

};
```

# DESCRIPTION

This middle provides a handler for requests for `/.well-known/traffic-advice`.

You must specify either a ["file"](#file) or ["data"](#data) containing the traffic
advice information.

# ATTRIBUTES

## data

This is either an array referece that corresponds to the traffic advice data structure,
or a JSON string to return.

The data will be saved as a temporary ["file"](#file).

## file

This is a file containing the JSON string to return.

# SEE ALSO

[https://github.com/buettner/private-prefetch-proxy/blob/main/traffic-advice.md](https://github.com/buettner/private-prefetch-proxy/blob/main/traffic-advice.md)

# SOURCE

The development version is on github at [https://github.com/robrwo/Plack-Middleware-TrafficAdvice](https://github.com/robrwo/Plack-Middleware-TrafficAdvice)
and may be cloned from [git://github.com/robrwo/Plack-Middleware-TrafficAdvice.git](git://github.com/robrwo/Plack-Middleware-TrafficAdvice.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Plack-Middleware-TrafficAdvice/issues](https://github.com/robrwo/Plack-Middleware-TrafficAdvice/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
