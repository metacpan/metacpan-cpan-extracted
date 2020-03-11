# NAME

Plack::Middleware::Security::Simple - A simple security filter for Plack

# VERSION

version v0.4.1

# SYNOPSIS

```perl
use Plack::Builder;

builder {

  enable "Security::Simple",
      rules => [
          PATH_INFO       => qr{^/cgi-bin/},
          PATH_INFO       => qr{\.(php|asp)$},
          HTTP_USER_AGENT => qr{BadRobot},
      ];

 ...

};
```

# DESCRIPTION

This module provides a simple security filter for PSGI-based
applications, so that you can filter out obvious exploit-seeking
scripts.

Note that as an alternative, you may want to consider using something like
[modsecurity](https://modsecurity.org/) as a filter in a reverse proxy.

# ATTRIBUTES

## rules

This is a set of rules. It can be a an array-reference or
[Hash::Match](https://metacpan.org/pod/Hash::Match) object containing matches against keys in the Plack
environment.

It can also be a code reference for a subroutine that takes the Plack
environment as an argument and returns a true value if there is a
match.

See [Plack::Middleware::Security::Common](https://metacpan.org/pod/Plack::Middleware::Security::Common) for a set of common rules.

## handler

This is a function that is called when a match is found.

It takes the Plack environment as an argument, and returns a
[Plack::Response](https://metacpan.org/pod/Plack::Response), or throws an exception for
[Plack::Middleware::HTTPExceptions](https://metacpan.org/pod/Plack::Middleware::HTTPExceptions).

The default handler will log a warning to the `psgix.logger`, and
return a HTTP 400 (Bad Request) response.

The message is of the form

```
Plack::Middleware::Security::Simple Blocked $ip $method $path_query HTTP $status
```

This can be used if you are writing [fail2ban](https://metacpan.org/pod/fail2ban) filters.

## status

This is the HTTP status code that the default ["handler"](#handler) will return
when a resource is blocked.  It defaults to 400 (Bad Request).

# SEE ALSO

[Hash::Match](https://metacpan.org/pod/Hash::Match)

[Plack](https://metacpan.org/pod/Plack)

[PSGI](https://metacpan.org/pod/PSGI)

# SOURCE

The development version is on github at [https://github.com/robrwo/Plack-Middleware-Security-Simple](https://github.com/robrwo/Plack-Middleware-Security-Simple)
and may be cloned from [git://github.com/robrwo/Plack-Middleware-Security-Simple.git](git://github.com/robrwo/Plack-Middleware-Security-Simple.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Plack-Middleware-Security-Simple/issues](https://github.com/robrwo/Plack-Middleware-Security-Simple/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2014,2018-2020 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
