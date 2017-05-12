package Mojolicious::Plugin::Materialize;
use 5.010001;
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Plugin';
use Mojolicious::Plugin::AssetPack;
use File::Spec::Functions 'catdir';
use Cwd ();
our $VERSION = "0.9770";

my @DEFAULT_CSS_FILES = qw( materialize.css );
my @DEFAULT_JS_FILES  = qw( materialize.js);

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
        $app->asset( 'materialize.css' => map {"/css/$_"}
                @{ $config->{css} } );
    }

    if ( @{ $config->{js} } ) {
        $app->asset( 'materialize.js' => map {"/js/$_"} @{ $config->{js} },
        );
    }

}

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::Materialize - Mojolicious + http://materializecss.com/

=head1 DESCRIPTION

L<Mojolicious::Plugin::Materialize> is used to include L<http://materializecss.com/>
CSS and JavaScript files into your project.

This is done with the help of L<Mojolicious::Plugin::AssetPack>.

=head1 SYNOPSIS

=head2 Mojolicious

  use Mojolicious::Lite;
  plugin "Materialize";
  get "/" => "index";
  app->start;

=head2 Template

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

TIP! You might want to load L<Mojolicious::Plugin::AssetPack> yourself to specify
options.


=head1 METHODS

=head2 asset_path

  $path = Mojolicious::Plugin::Materialize->asset_path();
  $path = $self->asset_path();

Returns the base path to the assets bundled with this module.

=head2 register

  $app->plugin("Materialize");

Loads the plugin and register the static paths that includes the css and js.

=head1 CREDITS

L<materialize|http://materializecss.com/> L<contributors|https://github.com/Dogfalo/materialize/graphs/contributors>

=head1 LICENSE

Copyright (C) mudler.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=cut

