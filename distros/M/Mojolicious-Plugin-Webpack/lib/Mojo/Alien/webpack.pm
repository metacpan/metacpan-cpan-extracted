package Mojo::Alien::webpack;
use Mojo::Base -base;

use Carp qw(croak);
use File::chdir;
use Mojo::Alien::npm;
use Mojo::File qw(path tempfile);
use Mojo::Loader;
use POSIX ':sys_wait_h';
use Time::HiRes qw(sleep);

use constant DEBUG => ($ENV{MOJO_ROLLUP_DEBUG} || $ENV{MOJO_WEBPACK_DEBUG}) && 1;

# TODO
our $VERSION = $Mojolicious::Plugin::Webpack::VERSION || '0.01';

has assets_dir => sub { shift->config->dirname->child('assets') };

has binary => sub {
  my $self = shift;
  return $ENV{MOJO_WEBPACK_BINARY} if $ENV{MOJO_WEBPACK_BINARY};
  my $bin = $self->config->to_abs->dirname->child(qw(node_modules .bin webpack));
  $self->_d('%s %s', -e $bin ? 'Found' : 'Not installed', $bin) if DEBUG;
  return -e $bin ? $bin->to_string : 'webpack';
};

has config => sub { path->to_abs->child('webpack.config.js') };

has dependencies => sub {
  return {
    core   => [qw(webpack webpack-cli)],
    css    => [qw(css-loader mini-css-extract-plugin css-minimizer-webpack-plugin)],
    eslint => [qw(eslint eslint-webpack-plugin)],
    js     => [qw(@babel/core @babel/preset-env @babel/plugin-transform-runtime babel-loader terser-webpack-plugin)],
    sass   => [qw(css-loader mini-css-extract-plugin css-minimizer-webpack-plugin sass sass-loader)],
    vue    => [qw(vue vue-loader vue-template-compiler)],
  };
};

has include => sub { +[] };
has mode    => sub { $ENV{NODE_ENV} || 'development' };

has npm => sub {
  my $self = shift;
  Mojo::Alien::npm->new(config => $self->config->dirname->child('package.json'), mode => $self->mode);
};

has out_dir => sub { shift->config->dirname->child('dist') };

