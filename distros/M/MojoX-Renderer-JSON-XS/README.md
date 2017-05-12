[![Build Status](https://travis-ci.org/yowcow/MojoX-Renderer-JSON-XS.svg?branch=master)](https://travis-ci.org/yowcow/MojoX-Renderer-JSON-XS)
# NAME

MojoX::Renderer::JSON::XS - Fast JSON::XS handler for Mojolicious::Renderer

# SYNOPSIS

    sub setup {
        my $app = shift;

        # Via plugin
        $app->plugin('JSON::XS');

        # Or manually
        $app->renderer->add_handler(
            json => MojoX::Renderer::JSON::XS->build,
        );
    }

# DESCRIPTION

MojoX::Renderer::JSON::XS provides fast [JSON::XS](https://metacpan.org/pod/JSON::XS) renderer to [Mojolicious](https://metacpan.org/pod/Mojolicious) applications.

# METHODS

## build

Returns a handler for `Mojolicious::Renderer` that calls `JSON::XS::encode_json`.

# SEE ALSO

[JSON::XS](https://metacpan.org/pod/JSON::XS)
[Mojolicious](https://metacpan.org/pod/Mojolicious)
[Mojolicious::Renderer](https://metacpan.org/pod/Mojolicious::Renderer)

# LICENSE

Copyright (C) yowcow.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

yowcow &lt;yowcow@cpan.org>
