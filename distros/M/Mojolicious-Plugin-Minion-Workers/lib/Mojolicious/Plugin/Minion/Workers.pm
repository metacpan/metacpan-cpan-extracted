package Mojolicious::Plugin::Minion::Workers;
use Mojo::Base 'Mojolicious::Plugin::Minion';

use Mojo::Util 'monkey_patch';
use Mojo::File 'path';

sub register {
  my ($self, $app, $conf) = @_;

  my $conf_workers = delete $conf->{workers};
  $self->SUPER::register($app, $conf)
    unless $app->renderer->get_helper('minion');

  my $is_manage = !$ARGV[0]
                                  || $ARGV[0] eq 'daemon'
                                  || $ARGV[0] eq 'prefork';
  my $is_prefork = $ENV{HYPNOTOAD_APP}
                                  || ($ARGV[0] && $ARGV[0] eq 'prefork');

  monkey_patch 'Minion',
    'manage_workers' => sub {
      return
        unless $is_manage;

      my $minion = shift;
      my $workers = shift || $conf_workers
        or return;

      if ($is_prefork) {
        $minion->${ \\&prefork }($workers);
      } else {
        $minion->${ \\&subprocess }();
      }
    };

  return $self;
}

# Cases: hypnotoad script/app.pl | perl script/app.pl prefork
sub prefork {
  my ($minion, $workers) = @_;

  my $hypnotoad_pid = check_pid(
    $minion->app->config->{hypnotoad}{pid_file}
    ? path($minion->app->config->{hypnotoad}{pid_file})
    : path($ENV{HYPNOTOAD_APP})->sibling('hypnotoad.pid')
  );
  # Minion job here would be better for graceful restart worker
  # when hot deploy hypnotoad (TODO)
  return
    if $hypnotoad_pid && !$ENV{HYPNOTOAD_STOP};

  kill_all($minion);
  
  return
    if $ENV{HYPNOTOAD_STOP};

  while ($workers--) {
    defined(my $pid = fork())   || die "Can't fork: $!";
    next
      if $pid;

    $0 = "$0 minion worker";
    $ENV{MINION_PID} = $$;
    $minion->app->log->error("Minion worker (pid $$) as prefork starting now ...");
    $minion->worker->run;
    CORE::exit(0);
  }
}

# Cases: morbo script/app.pl | perl script/app.pl daemon
sub subprocess {
  my ($minion) = @_;

  kill_all($minion);

  # subprocess allow run/restart worker later inside app worker
  my $subprocess = Mojo::IOLoop::Subprocess->new();
  $subprocess->run(
    sub {
      my $subprocess = shift;
      $ENV{MINION_PID} = $$;
      $0 = "$0 minion worker";
      $minion->app->log->error("Minion worker (pid $$) as subprocess starting  now ...");
      $minion->worker->run;
      return $$;
    },
    sub {1}
  );
  # Dont $subprocess->ioloop->start here!
}

# check process
sub check_pid {
  my ($pid_path) = @_;
  return undef unless -r $pid_path;
  my $pid = $pid_path->slurp;
  chomp $pid;
  # Running
  return $pid if $pid && kill 0, $pid;
  # Not running
  return undef;
}

# kill all prev workers
sub kill_all {
  my ($minion) = @_;

  kill 'QUIT', $_->{pid}
    and $minion->app->log->error("Minion worker (pid $_->{pid}) was stoped")
    for @{$minion->backend->list_workers()->{workers}};
}

our $VERSION = '0.09072';# as to Minion/100+0.000<minor>


=encoding utf8

=head1 Mojolicious::Plugin::Minion::Workers

Доброго всем

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 VERSION

0.09072 (up to Minion 9.07)

=head1 NAME

Mojolicious::Plugin::Minion::Workers - does extend base Mojolicious::Plugin::Minion
on manage Minion workers.

=head1 SYNOPSIS

  # Mojolicious (define amount workers in config)
  $self->plugin('Minion::Workers' => {Pg => ..., workers=>2});
  # or pass to $app->minion->manage_workers(<num>) later
  $self->plugin('Minion::Workers' => {Pg => ...});

  # Mojolicious::Lite (define amount workers in config)
  plugin 'Minion::Workers' => {Pg => ..., workers=>2};

  # Add tasks to your application
  app->minion->add_task(slow_log => sub {
    my ($job, $msg) = @_;
    sleep 5;
    $job->app->log->debug(qq{Received message "$msg"});
  });
  
  # Allow manage with amount workers (gets from config)
  app->minion->manage_workers();
  # or override config workers by pass
  app->minion->manage_workers(4);

  # Start jobs from anywhere in your application

=head1 DESCRIPTION

L<Mojolicious::Plugin::Minion::Workers> is a L<Mojolicious> plugin for the L<Minion> job
queue and has extending base L<Mojolicious::Plugin::Minion> for enable workers managment.

=head1 Manage workers

L<Mojolicious::Plugin::Minion::Workers> has patch the L<Minion> module on the following new one method.

=head2 manage_workers(int)

Start/restart Minion passed amount workers or get its from plugin config.
None workers mean skip managment.

  $app->minion->manage_workers(1);

Tested on standard commands:

  $ perl script/app.pl daemon
  $ perl script/app.pl prefork
  $ morbo script/app.pl # yes,  worker will restarted when morbo restarts on watch changes
  $ hypnotoad script/app.pl
  $ hypnotoad script/app.pl # hot deploy (TODO: graceful restarting minion workers)
  $ hypnotoad -s script/app.pl # yes, minion workers will stoped too

B<NOTE> for commands C<$ morbo script/app.pl> and C<$ perl script/app.pl daemon>
workers always one.

=head1 HELPERS

L<Mojolicious::Plugin::Minion::Workers> enable all helpers from base plugin L<Mojolicious::Plugin::Minion>,
thus you dont need apply base plugin (auto register).

=head1 METHODS

L<Mojolicious::Plugin::Minion::Workers> inherits all methods from
L<Mojolicious::Plugin::Minion> and override the following new ones.

=head2 register

  $plugin->register(Mojolicious->new, {Pg => ..., worker=>1});

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious::Plugin::Minion>, L<Minion>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche[-at-]cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojolicious-Plugin-Minion-Workers/issues>.
Pull requests also welcome.

=head1 COPYRIGHT

Copyright 2019+ Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