sub asset_map {
  my $self = shift;

  my %assets;
  for my $path ($self->out_dir->list_tree->each) {
    my $rel_path = File::Spec->abs2rel($path, $self->out_dir);
    my $name     = $rel_path;
    $name =~ s!(.*)\W(\w+)\.(\w+)$!$1.$3!;    # (prefix, checksum, ext)
    my $mode = ($2 // '') eq 'development' ? 'development' : 'production';
    $assets{$rel_path} = {ext => lc $3, name => $name, mode => $mode, mtime => $path->stat->mtime, path => $path};
  }

  return \%assets;
}

sub build {
  my $self = shift;
  croak "Can't call build() after watch()" if $self->pid;

  ($!, $?) = (0, 0);
  $self->_run($self->_cmd_build);
  croak "$self->{basename} $! (exit=$?)"   if $!;
  croak "$self->{basename} failed exit=$?" if !$! and $?;

  return $self;
}

sub exec {
  my $self = shift;
  my @cmd  = ($self->_cmd_build, '--watch');
  my $home = $self->config->dirname->to_string;

  chdir $home or die "Can't chdir to $home: $!";
  $ENV{NODE_ENV}           = $self->mode;
  $ENV{WEBPACK_ASSETS_DIR} = $self->assets_dir->to_string;
  $ENV{WEBPACK_OUT_DIR}    = $self->out_dir->to_string;
  $self->_d('(%s) cd %s && %s', $$, $home, join ' ', @_) if DEBUG;
  { CORE::exec(@cmd) }
  die "Can't exec @cmd: $!";
}

sub init {
  my $self = shift;

  $self->npm->init;
  $self->_render_file($self->_config_template_name, $self->config);

  my $dependencies = $self->npm->dependencies;
  my @includes     = @{$self->include};
  unshift @includes, 'core' unless grep { $_ eq 'core' } @includes;
  my ($conf_d, @includes_names, %seen) = ($self->_config_include_dir);
  for my $include (@includes) {
    for my $package (@{$self->dependencies->{$include} || []}) {
      next if $seen{$package}++;
      $self->npm->install($package) unless $dependencies->{$package}{version};
    }

    my $exists = $self->_resources->{"include/$include.js"} ? 'exists' : 'does not exist';
    my $file   = $conf_d->child("$include.js");
    $self->_d('Template %s.js %s', $include, $exists) if DEBUG;
    $self->_render_file("include/$include.js", $file) if $exists eq 'exists';
    push @includes_names, $include if -e $file;
  }

  my $include_src = ("module.exports = function(config, opts) {\n");
  $include_src .= "  require('./$_')(config, opts);\n" for @includes_names;
  $include_src .= "};\n";
  $self->_render_file('include.js', $self->_config_include_dir->child('include.js'), $include_src);
  return $self;
}

sub pid {
  my $self = shift;
  return 0 unless $self->{pid};
  my $r = waitpid $self->{pid}, WNOHANG;    # -1 == no such process, >0 if terminated
  return $r == -1 && delete $self->{pid} ? 0 : $r ? 0 : $self->{pid};
}

sub stop {
  my ($self, $tries) = @_;

  $tries ||= 100;
  while (--$tries) {
    return $self unless my $pid = $self->pid;
    local $!;
    kill 15, $pid;
    waitpid $pid, 0;
    sleep $ENV{MOJO_WEBPACK_STOP_INTERVAL} || 0.1;
  }

  $self->{basename} ||= path($self->binary)->basename;
  croak "Couldn't stop $self->{basename} with pid @{[$self->pid]}";
}

sub watch {
  my $self = shift;
  return $self if $self->pid;

  my $home = $self->config->dirname->to_string;
  croak "Can't chdir $home: No such file or directory" unless -d $home;

  my @cmd = ($self->_cmd_build, '--watch');
  croak "Can't fork: $!" unless defined(my $pid = fork);
  return $self if $self->{pid} = $pid;    # Parent
  return $self->exec;                     # Child
}

sub _cmd_build {
  my $self = shift;
  $self->init;

  my @cmd = ($self->binary);
  croak "Can't run $cmd[0]" unless -x $cmd[0];

  $self->{basename} ||= path($cmd[0])->basename;
  push @cmd, '--config' => $self->config->to_string;
  push @cmd, qw(--progress --profile --verbose) if $ENV{MOJO_WEBPACK_VERBOSE};
  return @cmd;
}

sub _config_include_dir   { shift->assets_dir->child('webpack.config.d') }
sub _config_template_name {'webpack.config.js'}
sub _d                    { my ($class, $format) = (shift, shift); warn sprintf "[Webpack] $format\n", @_ }

sub _render_file {
  my ($self, $name, $file, $content) = @_;

  if (-e $file) {
    my $version = $file->slurp =~ m!// Autogenerated.*(\d+\.\d+)! ? $1 : -1;
    $self->_d('File %s has version %s', $file, $version) if DEBUG;
    return $self                                         if $version == -1;
    return $self if $version == $VERSION and !$content and !$ENV{MOJO_WEBPACK_REGENERATE};
  }

  $self->_d('Render %s to %s', $name, $file) if DEBUG;
  $file->dirname->make_path unless -d $file->dirname;
  $content //= $self->_resources->{$name};
  $file->spurt(sprintf "// Autogenerated by %s %s\n%s", ref($self), $VERSION, $content);
  return $self;
}

sub _resources {
  state $resources = Mojo::Loader::data_section(ref($_[0]) || $_[0]);
}

sub _run {
  my ($self, @cmd) = @_;
  local $CWD                     = $self->config->dirname->to_string;
  local $ENV{NODE_ENV}           = $self->mode;
  local $ENV{WEBPACK_ASSETS_DIR} = $self->assets_dir->to_string;
  local $ENV{WEBPACK_OUT_DIR}    = $self->out_dir->to_string;
  $self->_d('cd %s && %s', $CWD, join ' ', @cmd) if DEBUG;
  open my $WEBPACK, '-|', @cmd or die "Can't run @cmd: $!";
  return $WEBPACK if defined wantarray;
  DEBUG && print while <$WEBPACK>;
}

sub DESTROY { shift->stop }

1;

=encoding utf8

=head1 NAME

Mojo::Alien::webpack - Runs the external nodejs program webpack

=head1 SYNOPSIS

  use Mojo::Alien::webpack;
  my $webpack = Mojo::Alien::webpack->new;

  # Run once
  $webpack->build;

  # Build when webpack see files change
  $webpack->watch;

=head1 DESCRIPTION

L<Mojo::Alien::webpack> is a class for runnig the external nodejs program
L<webpack|https://webpack.js.org/>.

=head1 ATTRIBUTES

=head2 assets_dir

  $path = $webpack->assets_dir;
  $webpack = $webpack->assets_dir($webpack->config->dirname->child('assets'))

Location to source assetsa and partial webpack.config.js files.

=head2 binary

  $array_ref = $webpack->binary;
  $webpack = $webpack->binary('webpack');

The path to the webpack executable. Defaults to C<MOJO_WEBPACK_BINARY>
environment variable, or "webpack" inside "./node_modules". Fallback to just
"webpack".

=head2 config

  $path = $webpack->config;
  $webpack = $webpack->config(path->to_abs->child('webpack.config.js'));

Holds an I</absolute> path to
L<webpack.config.js|https://webpack.js.org/concepts/configuration/>.

=head2 dependencies

  $hash_ref = $webpack->dependencies;

A hash where the keys can match the items in L</include> and the values are
lists of packages to install. Keys that does I</not> match items in L</include>
will be ignored. This attribute will be used by L</init>.

These dependencies are predefined:

  core   | webpack webpack-cli
  css    | css-loader mini-css-extract-plugin css-minimizer-webpack-plugin
  eslint | eslint-webpack-plugin
  js     | @babel/core @babel/preset-env @babel/plugin-transform-runtime babel-loader terser-webpack-plugin
  sass   | css-loader mini-css-extract-plugin css-minimizer-webpack-plugin sass sass-loader
  vue    | vue vue-loader vue-template-compiler

=head2 include

  $array_ref = $webpack->include;
  $webpack = $webpack->include([qw(js css)]);

L</include> can be used to install dependencies and load other webpack config
files. The config files included must exist in the "webpack.config.d" sub
directory inside L</assets_dir>. Here is an example of which files that will be
included if they exists:

  # Including "js" and "css" will look for the files below
  $webpack->include[qw(js css)]);

  # - assets/webpack.config.d/package-babel-loader.js
  # - assets/webpack.config.d/package-terser-webpack-plugin.js
  # - assets/webpack.config.d/package-css-loader.js
  # - assets/webpack.config.d/package-css-minimizer-webpack-plugin.js
  # - assets/webpack.config.d/js.js
  # - assets/webpack.config.d/css.js

