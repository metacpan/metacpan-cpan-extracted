# NAME

Plack::Middleware::Greylist - throttle requests with different rates based on net blocks

# SYNOPSIS

```perl
use Plack::Builder;

builder {

  enable "Greylist",
    file         => sprintf('/run/user/%u/greylist', $>), # cache file
    default_rate => 250,
    greylist     => {
        '192.168.0.0/24' => 'whitelist',
        '172.16.1.0/25'  => [ 100, 'netblock' ],
    };

}
```

# DESCRIPTION

This middleware will apply rate limiting to requests, depending on the requestor netblock.

Hosts that exceed their configured per-minute request limit will be rejected with HTTP 429 errors.

## Log Messages

Rejections will be logged with a message of the form

```
Rate limiting $ip after $hits/$rate for $netblock
```

for example,

```
Rate limiting 172.16.0.10 after 225/250 for 172.16.0.0/24
```

Note that the `$netblock` for the default rate is simply "default", e.g.

```
Rate limiting 192.168.0.12 after 101/100 for default
```

This will allow you to use something like [fail2ban](https://github.com/fail2ban/fail2ban) to block repeat offenders, since bad
robots are like houseflies that repeatedly bump against closed windows.

Note, if a ["callback"](#callback) is specified, then nothing will be logged, but the log message will be sent to the callback.

# RECENT CHANGES

Changes for version v0.8.2 (2026-09-06)

- Security
    - Updated the minimum recommended version of Net::IP::LPM.
- Documentation
    - Updated author email address.
    - Added security policy.
    - Updated copyright year.
    - Generate README with the UsefulReadme plugin.
- Tests
    - Added more author tests.
    - Moved author tests into xt.
- Toolchain
    - Improved dist.ini.
    - Use sigstore instead of Module::Signature, with is deprecated.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [HTTP::Status](https://metacpan.org/pod/HTTP%3A%3AStatus)
- [List::Util](https://metacpan.org/pod/List%3A%3AUtil) version 1.29 or later
- [Module::Load](https://metacpan.org/pod/Module%3A%3ALoad)
- [Net::IP::LPM](https://metacpan.org/pod/Net%3A%3AIP%3A%3ALPM)
- [Plack::Middleware](https://metacpan.org/pod/Plack%3A%3AMiddleware)
- [Ref::Util](https://metacpan.org/pod/Ref%3A%3AUtil)
- [Time::Seconds](https://metacpan.org/pod/Time%3A%3ASeconds)
- [experimental](https://metacpan.org/pod/experimental)
- [parent](https://metacpan.org/pod/parent)
- [perl](https://metacpan.org/pod/perl) version v5.20.0 or later
- [warnings](https://metacpan.org/pod/warnings)

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Plack::Middleware::Greylist
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

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Plack-Middleware-Greylist/issues](https://github.com/robrwo/Plack-Middleware-Greylist/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

## Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website.  Please see `SECURITY.md` for instructions how to
report security vulnerabilities

# SOURCE

The development version is on github at [https://github.com/robrwo/Plack-Middleware-Greylist](https://github.com/robrwo/Plack-Middleware-Greylist)
and may be cloned from [https://github.com/robrwo/Plack-Middleware-Greylist.git](https://github.com/robrwo/Plack-Middleware-Greylist.git)

# AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

The initial development of this module was sponsored by Science Photo
Library [https://www.sciencephoto.com](https://www.sciencephoto.com).

# CONTRIBUTOR

Gabor Szabo <gabor@szabgab.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2022-2026 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
