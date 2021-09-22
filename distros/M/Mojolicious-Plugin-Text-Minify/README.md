# NAME

Mojolicious::Plugin::Text::Minify - remove HTML indentation on the fly

# VERSION

version v0.2.1

# SYNOPSIS

```
# Mojolicious::Lite
plugin "Text::Minify";

# Mojolicious
$app->plugin("Text::Minify");
```

# DESCRIPTION

This plugin uses [Text::Minify::XS](https://metacpan.org/pod/Text::Minify::XS) to remove indentation and
trailing whitespace from HTML content.

If the `mojox.no-minify` key in the stash is set to a true value,
then the result will not be minified.

Note that this is naive minifier which does not understand markup, so
newlines will still be collapsed in HTML elements where whitespace is
meaningful, e.g. `pre` or `textarea`.

# SEE ALSO

[Text::Minify::XS](https://metacpan.org/pod/Text::Minify::XS)

[Plack::Middleware::Text::Minify](https://metacpan.org/pod/Plack::Middleware::Text::Minify)

# SOURCE

The development version is on github at [https://github.com/robrwo/Mojolicious-Plugin-Text-Minify](https://github.com/robrwo/Mojolicious-Plugin-Text-Minify)
and may be cloned from [git://github.com/robrwo/Mojolicious-Plugin-Text-Minify.git](git://github.com/robrwo/Mojolicious-Plugin-Text-Minify.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Mojolicious-Plugin-Text-Minify/issues](https://github.com/robrwo/Mojolicious-Plugin-Text-Minify/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
