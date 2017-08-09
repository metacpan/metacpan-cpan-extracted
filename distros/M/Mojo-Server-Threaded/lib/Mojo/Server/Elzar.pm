package Mojo::Server::Elzar;
use Mojo::Base -base;

use Mojo::File 'path';
use Mojo::Server::Threaded;
use Mojo::Util 'steady_time';
use Scalar::Util 'weaken';
use Win32::Process;

our $VERSION = $Mojo::Server::Threaded::VERSION;

has threaded => sub { Mojo::Server::Threaded->new(listen => ['http://*:8080']) };
has upgrade_timeout => 60;

sub configure {
  my ($self, $name, $fallback_name) = @_;

  # Elzar settings
  my $threaded = $self->threaded;
  my $c = $threaded->app->config($name)
       || $threaded->app->config($fallback_name)
       || {};

  $self->upgrade_timeout($c->{upgrade_timeout}) if $c->{upgrade_timeout};

  # threaded settings
  $threaded->reverse_proxy($c->{proxy})   if defined $c->{proxy};
  $threaded->max_clients($c->{clients})   if $c->{clients};
  $threaded->max_requests($c->{requests}) if $c->{requests};
  defined $c->{$_} and $threaded->$_($c->{$_})
    for qw(accepts backlog graceful_timeout heartbeat_interval),
    qw(heartbeat_timeout inactivity_timeout listen pid_file spare workers);
}

sub run {
  my ($self, $app) = @_;

  # Remember executable and application for later
  $ENV{ELZAR_EXE} ||= $0;
  $0 = $ENV{ELZAR_APP} ||= path($app)->to_abs->to_string;

  # This is a production server
  $ENV{MOJO_MODE} ||= 'production';

  # Clean start (to make sure everything works)
  unless (
       $ENV{ELZAR_FOREGROUND}
    || $ENV{ELZAR_COMMAND}
    || $ENV{ELZAR_STOP}
    || $ENV{ELZAR_TEST}
    || $ENV{ELZAR_REV}++
  ) {
    die "Can't exec: $!" unless exec $^X, $ENV{ELZAR_EXE};
  }

  my $threaded = $self->threaded->cleanup(0);

  $threaded->register_command(
    DEPLOY => sub {
      $threaded->app->log->info("got HOT_DEPLOY signal, setting upgrade flag");
      $self->{upgrade} ||= steady_time;
    }
  );

  # Preload application and configure server
  $threaded->load_app($app)->config->{elzar}{pid_file}
    //= path($ENV{ELZAR_APP})->sibling('elzar.pid')->to_string;
  $self->configure('elzar', 'hypnotoad');
  #weaken $self;
  $threaded->on(wait   => sub { $self->_manage });
  $threaded->on(reap   => sub { $self->_cleanup(pop) });
  $threaded->on(finish => sub { $self->_finish });

  # Testing
  _exit('Everything looks good!') if $ENV{ELZAR_TEST};

  # Send command to running server
  $threaded->send_command($ENV{ELZAR_COMMAND})
    && _exit("Sent command '$ENV{ELZAR_COMMAND}'!")
    if $ENV{ELZAR_COMMAND};

  # Stop running server
  $self->_stop if $ENV{ELZAR_STOP};

  # Initiate hot deployment
  $self->_hot_deploy unless $ENV{ELZAR_PORT};

  # Daemonize as early as possible (but not for restarts)
  $threaded->start;

  # Start accepting connections
  $threaded->cleanup(1)->run;
}

sub _cleanup {
  my ($self, $pid) = @_;

  # Clean up failed upgrade
  return unless ($self->{new} || '') eq $pid;
  $self->threaded->app->log->error('Zero downtime software upgrade failed');
  delete @$self{qw(new upgrade)};
}

sub _exit { say ''; say shift and exit 0 }

sub _finish {
  my $self = shift;

  $self->{finish} = 1;
  return unless my $new = $self->{new};

  my $threaded = $self->threaded->cleanup(0);
  unlink $threaded->pid_file;
  #$threaded->ensure_pid_file($new);
}

