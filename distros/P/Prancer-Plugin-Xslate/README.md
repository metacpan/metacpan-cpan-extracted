# NAME

Prancer::Plugin::Xslate

# SYNOPSIS

This plugin provides access to the [Text::Xslate](https://metacpan.org/pod/Text::Xslate) templating engine for your
[Prancer](https://metacpan.org/pod/Prancer) application and exports a keyword to access the configured engine.

This template plugin supports setting the basic configuration in your Prancer
application's configuration file. You can also configure all options at runtime
using arguments to `render`.

To set a configuration in your application's configuration file, begin the
configuration block with `template` and put all options underneath that. For
example:

    template:
        cache_dir: /path/to/cache
        verbose: 2

Any option for Text::Xslate whose value can be expressed in a configuration
file can be put into your application's configuration. Then using the template
engine is as simple as this:

    use Prancer::Plugin::Xslate qw(render);

    Prancer::Plugin::Xslate->load();

    print render("foobar.tx", \%vars);

However, there are some configuration options that cannot be expressed in
configuration files, especially the `functions` option. There are two
additional ways to handle that. The first way is to pass them to the template
plugin when loading it, like this:

    Prancer::Plugin::Xslate->load({
        'function' => {
            'encode_json' => sub {
                return JSON::encode_json(@_);
            }
        }
    });

The second way is to the optional third argument to `render`, like this:

    print render("foobar.tx", \%vars, {
        'function' => {
            'md5_hex' => sub {
                return Digest::MD5::md5_hex(@_);
            }
        }
    });

Options passed when initializing the template plugin will override options
configured in the configuration file. Options passed when calling `render`
will override options passed when initializing the template plugin. This is
the way you might go about adding support for functions and methods.

# METHODS

- path

    This will set the `path` option for Text::Xslate to anything that Text::Xslate
    suports. Each call to this method will overwrite whatever the previous template
    path was. For example:

        # sets template path to just /path/to/templates
        $plugin->path('/path/to/templates');

        # blows away /path/to/templates set previously and sets it to this arrayref
        $plugin->path([ '/path/to/global-templates', '/path/to/local-templates' ]);

        # blows away the arrayref set previously and sets it to this hashref
        $plugin->path({
            'foo.tx' => '<html><body><: $foo :><br/></body></html>',
            'bar.tx' => 'Hello, <: $bar :>.',
        });

- mark\_raw, unmark\_raw, html\_escape, uri\_escape

    Proxies access to the static functions of the same name provided in
    [Text::Xslate](https://metacpan.org/pod/Text::Xslate). These can all be called statically or an instance of the
    plugin and all will work just fine. All of these can also be exported on
    demand. For more information on how to use these functions, read the
    Text::Xslate documentation.

# COPYRIGHT

Copyright 2014, 2015 Paul Lockaby. All rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

# SEE ALSO

- [Prancer](https://metacpan.org/pod/Prancer)
- [Text::Xslate](https://metacpan.org/pod/Text::Xslate)
