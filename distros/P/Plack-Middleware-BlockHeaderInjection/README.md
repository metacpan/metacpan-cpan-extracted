# NAME

Plack::Middleware::BlockHeaderInjection - block header injections in responses

# VERSION

version v1.1.1

# SYNOPSIS

```perl
use Plack::Builder;

my $app = ...

$app = builder {
  enable 'BlockHeaderInjection',
    status => 500;
  $app;
};
```

# DESCRIPTION

This middleware will check responses for injected headers. If the
headers contain newlines, then the return code is set to `500` and
the offending header(s) are removed.

A common source of header injections is when parameters are passed
unchecked into a header (such as the redirection location).

An attacker can use injected headers to bypass system security, by
forging a header used for security (such as a referrer or cookie).

# ATTRIBUTES

## &lt;status

The status code to return if an invalid header is found. By default,
this is `500`.

# SUPPORT FOR OLDER PERL VERSIONS

Since v1.1.0, this module requires Perl v5.12 or later.

Future releases may only support Perl versions released in the last ten years.

If you need this module on Perl v5.8, please use one of the v1.0.x versions of this module.  Signficant bug or security
fixes may be backported to those versions.

# SEE ALSO

[https://en.wikipedia.org/wiki/HTTP\_header\_injection](https://en.wikipedia.org/wiki/HTTP_header_injection)

# SOURCE

The development version is on github at [https://github.com/robrwo/Plack-Middleware-BlockHeaderInjection](https://github.com/robrwo/Plack-Middleware-BlockHeaderInjection)
and may be cloned from [git://github.com/robrwo/Plack-Middleware-BlockHeaderInjection.git](git://github.com/robrwo/Plack-Middleware-BlockHeaderInjection.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Plack-Middleware-BlockHeaderInjection/issues](https://github.com/robrwo/Plack-Middleware-BlockHeaderInjection/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was supported by
Foxtons, Ltd [https://www.foxtons.co.uk](https://www.foxtons.co.uk).

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2014,2020,2023 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
