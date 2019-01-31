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

  # case hot deploy
  #~ my $hypnotoad_pid_file = $minion->app->config->{hypnotoad}{pid_file};
  #~ my $hypnotoad_pid = check_pid(
    #~ ($hypnotoad_pid_file && path($hypnotoad_pid_file))
    #~ || path($ENV{HYPNOTOAD_APP})->sibling('hypnotoad.pid')
  #~ );
  # Minion job here would be better for graceful restart worker
  # when hot deploy hypnotoad (TODO)
  
  # case hot deploy and kill -USR2
  return
    #~ if $hypnotoad_pid && !$ENV{HYPNOTOAD_STOP};
    if $ENV{HYPNOTOAD_PID} && !$ENV{HYPNOTOAD_STOP};

  $minion->${ \\&kill_workers }();
  
  return if $ENV{HYPNOTOAD_STOP};
  
  while ($workers--) {
    defined(my $pid = fork())   || die "Can't fork: $!";
    next  if $pid;

    $minion->${ \\&worker_run }();
    CORE::exit(0);
  }
}

# Cases: morbo script/app.pl | perl script/app.pl daemon
sub subprocess {
  my ($minion) = @_;

  $minion->${ \\&kill_workers }();

  # subprocess allow run/restart worker later inside app worker
  my $subprocess = Mojo::IOLoop::Subprocess->new();
  $subprocess->run(
    sub {
      my $subprocess = shift;
      $minion->${ \\&worker_run }();
      return $$;
    },
    sub {1}
  );
  # Dont $subprocess->ioloop->start here!
}

sub worker_run {
  my ($minion) = @_;
  $ENV{MINION_PID} = $$;
  $0 = "$0 minion worker";
  $minion->app->log->info("Minion worker (pid $$) was started");
  $minion->worker->run;
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


sub kill_workers {
  my ($minion, $workers) = @_;

  $workers ||= $minion->${ \\&list_workers }();
  kill 'QUIT', $_->{pid}
    and $minion->app->log->info("Minion worker (pid $_->{pid}) was stoped")
    for @$workers;
}

# all workers
sub list_workers {
  my ($minion) = @_;
  $minion->backend->pg->db->query(q{
    select *,
      extract(epoch from now()-started) as "time_work",
      count(*) over() as total
    from minion_workers
  })->expand->hashes->to_array;
}

#~ sub killer_task {
  #~ my ($job, $worker, $log) = @_;
  #~ return
    #~ unless $worker->{pid} eq $ENV{MINION_PID};
  #~ $log && $log->info("Minion worker (pid $worker->{pid}) was stoped");
  #~ kill 'QUIT', $worker->{pid};
  #~ $job->finish($worker->{pid});
#~ }

our $VERSION = '0.09073';# as to Minion/100+0.000<minor>
