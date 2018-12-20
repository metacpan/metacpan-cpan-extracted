package Mojolicious::Plugin::Webpack;
use Mojo::Base 'Mojolicious::Plugin';

use Carp 'confess';
use Mojo::File 'path';
use Mojo::JSON;
use Mojo::Path;
use Mojo::Util;

use constant DEBUG => $ENV{MOJO_WEBPACK_DEBUG} ? 1 : 0;
use constant LAZY  => $ENV{MOJO_WEBPACK_LAZY}  ? 1 : 0;

our $VERSION = '0.03';

sub assets_dir { shift->{assets_dir} }

has dependencies => sub {
  return {
    core => [qw(webpack-cli webpack webpack-md5-hash html-webpack-plugin)],
    css  => [qw(css-loader mini-css-extract-plugin optimize-css-assets-webpack-plugin)],
    js   => [qw(@babel/core @babel/preset-env babel-loader uglifyjs-webpack-plugin)],
    sass => [qw(node-sass sass-loader)],
    vue  => [qw(vue vue-loader vue-template-compiler)],
  };
};

sub out_dir { shift->{out_dir} }
sub route   { shift->{route} }

sub register {
  my ($self, $app, $config) = @_;
  my $helper = $config->{helper} || 'asset';

  # TODO: Not sure if this should be global or not
  $ENV{NODE_ENV} ||= $app->mode eq 'development' ? 'development' : 'production';

  $self->{$_} = $config->{$_} // 1 for qw(auto_cleanup source_maps);
  $self->{process} = $config->{process} || ['js'];
  $self->{route} ||= $app->routes->route('/asset/*name')->via(qw(HEAD GET))->name('webpack.asset');

  $self->{$_} = path $config->{$_} for grep { $config->{$_} } qw(assets_dir out_dir);
  $self->{assets_dir} ||= path $app->home->rel_file('assets');
  $self->{out_dir} ||= $self->_build_out_dir($app);

  $self->_migrate_from_assetpack;
  $self->dependencies->{$_} = $config->{dependencies}{$_} for keys %{$config->{dependencies} || {}};
  $self->_webpack_run($app) if $ENV{MOJO_WEBPACK_RUN};
  $self->_register_assets;
  $app->helper($helper => sub { $self->_helper(@_) });
}

sub url_for {
  my ($self, $c, $name) = @_;
  my $asset = $self->{assets}{$name} or confess qq(Unknown asset name "$name".);
  return $c->url_for('webpack.asset', $asset->[1]);
}

sub _build_out_dir {
  my ($self, $app) = @_;
  my $path = Mojo::Path->new($self->route->render({name => 'name.ext'}));
  pop @$path;
  return path $app->static->paths->[0], @$path;
}

