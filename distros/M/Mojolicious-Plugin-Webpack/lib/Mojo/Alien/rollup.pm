package Mojo::Alien::rollup;
use Mojo::Base 'Mojo::Alien::webpack';

use Carp qw(croak);
use Mojo::File qw(path tempfile);
use File::chdir;

use constant DEBUG => $ENV{MOJO_ROLLUP_DEBUG} && 1;

has binary => sub {
  my $self = shift;
  return $ENV{MOJO_ROLLUP_BINARY} if $ENV{MOJO_ROLLUP_BINARY};
  my $bin = $self->config->to_abs->dirname->child(qw(node_modules .bin rollup));
  $self->_d('%s %s', -e $bin ? 'Found' : 'Not installed', $bin) if DEBUG;
  return -e $bin ? $bin->to_string : 'rollup';
};

has config => sub { path->to_abs->child('rollup.config.js') };

has dependencies => sub {
  return {
    core   => [qw(rollup @rollup/plugin-commonjs @rollup/plugin-node-resolve)],
    css    => [qw(cssnano postcss-preset-env rollup-plugin-postcss)],
    eslint => [qw(@rollup/plugin-eslint)],
    js => [qw(@babel/core @babel/preset-env @babel/plugin-transform-runtime @rollup/plugin-babel rollup-plugin-terser)],
    sass   => [qw(cssnano @csstools/postcss-sass postcss-preset-env rollup-plugin-postcss sass)],
    svelte => [qw(rollup-plugin-svelte)],
  };
};

sub exec {
  my $self = shift;
  my @cmd  = ($self->_cmd_build, '--watch');
  my $home = $self->config->dirname->to_string;

  chdir $home or die "Can't chdir to $home: $!";
  $ENV{NODE_ENV}          = $self->mode;
  $ENV{ROLLUP_ASSETS_DIR} = $self->assets_dir->to_string;
  $ENV{ROLLUP_OUT_DIR}    = $self->out_dir->to_string;
  $self->_d('(%s) cd %s && %s', $$, $home, join ' ', @_) if DEBUG;
  { exec @cmd }
  die "Can't exec @cmd: $!";
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
  return @cmd;
}

sub _config_include_dir   { shift->assets_dir->child('rollup.config.d') }
sub _config_template_name {'rollup.config.js'}
sub _d                    { my ($class, $format) = (shift, shift); warn sprintf "[Rollup] $format\n", @_ }

sub _run {
  my ($self, @cmd) = @_;
  local $CWD                    = $self->config->dirname->to_string;
  local $ENV{NODE_ENV}          = $self->mode;
  local $ENV{ROLLUP_ASSETS_DIR} = $self->assets_dir->to_string;
  local $ENV{ROLLUP_OUT_DIR}    = $self->out_dir->to_string;
  $self->_d('cd %s && %s', $CWD, join ' ', @cmd) if DEBUG;
  open my $ROLLUP, '-|', @cmd or die "Can't run @cmd: $!";
  return $ROLLUP if defined wantarray;
  DEBUG && print while <$ROLLUP>;
}

1;

=encoding utf8

=head1 NAME

Mojo::Alien::rollup - Runs the external nodejs program rollup

=head1 SYNOPSIS

  use Mojo::Alien::rollup;
  my $rollup = Mojo::Alien::rollup->new;

  # Run once
  $rollup->build;

  # Build when rollup see files change
  $rollup->watch

=head1 DESCRIPTION

L<Mojo::Alien::rollup> is a class for runnig the external nodejs program
L<rollup|https://rollupjs.org/>.

=head1 ATTRIBUTES

=head2 assets_dir

See L<Mojo::Alien::webpack/assets_dir>.

=head2 binary

  $array_ref = $rollup->binary;
  $rollup = $rollup->binary('rollup');

The path to the rollup executable. Defaults to C<MOJO_ROLLUP_BINARY>
environment variable, or "rollup" inside "./node_modules". Fallback to just
"rollup".

=head2 config

  $path = $rollup->config;
  $rollup = $rollup->config(path->to_abs->child('rollup.config.js'));

Holds an I</absolute> path to
L<rollup.config.js|https://rollup.js.org/concepts/configuration/>.

=head2 dependencies

  $hash_ref = $rollup->dependencies;

A hash where the keys can match the items in L</include> and the values are
lists of packages to install. Keys that does I</not> match items in L</include>
will be ignored. This attribute will be used by L</init>.

