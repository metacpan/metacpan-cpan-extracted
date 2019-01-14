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
has usage => sub { shift->extract_usage };

has _morbo => sub {
  require Mojo::Server::Morbo;
  Mojo::Server::Morbo->new;
};

has _script_name => $0;
has _webpack_pid => undef;

sub run {
  my ($self, $app) = shift->_parse_argv(@_);

  local $ENV{MOJO_WEBPACK_DEBUG} //= $ENV{MORBO_VERBOSE} // 0;
  local $ENV{MOJO_WEBPACK_LAZY} = 1;

  $self->_start_webpack($app);
  warn "[Webpack] Webpack has pid @{[$self->_webpack_pid]}.\n" if $ENV{MORBO_VERBOSE} and !SILENT;

  $self->_run_morbo($app);

  warn "[Webpack/$$] Reaping webpack with pid @{[$self->_webpack_pid]}...\n" if $ENV{MORBO_VERBOSE} and !SILENT;
  1 while kill $self->_webpack_pid;
}

sub _exec_mojo_webpack {
  my ($self, @argv) = @_;
  warn "[Webpack] exec mojo webpack @argv ...\n" if $ENV{MORBO_VERBOSE} and !SILENT;
  { exec mojo => webpack => @argv };
  die "exec mojo @argv: $!";
}

sub _parse_argv {
  my ($self, @argv) = @_;

  getopt \@argv,
    'b|backend=s' => \$ENV{MOJO_MORBO_BACKEND},
    'h|help'      => \my $help,
    'l|listen=s'  => \my @listen,
    'm|mode=s'    => \$ENV{MOJO_MODE},
    'v|verbose'   => \$ENV{MORBO_VERBOSE},
    'w|watch=s'   => \my @watch;

  # Need to run "mojo webpack" and not "./myapp.pl webpack" to have a clean environment
  $self->_exec_mojo_webpack($self->_script_name, @argv) if path($self->_script_name)->basename ne 'mojo';

  die join "\n\n", $self->description, $self->usage if $help or !(my $app = shift @argv);

  $self->_morbo->backend->watch(\@watch)  if @watch;
  $self->_morbo->daemon->listen(\@listen) if @listen;

  return ($self, $app);
}

sub _run_morbo {
  local $WORKER_PID = $$;
  shift->_morbo->run(shift);
}

sub _start_webpack {
  my ($self, $app) = @_;

  local $ENV{MOJO_WEBPACK_BUILD} = '--watch';
  die "Can't fork: $!" unless defined(my $pid = fork);

  # Manager
  return $self->_webpack_pid($pid) if $pid;

  # Webpack worker
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

  Options:
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
