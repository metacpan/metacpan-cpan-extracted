package Mojolicious::Plugin::Webpack::Builder;
use Mojo::Base 'Mojolicious::Plugin';

use Carp 'confess';
use Mojo::File 'path';
use Mojo::JSON;
use Mojo::Path;
use Mojo::Util;
use Mojolicious::Plugin::Webpack;

use constant DEBUG => $ENV{MOJO_WEBPACK_DEBUG} ? 1 : 0;

has dependencies => sub {
  return {
    core => [qw(webpack webpack-cli webpack-md5-hash html-webpack-plugin)],
    css  => [qw(css-loader mini-css-extract-plugin optimize-css-assets-webpack-plugin)],
    js   => [qw(@babel/core @babel/preset-env babel-loader terser-webpack-plugin)],
    sass => [qw(node-sass sass-loader)],
    vue  => [qw(vue vue-loader vue-template-compiler)],
  };
};

sub assets_dir   { shift->{webpack}->assets_dir }
sub node_env     { shift->{webpack}->node_env }
sub out_dir      { shift->{webpack}->out_dir }
sub process      { shift->{process} }
sub source_maps  { shift->{source_maps} }
sub _custom_file { shift->{custom_file} }
sub _share_dir   { state $share = path(__FILE__)->dirname }

sub register {
  my ($self, $app, $config) = @_;

  $self->{webpack}     = $app->renderer->get_helper($config->{helper} || 'asset')->($app->build_controller);
  $self->{custom_file} = $self->_build_custom_file($app);
  $self->{process}     = $config->{process} || ['js'];
  $self->{$_} = $config->{$_} // 1 for qw(source_maps);
  $self->dependencies->{$_} = $config->{dependencies}{$_} for keys %{$config->{dependencies} || {}};

  # Hack to test internal methods. Open for suggestions on how to make this prettier.
  return $t::Helper::builder = $self if $ENV{MOJO_WEBPACK_TEST_INTERNAL};

  $self->_migrate_from_assetpack;
  $self->_render_to_file($app, 'package.json');
  $self->_render_to_file($app, 'webpack.config.js');
  $self->_render_to_file($app, 'webpack.custom.js', $self->_custom_file);
  $self->_render_to_file($app, 'my_app.js', $self->assets_dir->child('my_app.js'))
    if $self->{files}{'webpack.custom.js'}[0] eq 'generated';
  $self->_install_node_deps;
  $self->_webpack_run($app);
  $self->_install_shim($app) if $config->{shim};
}

sub _build_custom_file {
  return shift->assets_dir->child(sprintf 'webpack.%s.js', $ENV{WEBPACK_CUSTOM_NAME} || 'custom');
}

sub _install_node_deps {
  my $self         = shift;
  my $package_file = $self->{files}{'package.json'}[1];
  my $package_json = Mojo::JSON::decode_json($package_file->slurp);
  my $n            = 0;

  my $CWD = Mojolicious::Plugin::Webpack::CWD->new($package_file->dirname);
  system qw(npm install) if %{$package_json->{dependencies}} and !-d 'node_modules';

  for my $preset ('core', @{$self->process}) {
    for my $module (@{$self->dependencies->{$preset} || []}) {
      next if $package_json->{dependencies}{$module};
      warn "[Webpack] npm install $module\n" if DEBUG;
      system npm => install => $module;
      $n++;
    }
  }

  return $n;
}

