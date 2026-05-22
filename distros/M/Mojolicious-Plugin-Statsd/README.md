# NAME

Mojolicious::Plugin::Statsd - Emit to Statsd, easy!

# SYNOPSIS

```perl
# Mojolicious
$self->plugin('Statsd');

# Mojolicious::Lite
plugin 'Statsd';

# Anywhere you have Mojo helpers available
$app->stats->increment('frobs.adjusted');

# It's safe to pass around if need be
my $stats = $app->stats;

# Only sample half of the time
$stats->increment('frobs.discarded', 0.5);

# Time a code section
$stats->timing('frobnicate' => sub {
  # section to be timed
});

# Or do it yourself
$stats->timing('frobnicate', $milliseconds);

# Save repetition
my $jobstats = $app->stats->with_prefix('my-special-process.');

# This becomes myapp.my-special-process.foo
$jobstats->increment('foo');
```

# DESCRIPTION

Mojolicious::Plugin::Statsd is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin which adds a helper for
throwing your metrics at statsd.

# RECENT CHANGES

Changes for version 0.06 (2026-05-21)

- Security
    - Fixed metric injection CVE-2026-46740
- Enhancements
    - Use Net::Statsd::Tiny for handling the statsd protocol
    - Added the client attribute for choosing any statsd client
- Documentation
    - New maintainer Robert Rothenberg <perl@rhizomnic.com>
    - Updated copyright year
    - Added a security policy
    - Added a SECURITY CONSIDERATIONS section
    - Use Pod::Weaver
    - Added doap.xml metadata
- Incompatible Changes
    - Minimum Perl is v5.16 (same as the current Mojolicious)

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [IO::Socket::INET](https://metacpan.org/pod/IO%3A%3ASocket%3A%3AINET)
- [Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase)
- [Mojo::Loader](https://metacpan.org/pod/Mojo%3A%3ALoader)
- [Time::HiRes](https://metacpan.org/pod/Time%3A%3AHiRes)
- [perl](https://metacpan.org/pod/perl) version v5.16.0 or later

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Mojolicious::Plugin::Statsd
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

When using the ["set\_add"](#set_add) method, be wary of exposing sensitive
information like IP addresses, usernames, email addresses or even
session ids over insecure channels.  One workaround is to log a
message digest of the value instead, for example

```perl
use Digest::SHA qw/ hmac_sha1 /;

...

$statsd->set_key( "myapp.sessions", hmac_sha1( $session->id, $my_secret_key );
```

Note that the keys should be consistent across worker processes and hosts.

When generating metric names based on untrusted sources (such as HTTP
requests), ensure that the metrics contain only printable characters
and do not contain colons (":") or pipes ("|"), since these are used
by the statsd protocol.

# SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.16 or later.
Future releases may only support Perl versions that are supported by [Mojolicious](https://metacpan.org/pod/Mojolicious).

## Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Mojolicious-Plugin-Statsd/issues](https://github.com/robrwo/perl-Mojolicious-Plugin-Statsd/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Mojolicious-Plugin-Statsd](https://github.com/robrwo/perl-Mojolicious-Plugin-Statsd)
and may be cloned from [https://github.com/robrwo/perl-Mojolicious-Plugin-Statsd.git](https://github.com/robrwo/perl-Mojolicious-Plugin-Statsd.git)

# AUTHOR

Meredith Howard  <mhoward@cpan.org>

This module is currently maintained by Robert Rothenberg <perl@rhizomnic.com>.

# CONTRIBUTOR

Robert Rothenberg <perl@rhizomnic.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2026 by Meredith Howard  <mhoward@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# SEE ALSO

[Mojolicious::Plugin::Statsd::Adapter::Statsd](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AStatsd%3A%3AAdapter%3A%3AStatsd)

[Mojolicious::Plugin::Statsd::Adapter::Memory](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AStatsd%3A%3AAdapter%3A%3AMemory)

[Mojolicious](https://metacpan.org/pod/Mojolicious)
