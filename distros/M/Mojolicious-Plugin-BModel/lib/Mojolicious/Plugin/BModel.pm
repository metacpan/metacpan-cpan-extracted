package Mojolicious::Plugin::BModel;

use 5.010;
use strict;
use warnings;
use Carp qw/ croak /;
use File::Find qw/ find /;

use Mojo::Loader;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.09';

my $CREATE_DIR = 1;
my $MODEL_DIR  = 'Model'; # directory of poject for the Model-modules
my %MODULES    = ();
my $BASE_MODEL = 'Mojolicious::BModel::Base';

sub register {
    my ( $self, $app, $conf ) = @_;

    my $app_name      = ref $app; # name of calling app
    my $path_to_model = $app->home->lib_dir . '/' . $app_name . '/' . $MODEL_DIR;
    my $dir_exists    = $self->check_model_dir( $path_to_model );
    my $create_dir    = $conf->{create_dir} || $CREATE_DIR;

    if ( ! $dir_exists && ! $create_dir ) {
        warn "Directory $app_name/$MODEL_DIR does not exist";
        return 1;
    }
    elsif ( ! $dir_exists && $create_dir ) {
        mkdir $path_to_model or croak "Could not create directory $path_to_model : $!";
    }

    $self->load_models( $path_to_model, $app_name, $app );

    $app->helper(
        model => sub {
            my ( $self, $model_name ) = @_;
            $model_name =~ s/\/+/::/g;
            croak "Unknown model $model_name" unless $MODULES{ $model_name };
            return $MODULES{ $model_name };
        }
    );

    return 1;
}

sub check_model_dir {
    my ( $self, $path_to_model ) = @_;

    return 1 if -e $path_to_model && -d $path_to_model;
    return;
}

sub find_models {
    my ( $self, $path_to_model, $model_path ) = @_;

    my @model_dirs = ( $model_path );

    # find all subdirs in the directory of model
    find(
        sub {
            return if ! -d $File::Find::name || $File::Find::name eq $path_to_model;
            my $dir_name = $File::Find::name;
            $dir_name =~ s/$path_to_model\/?(.+)/$1/;
            $dir_name =~ s/(\/)+/::/g;
            push @model_dirs, $model_path . '::' . $dir_name;
        },
        ( $path_to_model )
    );

    return \@model_dirs;
}

# recursive search and download modules with models
sub load_models {
    my ( $self, $path_to_model, $app_name, $app ) = @_;

    my $model_path = "$app_name\::$MODEL_DIR";
    my @model_dirs = @{ $self->find_models( $path_to_model, $model_path ) };

    my $base_load_err = Mojo::Loader::load_class( $BASE_MODEL );
    croak "Loading base model $BASE_MODEL failed: $base_load_err" if ref $base_load_err;
    {
        no strict 'refs';
        *{ "$BASE_MODEL\::app" } = sub { $app };
    }

    # load modules from every dirs and subdirs of model
    for my $dir ( @model_dirs ) {
        my @model_packages = Mojo::Loader::find_modules( $dir );
        for my $pm ( @model_packages ) {
            my $load_err = Mojo::Loader::load_class( $pm );
            croak "Loading '$pm' failed: $load_err" if ref $load_err;
            my ( $basename ) = $pm =~ /$model_path\::(.*)/;
            $MODULES{ $basename } = $pm->new;
        }
    }

    return 1;
}

1;

__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::BModel - Catalyst-like models in Mojolicious

=head1 SYNOPSIS

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

=head1 DESCRIPTION

    This module provides you an ability to separate a business-logic from controllers into a 'model' class
    and use this one by the method 'model' of a controller object.
    This approach is using in the L<Catalyst framework|https://metacpan.org/pod/Catalyst>.

=head2 Options

=over

=item B<create_dir>

    A flag that determines automatically create the folder '<yourapp>/lib/Model'
    if it does not exist. 0 - do not create, 1 - create. Enabled by default

=back

=cut

=head1 EXAMPLE

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


=head1 LICENSE

Copyright (C) 2016 Alexander Ruzhnikov.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Alexander Ruzhnikov E<lt>ruzhnikov85@gmail.comE<gt>

=cut

