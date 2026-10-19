# NAME

Plack::Middleware::ETag - Adds automatically an ETag header.

# SYNOPSIS

```perl
use Plack::Builder;

my $app = builder {
  enable "Plack::Middleware::ETag", file_etag => [qw/mtime size/];
  sub {['200', ['Content-Type' => 'text/html'}, ['hello world']]};
};
```

# DESCRIPTION

Plack::Middleware::ETag adds automatically an ETag header. You may want to use it with `Plack::Middleware::ConditionalGET`.

```perl
my $app = builder {
  enable "Plack::Middleware::ConditionalGET";
  enable "Plack::Middleware::ETag", file_etag => [qw/mtime size/];
  sub {['200', ['Content-Type' => 'text/html'}, ['hello world']]};
};
```

# RECENT CHANGES

Changes for version 0.06 (2026-10-18)

- Security
    - The inode is no longer used for generated the ETag by default. (CVE-2026-111946)
    - Bump minimum version of Digest::SHA to 5.96.
- Incompatabilities
    - Minimum version is Perl v5.14.
- Documentation
    - Updated with new maintainer.
    - Added security policy.
    - Documented the file\_etag supported attributes.
- Toolchain
    - Static install.
    - Distributions signed with sigstore.
    - Note that the git repository and bugtracker have moved.
    - Updated Dist::Zilla configuration for RRWO's preferences.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Digest::SHA](https://metacpan.org/pod/Digest%3A%3ASHA) version 5.96 or later
- [Plack::Middleware](https://metacpan.org/pod/Plack%3A%3AMiddleware)
- [Plack::Util](https://metacpan.org/pod/Plack%3A%3AUtil)
- [Plack::Util::Accessor](https://metacpan.org/pod/Plack%3A%3AUtil%3A%3AAccessor)
- [parent](https://metacpan.org/pod/parent)
- [perl](https://metacpan.org/pod/perl) version v5.14.0 or later
- [warnings](https://metacpan.org/pod/warnings)

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Plack::Middleware::ETag
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

For more information, see [How to install CPAN modules](https://www.cpan.org/modules/INSTALL.html).

# SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.14 or later.
Future releases may only support Perl versions released in the last ten (10) years.

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Plack-Middleware-ETag/issues](https://github.com/robrwo/perl-Plack-Middleware-ETag/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

## Reporting Security Vulnerabilities

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Plack-Middleware-ETag](https://github.com/robrwo/perl-Plack-Middleware-ETag)
and may be cloned from [https://github.com/robrwo/perl-Plack-Middleware-ETag.git](https://github.com/robrwo/perl-Plack-Middleware-ETag.git)

# AUTHORS

- Franck Cuny <franckcuny@gmail.com>
- Robert Rothenberg <perl@rhizomnic.com>

# CONTRIBUTOR

Leo Lapworth <leo@cuckoo.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015, 2026 by Franck Cuny.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