sub _custom_file {
  return shift->assets_dir->child(sprintf 'webpack.%s.js', $ENV{WEBPACK_CUSTOM_NAME} || 'custom');
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

sub _install_node_deps {
  my $self         = shift;
  my $package_file = $self->{files}{'package.json'}[1];
  my $package_json = Mojo::JSON::decode_json($package_file->slurp);
  my $n            = 0;

  my $CWD = Mojolicious::Plugin::Webpack::CWD->new($package_file->dirname);
  system qw(npm install) if %{$package_json->{dependencies}} and !-d 'node_modules';

  for my $preset ('core', @{$self->{process}}) {
    for my $module (@{$self->dependencies->{$preset} || []}) {
      next if $package_json->{dependencies}{$module};
      warn "[Webpack] npm install $module\n" if DEBUG;
      system npm => install => $module;
      $n++;
    }
  }

  return $n;
}

sub _migrate_from_assetpack {
  my $self = shift;

  my $assetpack_def = $self->assets_dir->child('assetpack.def');
  return unless -e $assetpack_def;

  my $webpack_custom = $self->_custom_file;
  if (-s $webpack_custom) {
    warn <<"HERE";
[Webpack] Cannot migrate from AssetPack, since @{[$webpack_custom->basename]} exists.
Please remove
  $webpack_custom
to migrate, or remove
  $assetpack_def
if you have migrated.
HERE
    return;
  }

  # Copy/paste from AssetPack.pm
  my ($topic, %found);
  for (split /\r?\n/, $assetpack_def->slurp) {
    s/\s*\#.*//;
    if (/^\<(\S*)\s+(\S+)\s*(.*)/) {
      my ($class, $url, $args) = ($1, $2, $3);
      $topic =~ s!\.\w+$!!;    # Remove extension
      push @{$found{$topic}}, $url;
    }
    elsif (/^\!\s*(.+)/) { $topic = Mojo::Util::trim($1); }
  }

  my $entries = '';
  for my $topic (sort keys %found) {
    my $entry = $self->assets_dir->child("entry-$topic.js");
    warn "[Webpack] Generate entrypoint: $entry\n";
    $entry->spurt(join '', map {qq(import "./$_";\n)} @{$found{$topic}}) unless -e $entry;
    $entries .= sprintf qq(    '%s': './%s/entry-%s.js',\n), $topic, $self->assets_dir->basename, $topic;
  }

  $entries =~ s!,\n$!!s;
  warn "[Webpack] Generate webpack config: $webpack_custom\n";
  $webpack_custom->spurt(<<"HERE");
module.exports = function(config) {
  config.entry = {
$entries
  };
};
HERE

  warn <<"HERE";
[Webpack] AssetPack .def file was migrated into webpack config file:

$assetpack_def
  => $webpack_custom

You might want to remove old AssetPack files, such as:
* @{[$self->assets_dir->child('assetpack.def')]}
* @{[$self->assets_dir->child('assetpack.db')]}
* @{[$self->assets_dir->child('cache')]}/*css
* @{[$self->assets_dir->child('cache')]}/*js

HERE

}

sub _render_to_file {
  my ($self, $app, $name, $out_file) = @_;
  my $is_generated = '';

  eval {
    $out_file ||= $app->home->rel_file($name);
    my $CFG = $out_file->open('<');
    /Autogenerated\s*by\s*Mojolicious-Plugin-Webpack/i and $is_generated = $_ while <$CFG>;
  };

  return $self->{files}{$name} = [custom => $out_file] if !$is_generated and -r $out_file;
  return $self->{files}{$name} = [current => $out_file] if $is_generated =~ /\b$VERSION\b/;

  my $template = $self->_share_dir->child($name)->slurp;
  $template =~ s!__AUTOGENERATED__!Autogenerated by Mojolicious-Plugin-Webpack $VERSION!g;
  $template =~ s!__NAME__!{$app->moniker}!ge;
  $template =~ s!__VERSION__!{$app->VERSION || '0.0.1'}!ge;
  $out_file->spurt($template);
  return $self->{files}{$name} = [generated => $out_file];
}

sub _register_assets {
  my $self           = shift;
  my $path_to_markup = $self->out_dir->child(sprintf 'webpack.%s.html',
    $ENV{WEBPACK_CUSTOM_NAME} || ($ENV{NODE_ENV} ne 'production' ? 'development' : 'production'));

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

sub _webpack_run {
  my ($self, $app) = @_;

  $self->_render_to_file($app, 'package.json');
  $self->_render_to_file($app, 'webpack.config.js');
  $self->_render_to_file($app, 'webpack.custom.js', $self->_custom_file);
  $self->_install_node_deps;

  my $env = $self->_webpack_environment;
  map { warn "[Webpack] $_=$env->{$_}\n" } grep {/^WEBPACK_/} sort keys %$env if DEBUG;

  path($env->{WEBPACK_OUT_DIR})->make_path unless -d $env->{WEBPACK_OUT_DIR};
  return DEBUG ? warn "[Webpack] Cannot write to $env->{WEBPACK_OUT_DIR}\n" : 1 unless -w $env->{WEBPACK_OUT_DIR};

  my $config_file = $self->{files}{'webpack.config.js'}[1];
  my @cmd         = $ENV{MOJO_WEBPACK_BINARY} || path($config_file->dirname, qw(node_modules .bin webpack))->to_string;
  my @extra       = split /\s+/, +($ENV{MOJO_WEBPACK_RUN} || '');
  push @cmd, '--config' => $config_file->to_string;
  push @cmd, '--progress', '--profile', '--verbose' if $ENV{MOJO_WEBPACK_VERBOSE};
  push @cmd, @extra unless @extra == 1 and $extra[0] eq '1';
  warn "[Webpack] @cmd\n" if DEBUG;

  my $run_with = (grep {/--watch/} @cmd) ? 'exec' : 'system';
  my $CWD = Mojolicious::Plugin::Webpack::CWD->new($config_file->dirname);
  local $!;    # Make sure only system/exec sets $!
  { local %ENV = %$env; $run_with eq 'exec' ? exec @cmd : system @cmd }
  die "[Webpack] $run_with @cmd: $!" if $!;
}

sub _share_dir {
  state $share = path(path(__FILE__)->dirname, 'Webpack');
}

sub _webpack_environment {
  my $self = shift;
  my %env  = %ENV;

  $env{WEBPACK_ASSETS_DIR} = $self->assets_dir;
  $env{WEBPACK_OUT_DIR}    = $self->out_dir;
  $env{WEBPACK_SHARE_DIR}   //= $self->_share_dir;
  $env{WEBPACK_SOURCE_MAPS} //= $self->{source_maps} // 1;
  $env{uc "WEBPACK_RULE_FOR_$_"} = 1 for @{$self->{process}};

  return \%env;
}

package    # hide from pause
  Mojolicious::Plugin::Webpack::CWD;

sub new { _chdir(bless([$_[2] || Mojo::File->new->to_string], $_[0]), $_[1]) }
sub _chdir { chdir $_[1] or die "[Webpack] chdir $_[1]: $!"; $_[0] }
sub DESTROY { $_[0]->_chdir($_[0]->[0]) }

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Webpack - Mojolicious ♥ Webpack

=head1 SYNOPSIS

Check out
L<https://github.com/jhthorsen/mojolicious-plugin-webpack/tree/master/example>
for a working example.

=head2 Define assets

One or more assets need to be defined. The minimum is to create one
L<entry point|https://webpack.js.org/concepts/#entry> and add it to
the C<webpack.custom.js> file.

  # Entrypoint: ./assets/app.js
  // This will result in one css and one js asset.
  import "../css/css-example.css";
  console.log("I'm loaded!");

  # Config file: ./assets/webpack.custom.js
  module.exports = function(config) {
    config.entry = {
      "cool_beans": "./assets/app.js",
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

  %= asset "myapp.css"
  %= asset "myapp.js"

=head2 Start application

You can start the application using C<daemon>, C<hypnotoad> or any Mojolicious
server you want, but if you want rapid development you should use
C<crushinator>, which is an alternative to C<morbo>:

  $ crushinator -h
  $ crushinator ./myapp.pl

However if you want to use another daemon and make C<webpack> run, you need to
set the C<MOJO_WEBPACK_RUN> environment variable to "1". Example:

  MOJO_WEBPACK_RUN=1 ./myapp.pl daemon

=head2 Testing

If you want to make sure you have built all the assets, you can make a test
file like "build-assets.t":

  use Test::More;
  use Test::Mojo;

  # Run with TEST_BUILD_ASSETS=1 prove -vl t/build-assets.t
  plan skip_all => "TEST_BUILD_ASSETS=1" unless $ENV{TEST_BUILD_ASSETS};

  # Load the app and make a test object
  $ENV{MOJO_MODE}        = 'production';
  $ENV{MOJO_WEBPACK_RUN} = 1;
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
work with L<https://webpack.js.org/>.

Note that L<Mojolicious::Plugin::Webpack> is currently EXPERIMENTAL, and
changes might come without a warning.

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

  warn $app->asset->out_dir;
  $c->asset("cool_beans.js", @args);
  %= asset "cool_beans.css", media => "print"
  %= asset(url_for => "cool_beans.css")
  %= asset->url_for($c, "cool_beans.css")

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
files are read from.

=head2 dependencies

  $hash_ref = $self->dependencies;

Holds a mapping between what this plugin can L</process> and which node modules
it depends on.

=head2 out_dir

  $path = $self->out_dir;

Holds a L<Mojo::File> object pointing to the public directoy where processed
assets are written to.

=head2 route

  $route = $self->route;

Holds a L<Mojolicious::Routes::Route> object that generates the URLs to a
processed asset.

=head1 METHODS

=head2 register

  $self->register($app, \%config);

The C<%config> passed when loading this plugin can have:

=head3 auto_cleanup

Set this to "0" if you want to keep the old files in L</out_dir>.

Default: enabled.

=head3 dependencies

Holds a hash ref with mapping between what to L</process> and which node module
that need to be installed to do so.

=head3 helper

Name of the helper that will be added to your application.

Default: C<"asset">.

=head3 process

A list of assets to process. Currently "css", "js", "sass" and "vue" is
supported.

Default: C<["js"]>.

=head3 source_maps

Set this to "0" if you do not want source maps generated.

Default: enabled.

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

L<Mojolicious::Plugin::AssetPack>.

=cut
