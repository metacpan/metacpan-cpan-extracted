# NAME

Mojolicious::Plugin::Materialize - Mojolicious + http://materializecss.com/

# DESCRIPTION

[Mojolicious::Plugin::Materialize](https://metacpan.org/pod/Mojolicious::Plugin::Materialize) is used to include [http://materializecss.com/](http://materializecss.com/)
CSS and JavaScript files into your project.

This is done with the help of [Mojolicious::Plugin::AssetPack](https://metacpan.org/pod/Mojolicious::Plugin::AssetPack).

# SYNOPSIS

## Mojolicious

    use Mojolicious::Lite;
    plugin "Materialize";
    get "/" => "index";
    app->start;

## Template

    <!doctype html>
    <html>
      <head>
        % # ... your angular asset must be loaded before
        %= asset "materialize.css"
        %= asset "materialize.js"
      </head>
      <body>
        <p class="alert alert-danger">Danger, danger! High Voltage!</p>
      </body>
    </html>

TIP! You might want to load [Mojolicious::Plugin::AssetPack](https://metacpan.org/pod/Mojolicious::Plugin::AssetPack) yourself to specify
options.

# METHODS

## asset\_path

    $path = Mojolicious::Plugin::Materialize->asset_path();
    $path = $self->asset_path();

Returns the base path to the assets bundled with this module.

## register

    $app->plugin("Materialize");

Loads the plugin and register the static paths that includes the css and js.

# CREDITS

[materialize](http://materializecss.com/) [contributors](https://github.com/Dogfalo/materialize/graphs/contributors)

# LICENSE

Copyright (C) mudler.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

mudler <mudler@dark-lab.net>
