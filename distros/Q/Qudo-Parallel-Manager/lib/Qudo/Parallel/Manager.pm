package Qudo::Parallel::Manager;
use strict;
use warnings;
use Qudo;
use UNIVERSAL::require;
use Parallel::Prefork::SpareWorkers qw(:status);
use Sub::Throttle qw/throttle/;
use IO::Socket;

our $VERSION = '0.06';

sub new {
    my ($class, %args) = @_;

    my $max_request_par_child = delete $args{max_request_par_child} || 30;
    my $max_workers           = delete $args{max_workers}           || 1;
    my $min_spare_workers     = delete $args{min_spare_workers}     || 1;
    my $max_spare_workers     = delete $args{max_spare_workers}     || $max_workers;
    my $auto_load_worker      = delete $args{auto_load_worker}      || 1;
    my $work_delay            = $args{work_delay}                   || 5;
    my $admin                 = delete $args{admin}                 || 0;
    my $admin_host            = delete $args{admin_host}            || '127.0.0.1';
    my $admin_port            = delete $args{admin_port}            || 90000;
    my $debug                 = delete $args{debug}                 || 0;

    my $qudo = Qudo->new(%args);

    $qudo->manager->register_hooks(qw/Qudo::Hook::Scoreboard/);

    my $self = bless {
        max_workers           => $max_workers,
        max_request_par_child => $max_request_par_child,
        min_spare_workers     => $min_spare_workers,
        max_spare_workers     => $max_spare_workers,
        work_delay            => $work_delay,
        admin                 => $admin,
        admin_host            => $admin_host,
        admin_port            => $admin_port,
        debug                 => $debug,
        qudo                  => $qudo,
    }, $class;

    if ($auto_load_worker) {
        for my $worker (@{$qudo->{manager_abilities}}) {
            $self->debug("Setting up the $worker\n");
            $worker->use or die $@
        }
    }

    $self;
}

sub debug {
    my ($self, $msg) = @_;
    warn $msg if $self->{debug};
}

sub run {
    my $self = shift;

    $self->debug("START WORKING : $$\n");

    my $pm = $self->pm;
    my $c_pid = $self->start_admin_port;

    while ($pm->signal_received ne 'TERM') {
        $pm->start and next;

        $self->debug("spawn $$\n");

        {
            my $manager = $self->{qudo}->manager;
            for my $dsn ($manager->shuffled_databases) {
                my $db = $manager->driver_for($dsn);
                $db->reconnect;
            }

            my $reqs_before_exit = $self->{max_request_par_child};

            local $SIG{TERM} = sub { $reqs_before_exit = 0 };

            while ($reqs_before_exit > 0) {
                if (throttle(0.5, sub { $manager->work_once })) {
                    $self->debug("WORK $$\n");
                    --$reqs_before_exit
                } else {
                    sleep $self->{work_delay};
                }
            }
        }

        $self->debug("FINISHED $$\n");
        $pm->finish;
    }

    $pm->wait_all_children;

    $self->stop_admin_port($c_pid);
}

sub stop_admin_port {
    my ($self, $pid) = @_;
    return unless $pid;
    kill 'TERM', $pid;
}

sub start_admin_port {
    my $self = shift;

    return unless $self->{admin};

    my $pid = fork();
    die "fork failed: $!" unless defined $pid;
    return $pid if $pid; # main process

    my $admin = IO::Socket::INET->new(
        Listen    => 5,
        LocalAddr => $self->{admin_host},
        LocalPort => $self->{admin_port},
        Proto     => 'tcp',
        Type      => SOCK_STREAM,
        ReuseAddr => 1,
    ) or die "Cannot open server socket: $!";

    while (my $remote = $admin->accept) {
        my $status = join ' ', $self->pm->scoreboard->get_statuses;
        $remote->print($status);
        $remote->close;
    }
}

sub pm {
    my $self = shift;

    $self->{pm} ||= do {

        my $pm = Parallel::Prefork::SpareWorkers->new({
            max_workers       => $self->{max_workers},
            min_spare_workers => $self->{min_spare_workers},
            max_spare_workers => $self->{max_spare_workers},
            trap_signals      => {
                TERM => 'TERM',
                HUP  => 'TERM',
            },
        });

        {
            no strict 'refs'; ## no critic.
            *{"Qudo::Parallel::Manager::Registrar::pm"} = sub { $pm }
        }

        $pm;
    };
}

1;
__END__

=head1 NAME

Qudo::Parallel::Manager - auto control forking manager process.

=head1 SYNOPSIS

  use Qudo::Parallel::Manager;
  my $manager = Qudo::Parallel::Manager->new(
      databases => [+{
          dsn      => 'dbi:SQLite:/tmp/qudo.db',
          username => '',
          password => '',
      }],
      work_delay             => 3,
      max_workers            => 5,
      min_spare_workers      => 1,
      max_spare_workers      => 5,
      max_request_par_chiled => 30,
      auto_load_worker       => 1,
      admin                  => 1,
      debug                  => 1,
  );
  $manager->run; # start fork and work.

  # other process. get worker scoreborad.
  use IO::Socket::INET;
  my $sock = IO::Socket::INET->new(
      PeerHost => '127.0.0.1',
      PeerPort => 90000,
      Proto    => 'tcp',
  ) or die 'can not connect admin port.';

  # get scoreborad
  # ex) _ . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  my $status = $sock->getline;
  $sock->close;

=head1 DESCRIPTION

Qudo::Parallel::Manager is auto control forking manager process.
and get worker scoreborad.

=head1 AUTHOR

Atsushi Kobayashi E<lt>nekokak _at_ gmail _dot_ comE<gt>

=head1 SEE ALSO

L<Qudo>

L<Parallel::Prefork::SpareWorkers>

L<IO::Socket::INET>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
