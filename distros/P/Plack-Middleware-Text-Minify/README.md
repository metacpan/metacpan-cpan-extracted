# NAME

Plack::Middleware::Text::Minify - remove HTML indentation on the fly

# SYNOPSIS

```perl
use Plack::Builder;

builder {

  enable "Text::Minify",
      path => qr{\.(html|css|js)},
      type => qr{^text/};

...

};
```

# DESCRIPTION

This middleware uses [Text::Minify::XS](https://metacpan.org/pod/Text%3A%3AMinify%3A%3AXS) to remove indentation and
trailing whitespace from text content.

It will be disabled if the `psgix.no-minify` environment key is set
to a true value. (Added in v0.2.0.)

# RECENT CHANGES

Changes for version v0.4.2 (2026-05-02)

- Security
    - Bumped the minimum version of Text::Minify::XS for a security fix.
- Documentation
    - Added security policy.
    - Updated copyright year.
    - Updated maintainer email address due to closure of cpan.org email.
    - Updated support policy.
    - Fixed typos.
    - README is build by the UsefulReadme plugin.
- Tests
    - Moved author tests into xt.
    - Added and improved author tests.
- Toolchain
    - Removed the use of Dist::Zilla::Plugin::ManifestSkip.
- Other
    - Added doap.xml to the repo.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Plack::Middleware](https://metacpan.org/pod/Plack%3A%3AMiddleware)
- [Ref::Util](https://metacpan.org/pod/Ref%3A%3AUtil)
- [Text::Minify::XS](https://metacpan.org/pod/Text%3A%3AMinify%3A%3AXS) version v0.7.8 or later
- [parent](https://metacpan.org/pod/parent)
- [perl](https://metacpan.org/pod/perl) version v5.14.0 or later
- [warnings](https://metacpan.org/pod/warnings)

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Plack::Middleware::Text::Minify
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
[https://github.com/robrwo/Plack-Middleware-Text-Minify/issues](https://github.com/robrwo/Plack-Middleware-Text-Minify/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

## Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website.  Please see `SECURITY.md` for instructions how to
report security vulnerabilities

# SOURCE

The development version is on github at [https://github.com/robrwo/Plack-Middleware-Text-Minify](https://github.com/robrwo/Plack-Middleware-Text-Minify)
and may be cloned from [https://github.com/robrwo/Plack-Middleware-Text-Minify.git](https://github.com/robrwo/Plack-Middleware-Text-Minify.git)

# AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2020-2026 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

# SEE ALSO

[Text::Minify::XS](https://metacpan.org/pod/Text%3A%3AMinify%3A%3AXS)

[PSGI](https://metacpan.org/pod/PSGI)