sub _install_shim {
  my ($self, $app) = @_;
  my $shim_class = sprintf '%s::Plugin::Webpack', ref $app;
  my $shim_file  = path(Mojo::Util::class_to_path($shim_class));
  my $record     = 1;
  my $source     = '';

  return $shim_file if Mojolicious::Plugin::Webpack->VERSION eq ($shim_class->VERSION // '');
  return $shim_file if !-w $shim_file->dirname;

  my $SOURCE = path($INC{Mojo::Util::class_to_path('Mojolicious::Plugin::Webpack')})->open('<');
  while (<$SOURCE>) {
    s/package Mojolicious::Plugin::Webpack;/package $shim_class;/;
    s/^Mojolicious::Plugin::Webpack\s-/$shim_class -/;

    if (/\{MOJO_WEBPACK_BUILD\}/) {
      next;
    }
    elsif (/^=head1 SYNOPSIS/) {
      $record = 0;
      $source .= "=head1 SYNOPSIS\n\nSee L<Mojolicious::Plugin::Webpack>.\n\n";
    }
    elsif (/^=head1 MIGRATING FROM ASSETPACK/) {
      $record = 0;
    }
    elsif (!$record and /^=head1/) {
      $record = 1;
    }

    $source .= $_ if $record;
  }

  return $shim_file->spurt($source);
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

  state $VERSION = $Mojolicious::Plugin::Webpack::VERSION;

  return $self->{files}{$name} = [custom => $out_file] if !$is_generated and -r $out_file;
  return $self->{files}{$name} = [current => $out_file] if $is_generated =~ /\b$VERSION\b/;

  my $template = $self->_share_dir->child($name)->slurp;
  $template =~ s!__AUTOGENERATED__!Autogenerated by Mojolicious-Plugin-Webpack $VERSION!g;
  $template =~ s!__NAME__!{$app->moniker}!ge;
  $template =~ s!__VERSION__!{$app->VERSION || '0.0.1'}!ge;
  $out_file->spurt($template);
  return $self->{files}{$name} = [generated => $out_file];
}

sub _webpack_run {
  my ($self, $app) = @_;

  my $env = $self->_webpack_environment;
  map { warn "[Webpack] $_=$env->{$_}\n" } grep {/^(NODE_|WEBPACK_)/} sort keys %$env if DEBUG;

  my $config_file = $self->{files}{'webpack.config.js'}[1];
  my @cmd         = $ENV{MOJO_WEBPACK_BINARY} || path($config_file->dirname, qw(node_modules .bin webpack))->to_string;
  my @extra       = split /\s+/, +($ENV{MOJO_WEBPACK_BUILD} || '');
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

sub _webpack_environment {
  my $self = shift;
  my %env  = %ENV;

  $env{NODE_ENV}           = $self->{webpack}->node_env;
  $env{WEBPACK_ASSETS_DIR} = $self->assets_dir;
  $env{WEBPACK_OUT_DIR}    = $self->out_dir;
  $env{WEBPACK_SHARE_DIR}   //= $self->_share_dir;
  $env{WEBPACK_SOURCE_MAPS} //= $self->source_maps // 1;
  $env{uc "WEBPACK_RULE_FOR_$_"} = 1 for @{$self->process};

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

Mojolicious::Plugin::Webpack::Builder - Assets builder

=head1 SYNOPSIS

See L<Mojolicious::Plugin::Webpack/SYNOPSIS>.

=head1 DESCRIPTION

L<Mojolicious::Plugin::Webpack::Builder> is a L<Mojolicious::Plugin> that will
run L<webpack|https://webpack.js.org/>. This plugin is automatically registered
by L<Mojolicious::Plugin::Webpack>, so you do not have to register it yourself.

Note that it is I<not> a typo in examples below where C<Webpack> is the first
argument to L<Mojolicious/plugin>.

=head1 PLUGIN SHIM

L<Mojolicious::Plugin::Webpack::Builder> will install a shim of
L<Mojolicious::Plugin::Webpack> if there is a writable "Plugin" directory in
your distribution. Example:

  # Generate a full Mojolicious application
  $ mojo generate app MyApp
  $ cd my_app

  # Create a Plugin directory
  $ mkdir -p lib/MyApp/Plugin

  # Edit your application and enable it to load the shim
  $ $EDITOR lib/MyApp.pm

When editing C<MyApp.pm>, add load the L<Mojolicious::Plugin::Webpack> plugin
with the "shim" key set:

  sub startup {
    my $self = shift;

    # Make sure you can load plugins from your application namespaces
    unshift @{$self->plugins->namespaces}, "MyApp::Plugin";

    # Load the plugin with "shim" set
    $self->plugin(Webpack => {process => ["js"], shim => 1});
  }

Save the file and start your application with C<mojo webpack>:

  $ mojo webpack ./script/my_app

This will then generate C<lib/MyApp/Plugin/Webpack.pm> which will be enough to
run in production, which again means that your application does not depend on
L<Mojolicious::Plugin::Webpack> at all.

=head1 ATTRIBUTES

=head2 dependencies

  $hash_ref = $self->dependencies;

Holds a mapping between what this plugin can L</process> and which node modules
it depends on. Example:

  $app->plugin("Webpack" => {
    dependencies => {
      css  => [qw(css-loader mini-css-extract-plugin optimize-css-assets-webpack-plugin)],
      js   => [qw(@babel/core @babel/preset-env babel-loader terser-webpack-plugin)],
      sass => [qw(node-sass sass-loader)],
    }
  });

These dependencies will automatically be installed when the key is present in
L</process>.

=head2 process

  $array_ref = $self->process;

A list of assets to process. Currently "css", "js", "sass" and "vue" is
supported. Example:

  $app->plugin("Webpack" => {process => [qw(js sass vue)]});

=head2 source_maps

  $bool = $self->source_maps;

Set this to "0" if you do not want source maps generated. Example:

  $app->plugin("Webpack" => {source_maps => 0});

Default: true (enabled).

=head1 METHODS

=head2 assets_dir

  $path = $self->assets_dir;

Proxy method for L<Mojolicious::Plugin::Webpack/assets_dir>.

=head2 node_env

  $path = $self->node_env;

Proxy method for L<Mojolicious::Plugin::Webpack/node_env>.

=head2 out_dir

  $path = $self->out_dir;

Proxy method for L<Mojolicious::Plugin::Webpack/out_dir>.

=head2 register

  $self->register($app, \%config);
  $app->plugin("Webpack::Builder", \%config);

Used to register this plugin into your L<Mojolicious> app. Normally called
automatically by L<Mojolicious::Plugin::Webpack/register>, where C<%config> is
passed through without any modifications.

=head1 SEE ALSO

L<Mojolicious::Plugin::Webpack>.

=cut
