# NAME

Plack::Middleware::Text::Minify - minify text responses on the fly

# VERSION

version v0.2.1

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

It will be disabled if the `psgix.no-minify` environment key is set
to a true value. (Added in v0.2.0.)

# ATTRIBUTES

## path

This is a regex or callback that matches against `PATH_INFO`.  If it
does not match, then the response won't be minified.

The callback takes the `PATH_INFO` and Plack environment as arguments.

By default, it will match against any path except for HTTP status
codes with no bodies, or request methods other than `GET` or `POST`.

## type

This is a regex or callback that matches against the content-type. If it
does not match, then the response won't be minified.

The callback takes the content-type header and the Plack reponse as
arguments.

By default, it will match against any "text/" MIME type.

# KNOWN ISSUES

## Support for older Perl versions

This module requires Perl v5.9.3 or newer, which is the minimum
version supported by [Text::Minify::XS](https://metacpan.org/pod/Text::Minify::XS).

## Use with templating directive that collapse whitespace

If you are using a templating system with directives that collapse
whitespace in HTML documents, e.g. in [Template-Toolkit](https://metacpan.org/pod/Template)

```
[%- IF something -%]
  <div class="foo">
    ...
  </div>
[%- END -%]
```

then you may find it worth removing these and letting the middleware
clean up extra whitespace.

## Collapsed Newlines

The underlying minifier does not understand markup, so newlines will
still be collapsed in HTML elements where whitespace is meaningful,
e.g. `pre` or `textarea`.

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

This software is Copyright (c) 2020-2021 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