The L</include> feature is currently EXPERIMENTAL.

=head2 mode

  $str = $webpack->mode;
  $webpack = $webpack->mode('development');

Should be either "development" or "production". Will be used as "NODE_ENV"
environment variable when calling L</build> or L</watch>.

=head2 npm

  $npm = $webpack->npm;

A L<Mojo::Alien::npm> object used by L</init>.

=head2 out_dir

  $path = $webpack->out_dir;
  $webpack = $webpack->out_dir(path('dist')->to_abs);

Location to write output assets to.

=head1 METHODS

=head2 asset_map

  $hash_ref = $webpack->asset_map;

Parses the filenames in L</out_dir> and returns a hash ref with information
about the generated assets. Example return value:

  {
    'relative/output.development.js' => {            # Key is relative path to out_dir()
      ext   => 'css',                                # File extension
      mode  => 'development',                        # or "production"
      mtime => 1616976114,                           # File modification epoch timestamp
      name  => 'relative/output.js',                 # Name of asset, without checksum or mode
      path  => '/path/to/entry-name.development.js', # Absolute path to asset
    },
  }

Note that this method is currently EXPERIMENTAL.

=head2 build

  $webpack->build;

Will build the assets or croaks on errors. Automatically calls L</init>.

=head2 exec

  $webpack->exec;

This method will replace the current process, instead of starting webpack
inside a fork. This method is called by L</watch> inside a fork.

=head2 init

  $webpack = $webpack->init;

Will install "webpack" and "webpack-cli" and create a default L</config>. Does
nothing if this is already done.

