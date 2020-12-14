# NAME

Plack::Middleware::Text::Minify - minify text responses on the fly

# VERSION

version v0.1.0

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

This middleware uses [Text::Minify::XS](https://metacpan.org/pod/Text::Minify::XS) to remove indentation and
trailing whitespace from text content.

# ATTRIBUTES

## path

This is a regex or callback that matches against `PATH_INFO`.  If it
does not match, then the response won't be minified.

The callback takes the `PATH_INFO` and Plack environment as arguments.

By default, it will match against any path.

## type

This is a regex or callback that matches against the content-type. If it
does not match, then the response won't be minified.

The callback takes the content-type header and the Plack reponse as
arguments.

By default, it will match against any "text/" MIME type.

# SEE ALSO

[Text::Minify::XS](https://metacpan.org/pod/Text::Minify::XS)

[PSGI](https://metacpan.org/pod/PSGI)

# SOURCE

The development version is on github at [https://github.com/robrwo/Plack-Middleware-Text-Minify](https://github.com/robrwo/Plack-Middleware-Text-Minify)
and may be cloned from [git://github.com/robrwo/Plack-Middleware-Text-Minify.git](git://github.com/robrwo/Plack-Middleware-Text-Minify.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Plack-Middleware-Text-Minify/issues](https://github.com/robrwo/Plack-Middleware-Text-Minify/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
