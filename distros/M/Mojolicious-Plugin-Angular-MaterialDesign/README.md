[![Build Status](https://travis-ci.org/mudler/Mojolicious-Plugin-Angular-MaterialDesign.svg?branch=master)](https://travis-ci.org/mudler/Mojolicious-Plugin-Angular-MaterialDesign)
# NAME

Mojolicious::Plugin::Angular::MaterialDesign - Mojolicious + https://material.angularjs.org/

# DESCRIPTION

[Mojolicious::Plugin::Angular::MaterialDesign](https://metacpan.org/pod/Mojolicious::Plugin::Angular::MaterialDesign) is used to include [https://material.angularjs.org/](https://material.angularjs.org/)
CSS and JavaScript files into your project.

This is done with the help of [Mojolicious::Plugin::AssetPack](https://metacpan.org/pod/Mojolicious::Plugin::AssetPack).

# SYNOPSIS

## Mojolicious

    use Mojolicious::Lite;
    plugin "Angular::MaterialDesign";
    get "/" => "index";
    app->start;

## Template

    <!doctype html>
    <html>
      <head>
        % # ... your angular asset must be loaded before
        %= asset "materialdesign.css"
        %= asset "materialdesign.js"
      </head>
      <body>
        <p class="alert alert-danger">Danger, danger! High Voltage!</p>
      </body>
    </html>

TIP! You might want to load [Mojolicious::Plugin::AssetPack](https://metacpan.org/pod/Mojolicious::Plugin::AssetPack) yourself to specify
options.

# METHODS

## asset\_path

    $path = Mojolicious::Plugin::Angular::MaterialDesign->asset_path();
    $path = $self->asset_path();

Returns the base path to the assets bundled with this module.

## register

    $app->plugin("Angular::MaterialDesign");

Loads the plugin and register the static paths that includes the css and js.

# CREDITS

[angular/material](https://github.com/angular/material) [contributors](https://github.com/angular/material/graphs/contributors)

# LICENSE

Copyright (C) mudler.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

mudler <mudler@dark-lab.net>
