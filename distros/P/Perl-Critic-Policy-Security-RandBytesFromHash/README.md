# NAME

Perl::Critic::Policy::Security::RandBytesFromHash - flag common anti-patterns for generating random bytes

# SYNOPSIS

In your `perlcriticrc` file, add

```
[Perl::Critic::Policy::Security::RandBytesFromHash]
severity = 1
```

# DESCRIPTION

In the previous century, most operating systems didn't provide a good source of random bytes.
So people who needed to generate random strings for things like session ids in cookies needed to work around this.
They used cryptographic hashes around sources of pseudo-random noise, like

```
 message_digest( rand() + time() + $PID ... )
```

It seemed good enough. Hashing functions like MD5 or SHA were state-of-the-art and the output looked random.
That was naive, because the seed values were always predicable:

- Perl's built-in `rand` is seeded by 32-bits and is predicable enough that the seed can be reverse-engineered after a few iterations.
- The `time` function is predictable, and is leaked by protocols like HTTP.
- The `$PID` comes from a small pool of values, and it's common for child processes (such as workers for a web service) to have sequential ids.
- Perl data structures have predictable reference addresses.
- Internal counters have predictable content, as most of the leading digits will not change between invocations.

If an attacker can guess most of the seed, they can guess the generated data (which might be a session id in cookie that grants access to a website).
When you consider cryptanalysis of older algorithms like MD5 or SHA, along with the significant increase and availability of computing power, then this pattern seems to be an elaborate footgun.

Alas, this pattern still shows up in new code, and it remains in some legacy code.

This is a [Perl::Critic](https://metacpan.org/pod/Perl%3A%3ACritic) policy to flag common cases of this.
Anything that looks like the bad sources of randomness outlined above will be flagged.

What can you use instead?  Modules like [Crypt::URandom](https://metacpan.org/pod/Crypt%3A%3AURandom), [Crypt::SysRandom](https://metacpan.org/pod/Crypt%3A%3ASysRandom) or [Crypt::PRNG](https://metacpan.org/pod/Crypt%3A%3APRNG).

# RECENT CHANGES

Changes for version v0.1.3 (2026-04-15)

- Documentation
    - Updated author email address due to issues with cpan.org email.
- Tests
    - Added test case for false positives (GH#1).

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [List::Util](https://metacpan.org/pod/List%3A%3AUtil)
- [PPI](https://metacpan.org/pod/PPI) version 1.281 or later
- [Perl::Critic::Policy](https://metacpan.org/pod/Perl%3A%3ACritic%3A%3APolicy)
- [Perl::Critic::Utils](https://metacpan.org/pod/Perl%3A%3ACritic%3A%3AUtils)
- [Readonly](https://metacpan.org/pod/Readonly) version 2.01 or later
- [Ref::Util](https://metacpan.org/pod/Ref%3A%3AUtil)
- [experimental](https://metacpan.org/pod/experimental)
- [parent](https://metacpan.org/pod/parent)
- [perl](https://metacpan.org/pod/perl) version v5.24.0 or later
- [warnings](https://metacpan.org/pod/warnings)

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Perl::Critic::Policy::Security::RandBytesFromHash
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

This module requires Perl v5.24 or later.  Future releases may only support Perl versions released in the last ten
years.

## Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Perl-Critic-Policy-Security-RandBytesFromHash/issues](https://github.com/robrwo/Perl-Critic-Policy-Security-RandBytesFromHash/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications that make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# SOURCE

The development version is on github at [https://github.com/robrwo/Perl-Critic-Policy-Security-RandBytesFromHash](https://github.com/robrwo/Perl-Critic-Policy-Security-RandBytesFromHash)
and may be cloned from [https://github.com/robrwo/Perl-Critic-Policy-Security-RandBytesFromHash.git](https://github.com/robrwo/Perl-Critic-Policy-Security-RandBytesFromHash.git)

# AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Robert Rothenberg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# SEE ALSO

[CPAN Author’s Guide to Random Data for Security](https://security.metacpan.org/docs/guides/random-data-for-security.html)
