package Mojolicious::Plugin::Webpack;
use Mojo::Base 'Mojolicious::Plugin';

use Carp 'confess';
use Mojo::File 'path';
use Mojo::JSON;
use Mojo::Path;
use Mojo::Util;

use constant LAZY => $ENV{MOJO_WEBPACK_LAZY} ? 1 : 0;

our $VERSION = '0.09';

sub assets_dir { shift->{assets_dir} }
sub out_dir    { shift->{out_dir} }
sub node_env   { shift->{node_env} }
sub route      { shift->{route} }

sub register {
  my ($self, $app, $config) = @_;

  # If running inside a shim
  return $app->plugin('Mojolicious::Plugin::Webpack' => $config)
    unless $ENV{MOJO_WEBPACK_TEST_INTERNAL}
    or $self->isa('Mojolicious::Plugin::Webpack');

  $self->{route} = $app->routes->route('/asset/*name')->via(qw(HEAD GET))->name('webpack.asset');

  $self->{$_} = path $config->{$_} for grep { $config->{$_} } qw(assets_dir out_dir);
  $self->{node_env} = $config->{node_env} || ($app->mode eq 'development' ? 'development' : 'production');
  $self->{assets_dir} ||= $self->_build_assets_dir($app);
  $self->{out_dir}    ||= $self->_build_out_dir($app);

  $app->helper(($config->{helper} || 'asset') => sub { $self->_helper(@_) });
  $app->hook(after_static => \&_after_static_hook) unless $config->{no_after_static_hook};
  $app->plugin('Webpack::Builder' => $config) if $ENV{MOJO_WEBPACK_BUILD};
  $self->_register_assets;
}

sub url_for {
  my ($self, $c, $name) = @_;
  my $asset = $self->{assets}{$name} or confess qq(Unknown asset name "$name".);
  return $c->url_for('webpack.asset', $asset->[1]);
}

sub _after_static_hook {
  my $c = shift;

  my $asset_path = $c->app->{'webpack.asset.path'} ||= do {
    my $p = Mojo::Path->new($c->asset->route->render({name => 'name.ext'}));
    pop @$p;
    $p->to_string;
  };

  $c->res->headers->cache_control(LAZY ? 'no-cache' : 'max-age=86400') if 0 == index $c->req->url->path, $asset_path;
}

sub _build_assets_dir {
  my ($self, $app) = @_;
  my $dir = $app->home->rel_file('assets');
  $dir->make_path unless -d $dir;
  return $dir;
}

sub _build_out_dir {
  my ($self, $app) = @_;
  my $route = Mojo::Path->new($self->route->render({name => 'name.ext'}));
  pop @$route;
  my $dir = path $app->static->paths->[0], @$route;
  $dir->make_path unless -d $dir;
  return $dir;
}

sub _helper {
  my ($self, $c, $name, @args) = @_;
  return $self if @_ == 2;
  return $self->$name($c, @args) if $name =~ m!^\w+$!;

  $self->_register_assets if LAZY;    # Lazy read the generated markup
  my $asset = $self->{assets}{$name} or confess qq(Unknown asset name "$name".);
  my ($tag_helper, $route_args) = @$asset;
  return $c->$tag_helper($c->url_for('webpack.asset', $route_args), @args);
}

