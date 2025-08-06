# NAME

Net::CIDR::Set - Manipulate sets of IP addresses

# SYNOPSIS

```perl
use Net::CIDR::Set;

my $priv = Net::CIDR::Set->new( '10.0.0.0/8', '172.16.0.0/12',
  '192.168.0.0/16' );
for my $ip ( @addr ) {
  if ( $priv->contains( $ip ) ) {
    print "$ip is private\n";
  }
}
```

# DESCRIPTION

`Net::CIDR::Set` represents sets of IP addresses and allows standard
set operations (union, intersection, membership test etc) to be
performed on them.

In spite of the name it can work with sets consisting of arbitrary
ranges of IP addresses - not just CIDR blocks.

Both IPv4 and IPv6 addresses are handled - but they may not be mixed in
the same set. You may explicitly set the personality of a set:

```perl
my $ip4set = Net::CIDR::Set->new({ type => 'ipv4 }, '10.0.0.0/8');
```

Normally this isn't necessary - the set will guess its personality from
the first data that is added to it.

# RECENT CHANGES

Changes for version 0.19 (2025-08-05)

- Documentation
    - Fixed typos in documentation RT#168697 (thanks Thomas Eckardt).
    - Removed the separate INSTALL file.
    - Fixed the CONTRIBUTORS setion of the README.
    - Added CONTRIBUTING.md file.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Carp](https://metacpan.org/pod/Carp)
- [namespace::autoclean](https://metacpan.org/pod/namespace%3A%3Aautoclean)
- [overload](https://metacpan.org/pod/overload)
- [perl](https://metacpan.org/pod/perl) version v5.14.0 or later
- [strict](https://metacpan.org/pod/strict)
- [warnings](https://metacpan.org/pod/warnings)

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Net::CIDR::Set
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
[https://rt.cpan.org/Public/Dist/Display.html?Name=Net-CIDR-Set](https://rt.cpan.org/Public/Dist/Display.html?Name=Net-CIDR-Set)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

## Reporting Security Vulnerabilities

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Net-CIDR-Set](https://github.com/robrwo/perl-Net-CIDR-Set)
and may be cloned from [git://github.com/robrwo/perl-Net-CIDR-Set.git](git://github.com/robrwo/perl-Net-CIDR-Set.git)

# AUTHOR

Andy Armstrong <andy@hexten.net>

The current maintainer is Robert Rothenberg <rrwo@cpan.org>.

The encode and decode routines were stolen en masse from Douglas Wilson's [Net::CIDR::Lite](https://metacpan.org/pod/Net%3A%3ACIDR%3A%3ALite).

# CONTRIBUTORS

- Thomas Eckardt <Thomas.Eckardt@thockar.com>
- Brian Gottreu <gottreu@cpan.org>
- Robert Rothenberg <rrwo@cpan.org>
- Stig Palmquist <stigtsp@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2009, 2014, 2025 by Message Systems, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