sub _hot_deploy {
  my $self = shift;
  # Make sure server is running
  return unless my $pid = $self->threaded->check_pid;

  # Start hot deployment
  $self->threaded->send_command('DEPLOY');
  _exit("Starting hot deployment for Elzar server $pid.");
}

sub _manage {
  my $self = shift;

  my $threaded = $self->threaded;
  my $log = $threaded->app->log;

  # Upgraded (wait for all workers to send a heartbeat)
  my $mport = $self->threaded->management_port;
  if ($ENV{ELZAR_PORT} && $ENV{ELZAR_PORT} ne $mport) {
    $log->debug("Upgrade in progress");
    return unless $threaded->healthy == $threaded->workers;
    $log->info("Upgrade successful, stopping server with port $ENV{ELZAR_PORT}");
    $self->threaded->send_command('QUIT', '', $ENV{ELZAR_PORT});
  }

  $ENV{ELZAR_PORT} = $mport unless ($ENV{ELZAR_PORT} // '') eq $mport;

  # Upgrade
  if ($self->{upgrade} && !$threaded->{finished}) {

    # Fresh start
    my $ut = $self->upgrade_timeout;
    unless ($self->{new}) {
      $log->info("Starting zero downtime software upgrade ($ut seconds)");
      Win32::Process::Create(
        my $obj,
        $^X,
        qq("$^X" "$ENV{ELZAR_EXE}"),
        0,
        NORMAL_PRIORITY_CLASS,
        ".",
      ) || die Win32::FormatMessage(Win32::GetLastError());
      $self->{new} = $obj->GetProcessID();
      $log->info($$ . " new: $self->{new}");
    }

    # Timeout
    if ( $self->{upgrade} + $ut <= steady_time ) {
      $log->info("Killing $self->{new}");
      Win32::Process::KillProcess($self->{new}, my $ec = -1);
      $self->_cleanup($self->{new});
    }
  }
}

sub _stop {
  my $self = shift;
  _exit('Elzar server not running.')
    unless my $pid = $self->threaded->check_pid;
  $self->threaded->send_command('QUIT');
  _exit("Stopping Elzar server $pid gracefully.");
}

1;

=encoding utf8

=head1 NAME

Mojo::Server::Elzar - A windows multithreaded production web server

=head1 SYNOPSIS

  use Mojo::Server::Elzar;

  my $elzar = Mojo::Server::Elzar->new;
  $elzar->run('/home/me/myapp.pl');

=head1 DESCRIPTION

L<Mojo::Server::Elzar> is a multithreaded alternative for
L<Mojo::Server::Hypnotoad> which is not available under Win32.
It is designed to work as far as possible like L<Mojo::Server::Hypnotoad>
and will even use existing hypnotoad configuration entries.

The differences will be listed in this document.

To start applications with it you can use the L<elzar> script, which
listens on port C<8080> and defaults to C<production> mode for L<Mojolicious>
and L<Mojolicious::Lite> applications.

  $ elzar ./myapp.pl

You can run the same command again for automatic hot deployment.

  $ elzar ./myapp.pl
  Starting hot deployment for Elzar server 31841.

This second invocation will load the application again, detect the process id
file with it, and send a "DEPLOY" command to the already running server.

See L<Mojolicious::Guides::Cookbook/"DEPLOYMENT"> for more.

=head1 MANAGER SIGNALS

The L<Mojo::Server::Elzar> manager process can be controlled at runtime
with the following signals.

=head2 INT, TERM

Shut down server immediately.

=head2 QUIT

Shut down server gracefully.

=head1 SETTINGS

L<Mojo::Server::Elzar> can be configured with the same settings as
L<Mojo::Server::Hypnotoad>.

=head1 METHODS

L<Mojo::Server::Elzar> implements the same methods as
L<Mojo::Server::Hypnotoad>.

=head1 MANAGER COMMANDS

L<Mojo::Server::Elzar> can be controlled by the same commands as
L<Mojo::Server::Threaded>. For example to decrease the amount of
workers by 2:

  $ elzar ./myapp.pl -c "WORKERS -2"
  Sent command 'WORKERS -2'!

=head1 CAVEATS

L<Mojo::Server::Elzar> is new and should not be considered ready for
production yet. Please report any issues on github
L<https://github.com/tomk3003/mojo-server-threaded/issues>

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