These dependencies are predefined:

  core   | rollup @rollup/plugin-commonjs @rollup/plugin-node-resolve
  css    | cssnano postcss-preset-env rollup-plugin-postcss
  eslint | @rollup-plugin-eslint
  js     | @babel/core @babel/preset-env @rollup/plugin-babel rollup-plugin-terser
  sass   | cssnano @csstools/postcss-sass postcss-preset-env rollup-plugin-postcss sass
  svelte | rollup-plugin-svelte

=head2 include

See L<Mojo::Alien::webpack/include>.

=head2 mode

See L<Mojo::Alien::webpack/mode>.

=head2 npm

See L<Mojo::Alien::webpack/npm>.

=head2 out_dir

See L<Mojo::Alien::webpack/out_dir>.

=head1 METHODS

=head2 asset_map

  $hash_ref = $rollup->asset_map;

Parses the filenames in L</out_dir> and returns a hash ref with information
about the generated assets. Example return value:

  {
    'entry-name.js' => '/path/to/entry-name.development.js',
    'cool-beans.png' => /path/to/f47352684211060f3e34.png',
  }

Note that this method is currently EXPERIMENTAL.

=head2 build

See L<Mojo::Alien::webpack/build>.

=head2 exec

See L<Mojo::Alien::webpack/exec>.

=head2 init

See L<Mojo::Alien::webpack/init>.

=head2 pid

See L<Mojo::Alien::webpack/pid>.

=head2 stop

See L<Mojo::Alien::webpack/stop>.

=head2 watch

See L<Mojo::Alien::webpack/watch>.

=head1 SEE ALSO

L<Mojolicious::Plugin::Webpack> and L<Mojo::Alien::webpack>.

=cut

__DATA__
@@ include/core.js
const commonjs = require('@rollup/plugin-commonjs');
const {nodeResolve} = require('@rollup/plugin-node-resolve');

module.exports = function(config) {
  config.plugins.push(nodeResolve());
  config.plugins.push(commonjs());
};
@@ include/css.js
const postcss = require('rollup-plugin-postcss');

module.exports = function(config) {
  config.plugins.push(postcss({
    extract: true,
    plugins: [
      require('postcss-preset-env')(),
      require('cssnano')(),
    ],
  }));
};
@@ include/eslint.js
const eslint = require('@rollup/plugin-eslint');

module.exports = function(config, {isDev}) {
  if (!isDev) return;
  config.plugins.push(eslint({
    exclude: ['node_modules/**', '**/*.css', '**/*.sass'],
    fix: process.env.ESLINT_FIX ? true : false,
  }));
}
@@ include/js.js
const {babel} = require('@rollup/plugin-babel');
const {terser} = require('rollup-plugin-terser');

module.exports = function(config, {isDev}) {
  config.plugins.push(babel({
    babelHelpers: 'runtime',
    extensions: ['.html', '.js', '.mjs'],
    plugins: ['@babel/plugin-transform-runtime'],
    presets: [['@babel/preset-env', {corejs: 3, debug: false, useBuiltIns: 'entry'}]],
  }));

  if (!isDev) config.plugins.push(terser());
}
@@ include/sass.js
const postcss = require('rollup-plugin-postcss');

module.exports = function(config) {
  config.plugins.push(postcss({extract: true, plugins: [
    require('@csstools/postcss-sass')(),
    require('postcss-preset-env')(),
    require('cssnano')(),
  ]}));
};
@@ include/svelte.js
const svelte = require('rollup-plugin-svelte');

module.exports = function(config) {
  config.plugins.push(svelte({}));
};
@@ rollup.config.js
const fs = require('fs');
const pkg = require('./package.json');
const path = require('path');

const assetsDir = process.env.ROLLUP_ASSETS_DIR || path.resolve(__dirname, 'assets');
const isDev = process.env.NODE_ENV !== 'production';
const outDir = process.env.ROLLUP_OUT_DIR || path.resolve(__dirname, 'dist');
const ts = parseInt((new Date().getTime() / 1000), 10).toString(16);

function outPath(name) {
  return path.resolve(outDir, name.replace(/\[hash\]/, isDev ? 'development' : ts));
}

const config = {
  input: path.resolve(assetsDir, 'index.js'),
  output: {format: 'iife', sourcemap: true},
  plugins: [],
  watch: {clearScreen: false},
};

const includeFile = path.resolve(assetsDir, 'rollup.config.d', 'include.js');
if (fs.existsSync(includeFile)) require(includeFile)(config, {isDev});

if (!config.output.dir && !config.output.file) config.output.file = outPath(pkg.name.replace(/\W+/g, '-') + '.[hash].js');

module.exports = config;
