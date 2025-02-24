# NAME

Plack::Middleware::TrafficAdvice - handle requests for /.well-known/traffic-advice

# VERSION

version v0.3.1

# SYNOPSIS

```perl
use JSON::MaybeXS 1.004000;
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
advice information. (There is no default value.)

# ATTRIBUTES

## data

This is either an array referece that corresponds to the traffic advice data structure,
or a JSON string to return.

The data will be saved as a temporary ["file"](#file).

## file

This is a file containing the JSON string to return.

# KNOWN ISSUES

The `/.well-known/traffic-advice` specification is new and may be subject to change.

This does not validate that the ["data"](#data) string or ["file"](#file) contains
valid JSON, or that the JSON conforms to the specification.

# SUPPORT FOR OLDER PERL VERSIONS

This module requires Perl v5.12 or later.

Future releases may only support Perl versions released in the last ten (10) years.

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

## Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website. Please see `SECURITY.md` for instructions how to
report security vulnerabilities

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2021-2024 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
