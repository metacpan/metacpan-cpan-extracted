# NAME

Plack::Middleware::Statsd - send statistics to statsd

# SYNOPSIS

```perl
use Plack::Builder;
use Net::Statsd::Tiny;

builder {

  enable "Statsd",
    client      => Net::Statsd::Tiny->new( ... ),
    sample_rate => 1.0;

  ...

  sub {
    my ($env) = @_;

    # Send statistics via other middleware

    if (my $stats = $env->{'psgix.monitor.statsd'}) {

      $stats->increment('myapp.wibble');

    }

  };

};
```

# DESCRIPTION

This middleware gathers metrics from the application send sends them
to a statsd server.

# RECENT CHANGES

Changes for version v0.8.2 (2025-08-16)

- Documentation
    - Removed redundant section.
- Tests
    - Added more author tests.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [List::Util](https://metacpan.org/pod/List%3A%3AUtil)
- [Plack::Middleware](https://metacpan.org/pod/Plack%3A%3AMiddleware)
- [Ref::Util](https://metacpan.org/pod/Ref%3A%3AUtil)
- [Time::HiRes](https://metacpan.org/pod/Time%3A%3AHiRes)
- [Try::Tiny](https://metacpan.org/pod/Try%3A%3ATiny)
- [experimental](https://metacpan.org/pod/experimental)
- [parent](https://metacpan.org/pod/parent)
- [perl](https://metacpan.org/pod/perl) version v5.20.0 or later
- [warnings](https://metacpan.org/pod/warnings)

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Plack::Middleware::Statsd
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

This module requires Perl v5.20 or later.
Future releases may only support Perl versions released in the last ten (10) years.

## Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Plack-Middleware-Statsd/issues](https://github.com/robrwo/Plack-Middleware-Statsd/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# SOURCE

The development version is on github at [https://github.com/robrwo/Plack-Middleware-Statsd](https://github.com/robrwo/Plack-Middleware-Statsd)
and may be cloned from [git://github.com/robrwo/Plack-Middleware-Statsd.git](git://github.com/robrwo/Plack-Middleware-Statsd.git)

Please see `CONTRIBUTING.md` for more information on how to contribute to this project.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library [https://www.sciencephoto.com](https://www.sciencephoto.com).

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2025 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

# SEE ALSO

[Net::Statsd::Client](https://metacpan.org/pod/Net%3A%3AStatsd%3A%3AClient)

[Net::Statsd::Tiny](https://metacpan.org/pod/Net%3A%3AStatsd%3A%3ATiny)

[PSGI](https://metacpan.org/pod/PSGI)