sub _register_assets {
  my $self           = shift;
  my $path_to_markup = $self->out_dir->child(sprintf 'webpack.%s.html',
    $ENV{WEBPACK_CUSTOM_NAME} || ($self->node_env ne 'production' ? 'development' : 'production'));

  unless (-e $path_to_markup) {
    warn "[Webpack] Could not find $path_to_markup. Sure webpack has been run?"
      if !$ENV{HARNESS_VERSION} or $ENV{HARNESS_IS_VERBOSE};
    return,;
  }

  my $markup  = Mojo::DOM->new($path_to_markup->slurp);
  my $name_re = qr{(.*)\.\w+\.(css|js)$}i;

  $markup->find('link')->each(sub {
    my $name = shift->{href} // '';
    $self->{assets}{"$1.$2"} = [stylesheet => {name => $name}] if $name =~ $name_re;
  });

  $markup->find('script')->each(sub {
    my $name = shift->{src} // '';
    $self->{assets}{"$1.$2"} = [javascript => {name => $name}] if $name =~ $name_re;
  });
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Webpack - Mojolicious ♥ Webpack

=head1 SYNOPSIS

Check out
L<https://github.com/jhthorsen/mojolicious-plugin-webpack/tree/master/example/webpack>
for a working example.

=head2 Define assets

One or more assets need to be defined. The minimum is to create one
L<entry point|https://webpack.js.org/concepts/#entry> and add it to
the C<webpack.custom.js> file.

  # Entrypoint: ./assets/entry-cool_beans.js
  // This will result in one css and one js asset.
  import '../css/css-example.css';
  console.log('I'm loaded!');

  # Config file: ./assets/webpack.custom.js
  module.exports = function(config) {
    config.entry = {
      'cool_beans': './assets/entry-cool_beans.js',
    };
  };

=head2 Application

Your lite or full app, need to load L<Mojolicious::Plugin::Webpack> and
tell it what kind of assets it should be able to process:

  $app->plugin(Webpack => {process => [qw(js css)]});

See L</register> for more config options.

=head2 Template

To include the generated assets in your template, you can use the L</asset>
helper:

  %= asset "cool_beans.css"
  %= asset "cool_beans.js"

=head2 Start application

You can start the application using C<daemon>, C<hypnotoad> or any Mojolicious
server you want, but if you want rapid development you should use
C<mojo webpack>, which is an alternative to C<morbo>:

  $ mojo webpack -h
  $ mojo webpack ./myapp.pl

However if you want to use another daemon and make C<webpack> run, you need to
set the C<MOJO_WEBPACK_BUILD> environment variable to "1". Example:

  MOJO_WEBPACK_BUILD=1 ./myapp.pl daemon

=head2 Testing

If you want to make sure you have built all the assets, you can make a test
file like "build-assets.t":

  use Test::More;
  use Test::Mojo;

  # Run with TEST_BUILD_ASSETS=1 prove -vl t/build-assets.t
  plan skip_all => "TEST_BUILD_ASSETS=1" unless $ENV{TEST_BUILD_ASSETS};

  # Load the app and make a test object
  $ENV{MOJO_MODE}          = 'production';
  $ENV{MOJO_WEBPACK_BUILD} = 1;
  use FindBin;
  require "$FindBin::Bin/../myapp.pl";
  my $t = Test::Mojo->new;

  # Find all the tags and make sure they can be loaded
  $t->get_ok("/")->status_is(200);
  $t->element_count_is('script[src], link[href][rel=stylesheet]', 2);
  $t->tx->res->dom->find("script[src], link[href][rel=stylesheet]")->each(sub {
    $t->get_ok($_->{href} || $_->{src})->status_is(200);
  });

  done_testing;

=head1 DESCRIPTION

L<Mojolicious::Plugin::Webpack> is a L<Mojolicious> plugin to make it easier to
work with L<https://webpack.js.org/>. This means that this is mostly a
developer tool. This point is emphasized by installing a "shim" so your
application does not depend on this plugin at all when running in production.
See L<Mojolicious::Plugin::Webpack::Builder/PLUGIN SHIM> for more information.

There is also support for L<https://rollupjs.org/>. See L</Rollup> for more
information.

L<Mojolicious::Plugin::Webpack> is currently EXPERIMENTAL, but it's unlikely it
will change dramatically.

After creating the file, you can run the command below to get a development
server:

  $ perl myapp.pl webpack -c rollup.config.js

If you want to do L</Testing>, you have to set the environment variable
C<MOJO_WEBPACK_CONFIG> in addition to L<TEST_BUILD_ASSETS>:

  $ENV{MOJO_WEBPACK_CONFIG} = 'rollup.config.js';

=head2 Rollup

L<rollup.js|https://rollupjs.org/> is an alternative to Webpack. Both
accomplish more or less the same thing, but in different ways. There might be a
"Rollup" plugin in the future, but for now this plugin supports both.

For now, you need to write your own "rollup.config.js" file. See
L<https://github.com/jhthorsen/mojolicious-plugin-webpack/tree/master/example/rollup>
for a working example.

=head1 MIGRATING FROM ASSETPACK

Are you already a user of L<Mojolicious::Plugin::AssetPack>?
L<Mojolicious::Plugin::Webpack> will automatically detect your C<assetpack.def>
file and convert it into a custom webpack config, so you don't have to do
much, except changing how you load the plugin:

  # AssetPack
  $app->plugin(AssetPack => {pipes => [qw(Sass JavaScript)]});

  # Webpack
  $app->plugin(Webpack => {process => [qw(sass js)]});

=head1 HELPERS

=head2 asset

  # Call a method or access an attribute in this class
  my $path = $app->asset->out_dir;

  # Call a method, but from inside a mojo template
  %= asset->url_for($c, "cool_beans.css")

  # Generate a HTML tag
  my $bytestream = $c->asset("cool_beans.js", @args);

  # Generate a HTML tag, but from inside a mojo template
  %= asset "cool_beans.css", media => "print"
  %= asset(url_for => "cool_beans.css")

This helper will return the plugin instance if no arguments is passed in, or a
HTML tag created with either L<Mojolicious::Plugin::TagHelpers/javascript> or
L<Mojolicious::Plugin::TagHelpers/stylesheet> if a valid asset name is passed
in.

You can also use it to call a method and pass on C<$c> by passing in a method
name as the first argument, such as L</url_for>.

=head1 ATTRIBUTES

=head2 assets_dir

  $path = $self->assets_dir;

Holds a L<Mojo::File> object pointing to the private directoy where source
files are read from. Defaults value is:

  $app->home->rel_file("assets");

=head2 node_env

  $str = $self->node_env;

Used to set C<NODE_ENV> environment value.

Defaults value is "development" if L<Mojolicious/mode> is "development" and
"production" otherwise. This value usually tells webpack to either minify the
assets or generate readable output while developing.

=head2 out_dir

  $path = $self->out_dir;

Holds a L<Mojo::File> object pointing to the public directoy where processed
assets are written to. Default value is:

  $app->static->paths->[0] . "/asset";

=head2 route

  $route = $self->route;

Holds a L<Mojolicious::Routes::Route> object that generates the URLs to a
processed asset. Default value is C</asset/*name>.

=head1 METHODS

=head2 register

  $self->register($app, \%config);
  $app->plugin("Webpack", \%config);

Used to register this plugin into your L<Mojolicious> app.

The C<%config> passed when loading this plugin can have any of the
L<Mojolicious::Plugin::Webpack::Builder/ATTRIBUTES>, in addition to these
attributes:

=over 2

=item * helper

Name of the helper that will be added to your application.

Default: "asset".

=back

=head2 url_for

  $url = $self->url_for($c, $asset_name);

Returns a L<Mojo::URL> for a given asset.

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojolicious::Plugin::Webpack::Builder>.

L<Mojolicious::Plugin::AssetPack>.

=cut
