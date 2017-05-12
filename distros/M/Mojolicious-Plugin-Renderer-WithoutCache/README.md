[![Build Status](https://travis-ci.org/simbabque/Mojolicious-Plugin-Renderer-WithoutCache.svg?branch=master)](https://travis-ci.org/simbabque/Mojolicious-Plugin-Renderer-WithoutCache) [![Coverage Status](https://img.shields.io/coveralls/simbabque/Mojolicious-Plugin-Renderer-WithoutCache/master.svg?style=flat)](https://coveralls.io/r/simbabque/Mojolicious-Plugin-Renderer-WithoutCache?branch=master)
# NAME

Mojolicious::Plugin::Renderer::WithoutCache - Disable the template cache in your Mojo app

<div>
    <p>
    <a href="https://travis-ci.org/simbabque/Mojolicious-Plugin-Renderer-WithoutCache"><img src="https://travis-ci.org/simbabque/Mojolicious-Plugin-Renderer-WithoutCache.svg?branch=master"></a>
    <a href='https://coveralls.io/github/simbabque/Mojolicious-Plugin-Renderer-WithoutCache?branch=master'><img src='https://coveralls.io/repos/github/simbabque/Mojolicious-Plugin-Renderer-WithoutCache/badge.svg?branch=master' alt='Coverage Status' /></a>
    </p>
</div>

# VERSION

Version 0.04

# SYNOPSIS

This plugin turns off the renderer's cache in [Mojolicious](https://metacpan.org/pod/Mojolicious) and [Mojo::Lite](https://metacpan.org/pod/Mojo::Lite) applications.

    use Mojolicious::Lite;
    plugin 'Renderer::WithoutCache';

# DESCRIPTION

This does what it says on the box. It turns off caching for the [Mojolicious::Renderer](https://metacpan.org/pod/Mojolicious::Renderer)
or any other renderer that's inside `$app->renderer` by injecting a cache object that
does not do anything. This is supperior to setting the `max_keys` of [Mojo::Cache](https://metacpan.org/pod/Mojo::Cache)
to `0` if you plan to do a lot of uncached requests, becase [Mojolicious::Renderer](https://metacpan.org/pod/Mojolicious::Renderer)
will still try to cache, and every time [Mojo::Cache](https://metacpan.org/pod/Mojo::Cache) sets a value in the cache it
looks at the `max_keys`, and then stops.

Doing nothing at all is cheaper. But not a lot really.

# METHODS

## register

Register the plugin in a [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

    $plugin->register(Mojolicious->new);

# AUTHOR

simbabque, `<simbabque at cpan.org>`

# BUGS

Please report any bugs or feature requests through an issue
on github at [https://github.com/simbabque/Mojolicious-Plugin-Renderer-WithoutCache/issues](https://github.com/simbabque/Mojolicious-Plugin-Renderer-WithoutCache/issues).

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::Renderer::WithoutCache

## Why would I want to turn off the cache?

I don't know.

# ACKNOWLEDGEMENTS

This plugin was inspired by Tom Hunt asking about turning the cache off
on [Stack Overflow](http://stackoverflow.com/q/41750243/1331451).

# LICENSE

Copyright (C) simbabque.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
