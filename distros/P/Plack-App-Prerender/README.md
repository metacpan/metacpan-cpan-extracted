# NAME

Plack::App::Prerender - a simple prerendering proxy for Plack

# SYNOPSIS

```perl
use CHI;
use Log::Log4perl qw/ :easy /;
use Plack::App::Prerender;

my $cache = CHI->new(
    driver   => 'File',
    root_dir => '/tmp/test-chi',
);

Log::Log4perl->easy_init($ERROR);

my $app = Plack::App::Prerender->new(
    rewrite => "http://www.example.com",
    cache   => $cache,
    wait    => 10,
)->to_app;
```

# DESCRIPTION

This is a PSGI application that acts as a simple prerendering proxy
for websites using Chrome.

This only supports GET requests, as this is intended as a proxy for
search engines that do not support AJAX-generated content.

# RECENT CHANGES

Changes for version v0.3.0 (2026-07-27)

- Security
    - Requests with no forward slash are now blocked, as these may allow the host to be changed (CVE-2026-17552).
- Documentation
    - Updated AUTHOR email address.
    - Update copyright year.
    - Added a SECURITY CONSIDERATIONS section.
    - Fixed typos.
    - Updated README with the UsefulReadme plugin.
- Tests
    - Tests changed to use example.com as httpbin.org is not responding.
    - Tests will adapt when the external server is responding with HTTP 5xx errors.
    - Add more author tests.
- Toolchain
    - Update the Dist::Zilla configuration.
    - Releases are signed with SigStore.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Encode](https://metacpan.org/pod/Encode)
- [HTTP::Headers](https://metacpan.org/pod/HTTP%3A%3AHeaders)
- [HTTP::Request](https://metacpan.org/pod/HTTP%3A%3ARequest)
- [HTTP::Status](https://metacpan.org/pod/HTTP%3A%3AStatus)
- [Plack::Component](https://metacpan.org/pod/Plack%3A%3AComponent)
- [Plack::Request](https://metacpan.org/pod/Plack%3A%3ARequest)
- [Plack::Util](https://metacpan.org/pod/Plack%3A%3AUtil)
- [Plack::Util::Accessor](https://metacpan.org/pod/Plack%3A%3AUtil%3A%3AAccessor)
- [Ref::Util](https://metacpan.org/pod/Ref%3A%3AUtil)
- [Time::Seconds](https://metacpan.org/pod/Time%3A%3ASeconds)
- [WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome)
- [parent](https://metacpan.org/pod/parent)
- [perl](https://metacpan.org/pod/perl) version v5.10.1 or later
- [strict](https://metacpan.org/pod/strict)
- [warnings](https://metacpan.org/pod/warnings)

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Plack::App::Prerender
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

By default, Chrome can access local files using the `file:` protocol.

By default, Chrome will run scripts.

This should only be used for trusted websites, e.g. adding a prerendering proxy for your own website.

# SUPPORT

Only the latest version of this module will be supported.

Future releases may only support Perl versions released in the last ten (10) years.

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Plack-App-Prerender/issues](https://github.com/robrwo/perl-Plack-App-Prerender/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

## Reporting Security Vulnerabilities

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Plack-App-Prerender](https://github.com/robrwo/perl-Plack-App-Prerender)
and may be cloned from [https://github.com/robrwo/perl-Plack-App-Prerender.git](https://github.com/robrwo/perl-Plack-App-Prerender.git)

# AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2020, 2026 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

# SEE ALSO

[Plack](https://metacpan.org/pod/Plack)

[WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome)

Rendertron [https://github.com/GoogleChrome/rendertron](https://github.com/GoogleChrome/rendertron)
