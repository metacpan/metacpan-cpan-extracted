# NAME

Net::Statsd::Lite - A StatsD client that supports multimetric packets

# SYNOPSIS

```perl
use Net::Statsd::Lite;

my $stats = Net::Statsd::Lite->new(
  prefix          => 'myapp.',
  autoflush       => 0,
  max_buffer_size => 8192,
  secure_set_key  => 'MySecretKey!',
);

...

$stats->increment('this.counter');

$stats->set_add( 'this.users', $user->id ) if $user;

$stats->secure_set_add( 'this.session', $session->id );

$stats->timing( $run_time * 1000 );

$stats->flush;
```

# DESCRIPTION

This is a StatsD client that supports the
[StatsD Metrics Export Specification v0.1](https://github.com/b/statsd_spec).

It supports the following features:

- Multiple metrics can be sent in a single UDP packet.
- It supports the meter and histogram metric types.
- It can extended to support extensions such as tagging.
- It supports a ["secure\_set\_key"](#secure_set_key) method for logging sensitive data.

Note that the specification requires the measured values to be
integers no larger than 64-bits, but ideally 53-bits.

The current implementation expects values to be integers, except where
specified. But it otherwise does not enforce maximum/minimum values.

# RECENT CHANGES

Changes for version v0.11.1 (2026-05-23)

- Documentation
    - Fixed inconsistent POD markup.
    - Updated SECURITY CONSIDERATIONS about tagging extensions.
    - Fixed a bug in an example.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Carp](https://metacpan.org/pod/Carp)
- [Devel::StrictMode](https://metacpan.org/pod/Devel%3A%3AStrictMode)
- [Digest::SHA](https://metacpan.org/pod/Digest%3A%3ASHA) version 5.96 or later
- [IO::Socket::IP](https://metacpan.org/pod/IO%3A%3ASocket%3A%3AIP)
- [Moo](https://metacpan.org/pod/Moo) version 1.000000 or later
- [MooX::TypeTiny](https://metacpan.org/pod/MooX%3A%3ATypeTiny)
- [Ref::Util](https://metacpan.org/pod/Ref%3A%3AUtil)
- [Scalar::Util](https://metacpan.org/pod/Scalar%3A%3AUtil)
- [Sub::Quote](https://metacpan.org/pod/Sub%3A%3AQuote)
- [Sub::Util](https://metacpan.org/pod/Sub%3A%3AUtil) version 1.40 or later
- [Types::Common](https://metacpan.org/pod/Types%3A%3ACommon) version 2.000000 or later
- [experimental](https://metacpan.org/pod/experimental)
- [namespace::autoclean](https://metacpan.org/pod/namespace%3A%3Aautoclean)
- [perl](https://metacpan.org/pod/perl) version v5.20.0 or later
- [strict](https://metacpan.org/pod/strict)

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Net::Statsd::Lite
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

# SECURITY CONSIDERATIONS

When using the ["set\_add"](#set_add) method, be wary of exposing sensitive information like IP addresses, usernames, email addresses or even session ids over insecure channels.  Use the ["secure\_set\_add"](#secure_set_add) method instead.

When generating metric names based on untrusted sources (such as HTTP requests), ensure that the metrics contain only printable characters and do not contain colons (":") or pipes ("|"), since these are used by the statsd protocol.

When using [tagging extensions](#tagging-extensions), tags should also be validated to ensure that they do not contain control characters.

# SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.20 or later.
Future releases may only support Perl versions released in the last ten (10) years.

## Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Net-Statsd-Lite/issues](https://github.com/robrwo/Net-Statsd-Lite/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

## Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website. Please see `SECURITY.md` for instructions how to
report security vulnerabilities

# SOURCE

The development version is on github at [https://github.com/robrwo/Net-Statsd-Lite](https://github.com/robrwo/Net-Statsd-Lite)
and may be cloned from [https://github.com/robrwo/Net-Statsd-Lite.git](https://github.com/robrwo/Net-Statsd-Lite.git)

# AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

The initial development of this module was sponsored by Science Photo
Library [https://www.sciencephoto.com](https://www.sciencephoto.com).

# CONTRIBUTORS

- Michael R. Davis <mrdvt@cpan.org>
- Toby Inkster <tobyink@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

# SEE ALSO

This module was forked from [Net::Statsd::Tiny](https://metacpan.org/pod/Net%3A%3AStatsd%3A%3ATiny).

[https://github.com/statsd/statsd/blob/master/docs/metric\_types.md](https://github.com/statsd/statsd/blob/master/docs/metric_types.md)

[https://github.com/b/statsd\_spec](https://github.com/b/statsd_spec)
