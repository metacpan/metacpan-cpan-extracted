package Mojolicious::Plugin::Webpack;
use Mojo::Base 'Mojolicious::Plugin';

use Carp qw(carp croak);
use Mojo::File qw(path);
use Mojo::Path;
use Mojo::Util;

use constant DEBUG => $ENV{MOJO_WEBPACK_DEBUG} && 1;

our @CARP_NOT;
our $VERSION = '1.01';

has engine => undef;

sub asset_map {
  my $self = shift;

  # Production
  return $self->{asset_map} if $self->{cache_asset_map};

  # Development or initial load
  my $produced  = $self->engine->asset_map;
  my %asset_map = (development => {}, production => {});
  for my $rel_name (keys %$produced) {
    my $asset  = $produced->{$rel_name};
    my $helper = $asset->{ext} eq 'js' ? 'javascript' : $asset->{ext} eq 'css' ? 'stylesheet' : 'image';
    $asset_map{$asset->{mode}}{$asset->{name}} = {%$asset, helper => $helper, rel_name => $rel_name};
  }

  my $mode = $self->engine->mode;
  $self->{asset_map} = $asset_map{production};
  for my $name (keys %{$asset_map{development}}) {
    $mode eq 'development'
      ? ($self->{asset_map}{$name} = $asset_map{development}{$name})
      : ($self->{asset_map}{$name} ||= $asset_map{development}{$name});
  }

  return $self->{asset_map};
}

sub register {
  my ($self, $app, $config) = @_;

  my $asset_path = ($config->{asset_path} ||= '/asset');    # EXPERIMENTAL
  $asset_path .= '/';
  $app->routes->any([qw(HEAD GET)] => "$asset_path*name")->name('webpack.asset');

  $app->helper(($config->{helper} || 'asset') => sub { $self->_helper(@_) });
  $self->_build_engine($app, $config);
  $app->plugins->emit_hook(before_webpack_start => $self);

  my $cache_control = 'no-cache';
  if (my $build_method = $ENV{MOJO_WEBPACK_BUILD}) {
    $build_method = 'exec'  if $build_method =~ m!exec|watch!;
    $build_method = 'build' if $build_method ne 'exec';
    $self->engine->_d('MOJO_WEBPACK_BUILD=%s', $build_method) if DEBUG;
    $self->engine->$build_method;    # "exec" will take over the current process
  }
  else {
    $self->asset_map;
    $self->{cache_asset_map} = !defined $ENV{MOJO_WEBPACK_BUILD};
    $cache_control = $config->{cache_control} // 'max-age=86400' if $self->{cache_asset_map};
  }

  $app->hook(
    after_static => sub {
      my $c = shift;
      $c->res->headers->cache_control($cache_control) if index($c->req->url->path, $asset_path) == 0;
    }
  );
}

sub url_for {
  my ($self, $c, $name) = @_;
  _unknown_asset($name) unless my $asset = $self->asset_map->{$name};
  return $c->url_for('webpack.asset', {name => $asset->{rel_name}});
}

sub _build_engine {
  my ($self, $app, $config) = @_;

  # Custom engine
  my $engine = $config->{engine} || 'Mojo::Alien::webpack';

  # Build default engine
  $engine = eval "require $engine;$engine->new" || die "Could not load engine $engine: $@";
  $engine->assets_dir($app->home->rel_file('assets'));
  $engine->config($app->home->rel_file($engine->isa('Mojo::Alien::rollup') ? 'rollup.config.js' : 'webpack.config.js'));
  $engine->include($config->{process} || ['js']);
  $engine->mode($app->mode eq 'development' ? 'development' : 'production');
  $engine->out_dir(path($app->static->paths->[0], grep $_, split '/', $config->{asset_path})->to_abs);

  map { $engine->_d('%s = %s', $_, $engine->$_) } qw(config assets_dir out_dir mode) if DEBUG;
  return $self->{engine} = $engine;
}

sub _helper {
  my ($self, $c, $name, @args) = @_;
  return $self                   if @_ == 2;
  return $self->$name($c, @args) if $name =~ m!^\w+$!;

  _unknown_asset($name) unless my $asset = $self->asset_map->{$name};
  my $helper = $asset->{helper} || 'url_for';
  return $c->$helper($c->url_for('webpack.asset', {name => $asset->{rel_name}}), @args);
}

