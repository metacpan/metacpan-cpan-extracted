# NAME

Net::Statsd::Tiny - A tiny StatsD client that supports multimetric packets

# SYNOPSIS

```perl
use Net::Statsd::Tiny;

my $stats = Net::Statsd::Tiny->new(
  prefix          => 'myapp.',
  autoflush       => 0,
  max_buffer_size => 8192,
);

...

$stats->increment('this.counter');

$stats->set_add( 'this.users', $username ) if $username;

$stats->timing( $run_time * 1000 );

$stats->flush;
```

# DESCRIPTION

This is a small StatsD client that supports the
[StatsD Metrics Export Specification v0.1](https://github.com/b/statsd_spec).

It supports the following features:

- Multiple metrics can be sent in a single UDP packet.
- It supports the meter and histogram metric types.

Note that the specification requires the measured values to be
integers no larger than 64-bits, but ideally 53-bits.

The current implementation does not validate that the values you pass
to metrics conform to the spec, which allows you to take advantage of
extensions to some StatsD daemons. But the downside is that other
daemons may ignore those metrics.

For simplicity, it will allow you to specify a sampling rate for any
metric, not just the ones where it is documented below. But again,
some daemons may ignore or reject this.

# RECENT CHANGES

Changes for version v0.3.9 (2026-05-18)

- Incompatabilities
    - Bumped the minimum Perl version to 5.12.
- Security
    - Upgraded minimum versions of some prerequisites to exclude known vulnerabilities.
- Documentation
    - Added SPDX Licence Snippet to borrowed test code.
    - Fixed typos.
- Tests
    - Add more author tests.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Carp](https://metacpan.org/pod/Carp)
- [Class::Accessor::Fast](https://metacpan.org/pod/Class%3A%3AAccessor%3A%3AFast)
- [IO::Socket](https://metacpan.org/pod/IO%3A%3ASocket) version 1.18 or later
- [Socket](https://metacpan.org/pod/Socket) version 2.026 or later
- [parent](https://metacpan.org/pod/parent)
- [perl](https://metacpan.org/pod/perl) version v5.12.0 or later
- [strict](https://metacpan.org/pod/strict)
- [warnings](https://metacpan.org/pod/warnings)

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Net::Statsd::Tiny
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

# SECURITY CONSIDERATIONS

When using the ["set\_add"](#set_add) method, be wary of exposing sensitive information like IP addresses, usernames, email addresses or even session ids over insecure channels.  One workaround is to log a message digest of the value instead, for example

```perl
use Digest::SHA qw/ hmac_sha1 /;

...

$tats->set_key( "myapp.sessions", hmac_sha1( $session->id, $my_secret_key );
```

Note that the keys should be consistent across worker processes and hosts.

When generating metric names based on untrusted sources (such as HTTP requests), ensure that the metrics contain only printable characters and do not contain colons (":") or pipes ("|"), since these are used by the statsd protocol.

# SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.12 or later.
Future releases may only support Perl versions released in the last ten (10) years.

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Net-Statsd-Tiny/issues](https://github.com/robrwo/Net-Statsd-Tiny/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

## Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website. Please see `SECURITY.md` for instructions how to
report security vulnerabilities

# SOURCE

The development version is on github at [https://github.com/robrwo/Net-Statsd-Tiny](https://github.com/robrwo/Net-Statsd-Tiny)
and may be cloned from [https://github.com/robrwo/Net-Statsd-Tiny.git](https://github.com/robrwo/Net-Statsd-Tiny.git)

# AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

The initial development of this module was sponsored by Science Photo
Library [https://www.sciencephoto.com](https://www.sciencephoto.com).

# CONTRIBUTOR

Michael R. Davis <mrdvt@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

# SEE ALSO

[Net::Statsd::Lite](https://metacpan.org/pod/Net%3A%3AStatsd%3A%3ALite) which has a similar API but uses [Moo](https://metacpan.org/pod/Moo) and
[Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny) for data validation. It's also faster.

[https://github.com/b/statsd\_spec](https://github.com/b/statsd_spec)
