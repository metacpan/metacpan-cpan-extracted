package Mojolicious::Plugin::Angular::MaterialDesign;
use 5.008001;
use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';
use Mojolicious::Plugin::AssetPack;
use File::Spec::Functions 'catdir';
use Cwd ();

our $VERSION = '1.1.0';

my @DEFAULT_CSS_FILES = qw( angular-material.min.css );
my @DEFAULT_JS_FILES  = qw( angular-material.min.js);

sub asset_path {
    my ( $class ) = @_;
    my $path = Cwd::abs_path(__FILE__);
    $path =~ s!\.pm$!!;
    return $path;
}

sub register {
    my ( $self, $app, $config ) = @_;

    $app->plugin('AssetPack') unless eval { $app->asset };

    $config->{css} ||= [@DEFAULT_CSS_FILES];
    $config->{js}  ||= [@DEFAULT_JS_FILES];
    $config->{jquery} //= 1;

    push @{ $app->static->paths }, $self->asset_path;

    # TODO: 'bootstrap_resources.scss'
    if ( @{ $config->{css} } ) {
        $app->asset( 'materialdesign.css' => map {"/css/$_"}
                @{ $config->{css} } );
    }

    if ( @{ $config->{js} } ) {
        $app->asset( 'materialdesign.js' => map {"/js/$_"} @{ $config->{js} },
        );
    }

}

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::Angular::MaterialDesign - Mojolicious + https://material.angularjs.org/

=head1 DESCRIPTION

L<Mojolicious::Plugin::Angular::MaterialDesign> is used to include L<https://material.angularjs.org/>
CSS and JavaScript files into your project.

This is done with the help of L<Mojolicious::Plugin::AssetPack>.

=head1 SYNOPSIS

=head2 Mojolicious

  use Mojolicious::Lite;
  plugin "Angular::MaterialDesign";
  get "/" => "index";
  app->start;

=head2 Template

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

TIP! You might want to load L<Mojolicious::Plugin::AssetPack> yourself to specify
options.


=head1 METHODS

=head2 asset_path

  $path = Mojolicious::Plugin::Angular::MaterialDesign->asset_path();
  $path = $self->asset_path();

Returns the base path to the assets bundled with this module.

=head2 register

  $app->plugin("Angular::MaterialDesign");

Loads the plugin and register the static paths that includes the css and js.

=head1 CREDITS

L<angular/material|https://github.com/angular/material> L<contributors|https://github.com/angular/material/graphs/contributors>

=head1 LICENSE

Copyright (C) mudler.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=cut

