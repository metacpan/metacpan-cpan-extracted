package Mojolicious::Command::Author::webpack;
use Mojo::Base 'Mojolicious::Command';

use Mojo::File 'path';
use Mojo::Util 'getopt';

# Less noisy test runs
use constant SILENT => $ENV{HARNESS_ACTIVE} && !$ENV{HARNESS_IS_VERBOSE};

# Ugly hack to prevent Mojo::Server::Morbo from exiting
our $WORKER_PID = -1;
*CORE::GLOBAL::exit = sub { $WORKER_PID == $$ ? $_[0] : CORE::exit($_[0] // $!) };

has description => 'Start application with HTTP, WebSocket and Webpack development server';
has usage       => sub { shift->extract_usage };
has _morbo      => sub { require Mojo::Server::Morbo; Mojo::Server::Morbo->new };

sub run {
  my ($self, @argv) = @_;

  # Need to run "mojo webpack" and not "./myapp.pl webpack" to have a clean environment
  return $self->_exec_mojo_webpack($0, @argv) unless path($0)->basename eq 'mojo';

  # Parse command line options
  getopt \@argv,
    'B|build'     => \my $build,
    'b|backend=s' => \$ENV{MOJO_MORBO_BACKEND},
    'h|help'      => \my $help,
    'l|listen=s'  => \my @listen,
    'm|mode=s'    => \$ENV{MOJO_MODE},
    'v|verbose'   => \$ENV{MORBO_VERBOSE},
    'w|watch=s'   => \my @watch;

  die join "\n\n", $self->description, $self->usage if $help or !(my $app = shift @argv);
  return $self->_build($app) if $build;

  # Start rollup/webpack
  my $builder_pid = $self->_start_builder($app);
  say "Bundler started with pid $builder_pid." if +($ENV{MORBO_VERBOSE} // 1) == 1;

  # Set up and start morbo - Mojo::Server::Morbo::run() will block until the the app is killed
  local $ENV{MOJO_WEBPACK_BUILD} = '';    # Silence initial "Sure ... has been run ..." warning
  local $WORKER_PID = $$;
  $self->_morbo->backend->watch(\@watch)  if @watch;
  $self->_morbo->daemon->listen(\@listen) if @listen;
  $self->_morbo->run($app);

  # Stop rollup/webpack after the app is killed
  warn "[Webpack] [$$] Reaping builder with pid $builder_pid...\n" if $ENV{MORBO_VERBOSE} and !SILENT;
  1 while kill $builder_pid;
}

sub _build {
  my ($self, $app) = @_;
  $ENV{MOJO_WEBPACK_BUILD} ||= 'build';
  Mojo::Server->new->load_app($app);
}

sub _exec_mojo_webpack {
  my ($self, @argv) = @_;
  warn "Switching to `mojo webpack @argv` ...\n" unless SILENT;
  { exec qw(mojo webpack), @argv };
  die "exec mojo @argv: $!";
}

sub _start_builder {
  my ($self, $app) = @_;
  die "Can't fork: $!" unless defined(my $pid = fork);
  return $pid if $pid;
  local $ENV{MOJO_WEBPACK_BUILD} = 'watch';
  Mojo::Server->new->load_app($app);
  exit $!;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::Author::webpack - Mojolicious HTTP, WebSocket and Webpack development server

=head1 SYNOPSIS

  Usage: mojo webpack [OPTIONS] [APPLICATION]

    mojo webpack ./script/my_app
    mojo webpack ./myapp.pl
    mojo webpack -m production -l https://*:443 -l http://[::]:3000 ./myapp.pl
    mojo webpack -l 'https://*:443?cert=./server.crt&key=./server.key' ./myapp.pl
    mojo webpack -w /usr/local/lib -w public -w myapp.conf ./myapp.pl
    mojo webpack --build --mode production
    MOJO_NPM_BINARY=pnpm mojo webpack --build

  Options:
    -B, --build                    Build the assets and exit
    -b, --backend <name>           Morbo backend to use for reloading, defaults
                                   to "Poll"
    -h, --help                     Show this message
    -l, --listen <location>        One or more locations you want to listen on,
                                   defaults to the value of MOJO_LISTEN or
                                   "http://*:3000"
    -m, --mode <name>              Operating mode for your application,
                                   defaults to the value of
                                   MOJO_MODE/PLACK_ENV or "development"
    -v, --verbose                  Print details about what files changed to
                                   STDOUT
    -w, --watch <directory/file>   One or more directories and files to watch
                                   for changes, defaults to the application
                                   script as well as the "lib" and "templates"
                                   directories in the current working
                                   directory

=head1 DESCRIPTION

Start L<Mojolicious> and L<Mojolicious::Lite> applications with the
L<Mojo::Server::Morbo> web server.

=head1 ATTRIBUTES

=head2 description

  my $description = $daemon->description;
  $daemon         = $daemon->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $daemon->usage;
  $daemon   = $daemon->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

=head2 run

  $daemon->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Mojo::Server::Morbo>, L<Mojolicious::Plugin::Webpack>

=cut
