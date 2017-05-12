[![Build Status](https://travis-ci.org/ruzhnikov/Mojolicious-Plugin-BModel.svg?branch=master)](https://travis-ci.org/ruzhnikov/Mojolicious-Plugin-BModel)
# NAME

Mojolicious::Plugin::BModel - Catalyst-like models in Mojolicious

# SYNOPSIS

    # Mojolicious

    # in your app:
    sub startup {
        my $self = shift;

        $self->plugin( 'BModel', { create_dir => 1 } );
    }

    # in controller:
    sub my_controller {
        my $self = shift;

        my $config_data = $self->model('MyModel')->get_conf_data('field');
    }

    # in <your_app>/lib/Model/MyModel.pm:

    use Mojo::Base 'Mojolicious::BModel::Base';

    sub get_conf_data {
        my ( $self, $field ) = @_;

        # as example
        return $self->config->{field};
    }

# DESCRIPTION

    This module provides you an ability to separate a business-logic from controllers into a 'model' class
    and use this one by the method 'model' of a controller object.
    This approach is using in the L<Catalyst framework|https://metacpan.org/pod/Catalyst>.

## Options

- **create\_dir**

        A flag that determines automatically create the folder '<yourapp>/lib/Model'
        if it does not exist. 0 - do not create, 1 - create. Enabled by default

# EXAMPLE

    # the example of a new application:
    % cpan install Mojolicious::Plugin::BModel
    % mojo generate app MyApp
    % cd my_app/
    % vim lib/MyApp.pm

    # edit file:
    package MyApp;

    use Mojo::Base 'Mojolicious';

    sub startup {
        my $self = shift;

        $self->config->{testkey} = 'MyTestValue';

        $self->plugin( 'BModel' ); # used the default options

        my $r = $self->routes;
        $r->get('/')->to( 'root#index' );
    }

    1;

    # end of edit file

    # create a new controller

    % touch lib/Controller/Root.pm
    % vim lib/Controller/Root.pm

    # edit file

    package MyApp::Controller::Root;

    use Mojo::Base 'Mojolicious::Controller';

    sub index {
        my $self = shift;

        my $testkey_val = $self->model('MyModel')->get_conf_key('testkey');
        $self->render( text => 'Value: ' . $testkey_val );
    }

    1;

    # end of edit file

    # When you connect, the plugin will check if the folder "lib/Model".
    # If the folder does not exist, create it.
    # If the 'use_base_model' is set to true will be loaded
    # module "Mojolicious::BModel::Base" with the base model.
    # Method 'app' base model will contain a link to your application.
    # Method 'config' base model will contain a link to config of yor application.

    # create a new model
    % touch lib/MyApp/Model/MyModel.pm
    % vim lib/MyApp/Model/MyModel.pm

    # edit file

    package MyApp::Model::MyModel;

    use strict;
    use warnings;

    use Mojo::Base 'Mojolicious::BModel::Base';

    sub get_conf_key {
        my ( $self, $key ) = @_;

        return $self->config->{ $key } || '';
    }

    1;

    # end of edit file

    % morbo -v script/my_app

    # Open in your browser address http://127.0.0.1:3000 and
    # you'll see text 'Value: MyTestValue'

# LICENSE

Copyright (C) 2016 Alexander Ruzhnikov.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Alexander Ruzhnikov <ruzhnikov85@gmail.com>
