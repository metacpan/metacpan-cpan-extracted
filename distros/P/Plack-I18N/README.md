# NAME

Plack::I18N - I18N for Plack

# SYNOPSIS

    use Plack::I18N;
    use Plack::Builder;

    my $i18n = Plack::I18N->new(lexicon => 'gettext', locale_dir => 'locale/');

    builder {
        enable 'I18N', i18n => $i18n;

        sub {
            my $env = shift;

            my $handle = $env->{'plack.i18n.handle'};

            [200, [], [$handle->maketext('Hello')]];
        };
    };

# DESCRIPTION

Plack::I18N is an easy way to add i18n to your application. Plack::I18N supports
both [Locale::Maketext](https://metacpan.org/pod/Locale::Maketext) `*.pm` files and `gettext` `*.po` files. Use
whatevers suits better.

See [https://github.com/vti/plack-i18n/tree/master/examples](https://github.com/vti/plack-i18n/tree/master/examples) directory for both
examples.

## Language detection

Language detection is done via HTTP headers, session cookies, URL path prefix
and so on. See [Plack::Middleware::I18N](https://metacpan.org/pod/Plack::Middleware::I18N) for details.

## `$env` parameters

Plack::Middleware::I18N registers the following `$env` parameters:

- `plack.i18n`

    Holds Plack::I18N instance.

- `plack.i18n.language`

    Current detected language. A shortcut for `$env->{'plack.i18n'}->language`.

- `plack.i18n.handle`

    A shortcut for `$env->{'plack.i18n'}->handle($env->{'plack.i18n.language'})`.

# METHODS

## `new`

Creates new object.

Options:

- lexicon

    One of `gettext` or `maketext`.

- i18n\_class

    This is usually `MyApp::I18N`. This class is automatically generated if
    does not exist. In case of `gettext` `i18n_class` it even doesn't
    have to be specified.

- locale\_dir

    Directory where translations are stored.

- default\_language

    Default language. `en` by default.

- languages

    Available languages. Automatically detected unless specified.

## `default_language`

Returns default language.

## `handle($language)`

Returns handle of appropriate language.

## `languages`

Returns available languages.

# AUTHOR

Viacheslav Tykhanovskyi, <viacheslav.t@gmail.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2015, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

This program is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for
a particular purpose.
