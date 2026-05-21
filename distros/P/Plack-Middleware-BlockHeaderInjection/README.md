# NAME

Plack::Middleware::BlockHeaderInjection - block header injections in responses

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

This middleware will check response headers for control characters (codes 0 through 31) (which also includes newlines that can be used for header injections).
These  are not allowed according to the [PSGI specification](https://metacpan.org/pod/PSGI#Headers).
If they are found, then it will the return code is set to `500` and the offending header(s) are removed.

A common source of header injections is when parameters are passed
unchecked into a header (such as the redirection location).

An attacker can use injected headers to bypass system security, by
forging a header used for security (such as a referrer or cookie).

# RECENT CHANGES

Changes for version v1.3.1 (2026-05-02)

- Documentation
    - Added link to Plack::Middleware::Lint in the SEE ALSO.
- Toolchain
    - Stopped using Module::Signature for signing modules.
- Tests
    - Changed author tests to use Test::DistManifest.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Plack::Middleware](https://metacpan.org/pod/Plack%3A%3AMiddleware)
- [experimental](https://metacpan.org/pod/experimental)
- [parent](https://metacpan.org/pod/parent)
- [perl](https://metacpan.org/pod/perl) version v5.24.0 or later
- [warnings](https://metacpan.org/pod/warnings)

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Plack::Middleware::BlockHeaderInjection
```

You can also extract the distribution archive and install this module (along with any dependencies):

```
cpan .
```

You can also install this module manually using the following commands:

```
perl Makefile.PL
make
make test
make install
```

If you are working with the source repository, then it may not have a `Makefile.PL` file.  But you can use the [Dist::Zilla](https://dzil.org/) tool in anger to build and install this module:

```
dzil build
dzil test
dzil install --install-command="cpan ."
```

For more information, see the `INSTALL` file included with this distribution.

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Plack-Middleware-BlockHeaderInjection/issues](https://github.com/robrwo/Plack-Middleware-BlockHeaderInjection/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# SOURCE

The development version is on github at [https://github.com/robrwo/Plack-Middleware-BlockHeaderInjection](https://github.com/robrwo/Plack-Middleware-BlockHeaderInjection)
and may be cloned from [https://github.com/robrwo/Plack-Middleware-BlockHeaderInjection.git](https://github.com/robrwo/Plack-Middleware-BlockHeaderInjection.git)

# AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

The initial development of this module was supported by
Foxtons, Ltd [https://www.foxtons.co.uk](https://www.foxtons.co.uk).

# CONTRIBUTOR

Graham Knop <haarg@haarg.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2026 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

# SEE ALSO

[https://en.wikipedia.org/wiki/HTTP\_header\_injection](https://en.wikipedia.org/wiki/HTTP_header_injection)

[Plack::Middleware::Lint](https://metacpan.org/pod/Plack%3A%3AMiddleware%3A%3ALint)
