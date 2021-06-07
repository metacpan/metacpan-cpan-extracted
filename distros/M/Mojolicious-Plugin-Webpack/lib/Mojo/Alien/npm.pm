package Mojo::Alien::npm;
use Mojo::Base -base;

use Carp qw(croak);
use File::chdir;
use Mojo::File qw(path);
use Mojo::JSON qw(decode_json false);

use constant DEBUG => ($ENV{MOJO_NPM_DEBUG} || $ENV{MOJO_WEBPACK_DEBUG}) && 1;

has binary => sub {
  my $self = shift;
  return $ENV{MOJO_NPM_BINARY} ? $ENV{MOJO_NPM_BINARY} : 'npm';
};

has config => sub { path->to_abs->child('package.json') };
has mode   => sub { $ENV{NODE_ENV} || 'development' };

sub dependencies {
  my $self = shift;
  croak "Can't get dependency info without package.json" unless -r $self->config;

  my @args = $self->binary eq 'pnpm' ? qw(ls --json --silent) : qw(ls --json --parseable --silent);
  my $dependencies;

  eval {
    my $NPM = $self->_run(@args);

    # "WARN" might come from pnpm, and it also returns an array-ref
    $dependencies = decode_json(join '', grep { !/WARN/ } <$NPM>);
    $dependencies = $dependencies->[0] if ref $dependencies eq 'ARRAY';
    $dependencies = {map { %{$dependencies->{$_} || {}} } qw(devDependencies dependencies)};
  } or do {
    croak sprintf '%s failed: %s', join(' ', $self->binary, @args), $@;
  };

  my $package = decode_json $self->config->slurp;
  my %types   = (devDependencies => 'dev', dependencies => 'prod', optionalDependencies => 'optional');
  for my $type (qw(optionalDependencies devDependencies dependencies)) {
    for my $name (keys %{$package->{$type}}) {
      $dependencies->{$name}{required} = $package->{$type}{$name};
      $dependencies->{$name}{type}     = $types{$type};
      $dependencies->{$name}{version} //= '';
    }
  }

  return $dependencies;
}

sub init {
  my $self = shift;
  return $self if -r $self->config;
  $self->_run(qw(init -y));
  croak "$self->{basename} init failed: @{[$self->config]} was not generated." unless -r $self->config;
  return $self;
}

sub install {
  my ($self, $name, $info) = @_;
  croak "Can't install packages without package.json" unless -w $self->config;

  # Install everything
  do { $self->_run('install'); return $self } unless $name;

  # Install specific package
  $name = sprintf '%s@%s', $name, $info->{version} if $info->{version};
  my $type = sprintf '--save-%s', $info->{type} || 'dev';
  $self->_run('install', $name, $type);
  return $self;
}

sub _run {
  my $self = shift;
  my @cmd  = ($self->binary, @_);
  $self->{basename} ||= path($cmd[0])->basename;
  local $CWD = $self->config->dirname->to_string;
  local $ENV{NODE_ENV} = $self->mode;
  warn "[NPM] cd $CWD && @cmd\n" if DEBUG;
  open my $NPM, '-|', @cmd or die "Can't fork @cmd: $!";
  return $NPM if defined wantarray;
  map { DEBUG && print } <$NPM>;
}

# This is a utility function for the unit tests
sub _setup_working_directory {
  my ($class, $dir) = @_;
  my $remove_tree = $ENV{MOJO_NPM_CLEAN} ? 'remove_tree' : sub { };
  chdir(my $work_dir = path($dir ? $dir : ('local', path($0)->basename))->to_abs->tap($remove_tree)->make_path)
    or die "Couldn't set up working directory: $!";
  symlink $work_dir->dirname->child('node_modules')->make_path, 'node_modules'
    or warn "Couldn't set up shared node_modules: $!"
    unless -e 'node_modules';
  return $work_dir;
}

1;

=encoding utf8

=head1 NAME

Mojo::Alien::npm - Runs the external nodejs program npm

=head1 SYNOPSIS

  use Mojo::Alien::npm;
  my $npm = Mojo::Alien::npm->new;

  $npm->init;
  $npm->install;

=head1 DESCRIPTION

L<Mojo::Alien::webpack> is a class for runnig the external nodejs program
L<npm|https://npmjs.com/>.

=head1 ATTRIBUTES

=head2 binary

  $array_ref = $npm->binary;
  $npm = $npm->binary(['npm']);

The path to the npm executable. Default is "npm" unless the C<MOJO_NPM_BINARY>
environment variable has been set. This can also be set to "pnpm" in case you
prefer L<https://pnpm.io/>.

=head2 config

  $path = $npm->config;
  $npm = $npm->config(path->to_abs->child('package.json'));

Holds an I</absolute> path to "package.json".

=head2 mode

  $str = $npm->mode;
  $npm = $npm->mode('development');

Should be either "development" or "production". Will be used as "NODE_ENV"
environment variable when calling "npm".

=head1 METHODS

=head2 dependencies

  $dependencies = $npm->dependencies;

Used to get dependencies from L</config> combined with information from
C<npm ls>. The returned hash-ref looks like this:

  {
    "package-name" => {
      required => $str,  # version from package.json
      type     => $str,  # dev, optional or prod
      version  => $str,  # installed version
      ...
    },
    ...
  }

=head2 init

  $npm->init;

Used to create a default L</config> file.

=head2 install

  $npm->install;
  $npm->install('package-name');
  $npm->install('package-name', {type => 'prod', version => '0.1.2'});

Installs either all modules from L</config> or a given package by name. An
additional C<$info> hash can also be provided.

=head1 SEE ALSO

L<Mojolicious::Plugin::Webpack>.

=cut