This method is automatically called by L</build> and L</watch>.

=head2 pid

  $int = $webpack->pid;

Returns the PID of the webpack process started by L</start>.

=head2 stop

  $webpack->stop;

Will stop the process started by L</watch>. Does nothing if L</watch> has not
been called.

=head2 watch

  $webpack->watch;

Forks a new process that runs "webpack watch". This means that any changes will
generate new assets. This is much more efficient than calling L</build> over
and over again. Automatically calls L</init>.

=head1 SEE ALSO

L<Mojolicious::Plugin::Webpack> and L<Mojo::Alien::rollup>.

=cut

__DATA__
@@ include/css.js
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const OptimizeCSSAssetsPlugin = require('css-minimizer-webpack-plugin');

module.exports = function(config, {isDev}) {
  if (!isDev) config.optimization.minimizer.push(new OptimizeCSSAssetsPlugin({}));
  config.plugins.push(new MiniCssExtractPlugin({filename: isDev ? '[name].development.css' : '[name].[contenthash].css'}));
  config.module.rules.push({
    test: /\.css$/,
    use: [MiniCssExtractPlugin.loader, {loader: 'css-loader', options: {sourceMap: true, url: false}}],
  });
};
@@ include/eslint.js
const ESLintPlugin = require('eslint-webpack-plugin');

module.exports = function(config) {
  config.plugins.push(new ESLintPlugin({
    exclude: ['node_modules/**', '**/*.css', '**/*.sass'],
    fix: process.env.ESLINT_FIX ? true : false,
  }));
};
@@ include/js.js
const TerserPlugin = require('terser-webpack-plugin');

module.exports = function(config, {isDev}) {
  if (!isDev) config.optimization.minimizer.push(new TerserPlugin({parallel: true}));

  config.module.rules.push({
    test: /\.js$/,
    exclude: /node_modules/,
    use: {
      loader: 'babel-loader',
      options: {
        plugins: ['@babel/plugin-transform-runtime'],
        presets: ['@babel/preset-env'],
      },
    },
  });
};
@@ include/sass.js
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const OptimizeCSSAssetsPlugin = require('css-minimizer-webpack-plugin');

module.exports = function(config, {isDev}) {
  if (!isDev) config.optimization.minimizer.push(new OptimizeCSSAssetsPlugin({}));
  config.plugins.push(new MiniCssExtractPlugin({filename: isDev ? '[name].development.css' : '[name].[contenthash].css'}));
  config.module.rules.push({
    test: /\.s(a|c)ss$/,
    use: [
      MiniCssExtractPlugin.loader,
      {loader: 'css-loader', options: {sourceMap: true, url: false}},
      {loader: 'sass-loader', options: {sourceMap: true}},
    ],
  });
};
@@ include/vue.js
const {VueLoaderPlugin} = require('vue-loader');

module.exports = function(config) {
  config.plugins.push(new VueLoaderPlugin());
  config.module.rules.push({test: /\.vue$/, use: 'vue-loader'});
};
@@ webpack.config.js
const fs = require('fs');
const pkg = require('./package.json');
const path = require('path');

const assetsDir = process.env.WEBPACK_ASSETS_DIR || path.resolve(__dirname, 'assets');
const isDev = process.env.NODE_ENV !== 'production';

const config = {
  entry: {},
  mode: isDev ? 'development' : 'production',
  module: {rules: []},
  optimization: {minimizer: []},
  output: {},
  plugins: [],
};

config.output.filename = isDev ? '[name].development.js' : '[name].[chunkhash].js';
config.output.path = process.env.WEBPACK_OUT_DIR || path.resolve(__dirname, 'dist');
config.output.publicPath = '';

const entry = path.resolve(assetsDir, 'index.js');
if (fs.existsSync(entry)) config.entry[pkg.name.replace(/\W+/g, '-')] = entry;

const includeFile = path.resolve(assetsDir, 'webpack.config.d', 'include.js');
if (fs.existsSync(includeFile)) require(includeFile)(config, {isDev});

// Legacy
const custom = path.resolve(assetsDir, 'webpack.custom.js');
if (fs.existsSync(custom)) require(custom)(config);

module.exports = config;