sub _unknown_asset {
  local @CARP_NOT = qw(Mojolicious::Plugin::EPRenderer Mojolicious::Plugin::Webpack Mojolicious::Renderer);
  croak qq(Unknown asset name "$_[0]".);
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Webpack - Mojolicious ♥ Webpack

=head1 SYNOPSIS

=head2 Define entrypoint

Create a file "./assets/index.js" relative to you application directory with
the following content:

  console.log('Cool beans!');

=head2 Application

Your L<Mojolicious> application need to load the
L<Mojolicious::Plugin::Webpack> plugin and tell it what kind of assets it
should be able to process:

  $app->plugin(Webpack => {process => [qw(js css)]});

See L</register> for more configuration options.

=head2 Template

To include the generated assets in your template, you can use the L</asset>
helper:

  %= asset "cool_beans.css"
  %= asset "cool_beans.js"

=head2 Run the application

You can start the application using C<daemon>, C<hypnotoad> or any Mojolicious
server you want, but if you want rapid development you should use
C<mojo webpack>, which is an alternative to C<morbo>:

  $ mojo webpack -h
  $ mojo webpack ./script/myapp.pl

However if you want to use another daemon and force C<webpack> to run, you need
to set the C<MOJO_WEBPACK_BUILD> environment variable to "1". Example:

  MOJO_WEBPACK_BUILD=1 ./script/myapp.pl daemon

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
  require "$FindBin::Bin/../script/myapp.pl";
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
work with L<https://webpack.js.org/> or L<https://rollupjs.org/>. This plugin
will...

=over 2

=item 1.

Generate a minimal C<package.json> and a Webpack or Rollup config file. Doing
this manually is possible, but it can be quite time consuming to figure out all
the bits and pieces if you are not already familiar with Webpack.

=item 2.

Load the entrypoint "./assets/index.js", which is the starting point of your
client side application. The entry file can load JavaScript, CSS, SASS, ... as
long as the appropriate processing plugin is loaded.

=item 3.

It can be difficult to know exactly which plugins to use with Webpack. Because
of this L<Mojolicious::Plugin::Webpack> has some predefined rules for which
Nodejs dependencies to fetch and  install. None of the nodejs modules are
required in production though, so it will only be installed while developing.

=item 4.

While developing, the webpack executable will be started automatically next to
L<Mojo::Server::Morbo>. Webpack will be started with the appropriate switches
to watch your source files and re-compile on change.

=back

=head2 Rollup

L<rollup.js|https://rollupjs.org/> is an alternative to Webpack. Both
accomplish more or less the same thing, but in different ways.

To be able to use rollup, you have to load this plugin with a different engine:

  $app->plugin(Webpack => {engine => 'Mojo::Alien::rollup', process => [qw(js css)]});

=head2 Notice

L<Mojolicious::Plugin::Webpack> is currently EXPERIMENTAL.

=head1 HELPERS

=head2 asset

  # Call a method or access an attribute in this class
  my $path = $app->asset->engine->out_dir;

  # Call a method, but from inside a mojo template
  %= asset->url_for($c, "cool_beans.css")

  # Generate a HTML tag
  my $bytestream = $c->asset("cool_beans.js", @args);

  # Generate a HTML tag, but from inside a mojo template
  %= asset "cool_beans.css", media => "print"
  %= asset(url_for => "cool_beans.css")

The most basic usage of this helper is to create a HTML tag using
L<Mojolicious::Plugin::TagHelpers/javascript> or
L<Mojolicious::Plugin::TagHelpers/stylesheet> if a valid asset name is passed in.

On the other hand, the helper will return the plugin instance if no arguments
are passed in, allowing you to call any of the L</METHODS> or access the
L</ATTRIBUTES>.

=head1 HOOKS

=head2 before_webpack_start

  $app->before_webpack_start(sub { my $webpack = shift; ... });

Emitted right before the plugin starts building or loading in the generated
assets. Useful if you want to change any of the L</engine> attributes from the
defaults.

=head1 ATTRIBUTES

=head2 engine

  $engine = $webpack->engine;

Returns a L<Mojo::Alien::webpack> or L<Mojo::Alien::rollup> object.

=head1 METHODS

=head2 asset_map

  $hash_ref = $webpack->asset_map;

Reads all the generated files in L</asset_path> and returns a hash-ref like
this:

  {
    "relative/output.js" => {               # Key is a friendly name, withouc checksum
      ext      => 'css',                    # File extension
      helper   => 'javascript',             # Mojolicious helper used to render the asset
      rel_name => "relatibe/output.xyz.js", # Relative filename with checksum
    },
    ...
  }

Note that changing this hash might change how L</asset> and L</url_for> behaves!

=head2 register

  $webpack->register($app, \%config);
  $app->plugin("Webpack", \%config);

Used to register this plugin into your L<Mojolicious> app.

The C<%config> passed when loading this plugin can have any of these
attributes:

=over 2

=item * asset_path

Can be used to specify an alternative static directory to output the built
assets to.

Default: "/asset".

=item * cache_control

Used to set the response "Cache-Control" header for built assets.

Default: "no-cache" while developing and "max-age=86400" in production.

=item * engine

Must be a valid engine class name. Examples:

  $app->plugin("Webpack", {engine => 'Mojo::Alien::rollup'});
  $app->plugin("Webpack", {engine => 'Mojo::Alien::webpack'});

Default: L<Mojo::Alien::webpack>.

=item * helper

Name of the helper that will be added to your application.

Default: "asset".

=item * process

Used to specify L<Mojo::Alien::webpack/include> or  L<Mojo::Alien::rollup/include>.

Default: C<['js']>.

=back

=head2 url_for

  $url = $webpack->url_for($c, $asset_name);

Returns a L<Mojo::URL> for a given asset.

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

Copyright (C) Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojo::Alien::rollup>, L<Mojo::Alien::webpack>.

=cut
