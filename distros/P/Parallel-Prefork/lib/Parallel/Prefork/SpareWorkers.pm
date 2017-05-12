package Parallel::Prefork::SpareWorkers;

use strict;
use warnings;

use Exporter qw(import);

use List::MoreUtils qw(uniq);

use base qw/Parallel::Prefork/;

use constant STATUS_NEXIST => '.';
use constant STATUS_IDLE   => '_';

our %EXPORT_TAGS = (
    status => [ qw(STATUS_NEXIST STATUS_IDLE) ],
);
our @EXPORT_OK = uniq sort map { @$_ } values %EXPORT_TAGS;
$EXPORT_TAGS{all} = \@EXPORT_OK;

__PACKAGE__->mk_accessors(qw/min_spare_workers max_spare_workers scoreboard heartbeat/);

sub new {
    my $klass = shift;
    my $self = $klass->SUPER::new(@_);
    die "mandatory option min_spare_workers not set"
        unless $self->{min_spare_workers};
    $self->{max_spare_workers} ||= $self->max_workers;
    $self->{heartbeat} ||= 0.25;
    $self->{scoreboard} ||= do {
        require 'Parallel/Prefork/SpareWorkers/Scoreboard.pm';
        Parallel::Prefork::SpareWorkers::Scoreboard->new(
            $self->{scoreboard_file} || undef,
            $self->max_workers,
        );
    };
    $self;
}

sub start {
    my $self = shift;
    my $ret = $self->SUPER::start();
    unless ($ret) {
        # child process
        $self->scoreboard->child_start();
        return;
    }
    return 1;
}

sub num_active_workers {
    my $self = shift;
    scalar grep {
        $_ ne STATUS_NEXIST && $_ ne STATUS_IDLE
    } $self->scoreboard->get_statuses;
}

sub set_status {
    my ($self, $status) = @_;
    $self->scoreboard->set_status($status);
}

sub _decide_action {
    my $self = shift;
    my $spare_workers = $self->num_workers - $self->num_active_workers;
    return 1
        if $spare_workers < $self->min_spare_workers
            && $self->num_workers < $self->max_workers;
    return -1
        if $spare_workers > $self->max_spare_workers;
    return 0;
}

sub _on_child_reap {
    my ($self, $exit_pid, $status) = @_;
    $self->SUPER::_on_child_reap($exit_pid, $status);
    $self->scoreboard->clear_child($exit_pid);
}

sub _max_wait {
    my $self = shift;
    return $self->{heartbeat};
}

1;
__END__

=head1 NAME

Parallel::Prefork::SpareWorkers - A prefork server framework with support for (min|max)spareservers

=head1 SYNOPSIS

  use Parallel::Prefork::SpareWorkers qw(:status);
  
  my $pm = Parallel::Prefork::SpareWorkers->new({
    max_workers       => 40,
    min_spare_workers => 5,
    max_spare_workers => 10,
    trap_signals      => {
      TERM => 'TERM',
      HUP  => 'TERM',
      USR1 => undef,
    },
  });
  
  while ($pm->signal_received ne 'TERM') {
    load_config();
    $pm->start and next;
    
    # do what ever you like, as follows
    while (my $sock = $listener->accept()) {
      $pm->set_status('A');
      ...
      $sock->close();
      $pm->set_status(STATUS_IDLE);
    }
    
    $pm->finish;
  }
  
  $pm->wait_all_children;

=head1 DESCRIPTION

C<Parallel::Prefork::SpareWorkers> is a subclass of C<Parallel::Prefork> that supports setting minimum and maximum number of spare worker processes, a feature commonly found in network servers.  The module adds to C<Parallel::Prefork> several initialization parameters, constants, and a method to set state of the worker processes.

=head1 METHODS

=head2 new

Instantiation.  C<Parallel::Prefork::ShpareWorkers> recognizes the following parameters in addition to those defined by C<Parallel::Prefork>.  The parameters can be accessed using accessors with same names as well.

=head3 min_spare_workers

minimum number of spare workers (mandatory)

=head3 max_spare_workers

maxmum number of spare workers (default: max_workers)

=head3 heartbeat

a fractional period (in seconds) of child amount checking. Do not use very small numbers to avoid frequent use of CPU (default: 0.25)

=head3 scoreboard_file

filename of scoreboard.  If not set, C<Parallel::Prefork::SpareWorkers> will create a temporary file.

=head2 set_status

sets a single-byte character state of the worker process.  Worker processes should set any character of their choice using the function (but not one of the reserved characters) to declare that it is running some kind of task.  Or the state should be set to C<STATUS_IDLE> '_' once the worker enters idle state.  The other reserved character is C<STATUS_NEXIST> '.' which should never be set directly by applications.

=head1 CONSTANTS

=head2 STATUS_NEXIST

scoreboard status character '.', meaning no worker process is assigned to the slot of the scoreboard.  Applications should never set this value directly.

=head2 STATUS_IDLE

scoreboard status character '_', meaning that a worker process is in idle state

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
