package Proc::tored::Machine;
$Proc::tored::Machine::VERSION = '0.19';
use strict;
use warnings;
use Moo;
use Carp;
use Auto::Mata '!with';
use Proc::tored::Flag;
use Proc::tored::PidFile;
use Proc::tored::Types -types;
use Time::HiRes;
use Type::Utils qw(declare as where);
use Types::Standard -types;

use constant READY  => 'READY';
use constant STATUS => 'STATUS';
use constant LOCK   => 'LOCK';
use constant TOUCH  => 'TOUCH';
use constant STOP   => 'STOP';
use constant TERM   => 'TERM';

my $Lock    = Maybe[InstanceOf['Guard']];
my $Flag    = InstanceOf['Proc::tored::Flag'];
my $PidFile = InstanceOf['Proc::tored::PidFile'];

my $Proctor = declare 'Proctor', as Dict[
  pidfile => $PidFile,   # PidFile
  stopped => $Flag,      # Stop Flag
  paused  => $Flag,      # Pause Flag
  traps   => SignalList, # list of signals to trap
  call    => CodeRef,    # code ref to call while running
  lock    => $Lock,      # guard set on successful lock
  started => Bool,       # initialization status
  quit    => Bool,       # flag set by trapped posix signals
  finish  => Bool,       # true when last callback returned false
];

my $Stopped    = declare 'Stopped',    as  $Proctor, where { $_->{stopped}->is_set || $_->{quit} };
my $NotStopped = declare 'NotStopped', as ~$Stopped;
my $Unlocked   = declare 'Unlocked',   as  $NotStopped, where { !$_->{lock} };
my $Locked     = declare 'Locked',     as  $NotStopped, where { $_->{lock} };
my $Started    = declare 'Started',    as  $Locked, where { $_->{started} };
my $Paused     = declare 'Paused',     as  $Started, where { $_->{paused}->is_set };
my $NotPaused  = declare 'NotPaused',  as ~$Paused;
my $Running    = declare 'Running',    as  $NotPaused & $Started, where { !$_->{finish} };
my $Finished   = declare 'Finished',   as  $Started, where { $_->{finish} };

sub pause_sleep {
  my ($acc, $time) = @_;
  Time::HiRes::sleep($time);
  $acc;
}

sub sigtrap {
  my $acc = shift;
  foreach my $signal (@{$acc->{traps}}) {
    $SIG{$signal} = sub {
      warn "Caught SIG$signal\n";
      $acc->{quit} = 1;
      $acc;
    };
  }
}

my $FSM = machine {
  ready READY;
  term  TERM;

  # Ready
  transition READY,  to STATUS, on $Proctor;

  # Service loop
  transition STATUS, to STOP,   on $Finished;
  transition STATUS, to STOP,   on $Stopped;
  transition STATUS, to TOUCH,  on $Paused,   using { pause_sleep($_, 0.2) };
  transition STATUS, to TOUCH,  on $Running,  using { $_->{finish} = $_->{call}->() ? 0 : 1; $_ };

  # Touch pid file
  transition TOUCH,  to STATUS, using { $_->{pidfile}->touch; $_ };

  # PidFile lock
  transition STATUS, to LOCK,   on $Unlocked, using { $_->{lock} = $_->{pidfile}->lock; $_ };
  transition LOCK,   to STATUS, on $Locked,   using { sigtrap($_); $_->{started} = 1; $_ };
  transition LOCK,   to TERM,   on $Unlocked;

  # Term
  transition STOP,   to TERM,   on $Proctor,  using { undef $_->{lock}; undef $SIG{$_} foreach @{$_->{traps}}; $_ };
};

has pidfile_path => (is => 'ro', isa => NonEmptyStr, required => 1);
has stop_path    => (is => 'ro', isa => NonEmptyStr, required => 1);
has pause_path   => (is => 'ro', isa => NonEmptyStr, required => 1);
has traps        => (is => 'ro', isa => SignalList, default => sub {[]});

has pidfile => (
  is  => 'lazy',
  isa => $PidFile,
  handles => {
    read_pid    => 'read_file',
    running_pid => 'running_pid',
    is_running  => 'is_running',
  },
);

has stop_flag => (
  is  => 'lazy',
  isa => $Flag,
  handles => {
    stop       => 'set',
    start      => 'unset',
    is_stopped => 'is_set',
  },
);

has pause_flag => (
  is  => 'lazy',
  isa => $Flag,
  handles => {
    pause     => 'set',
    resume    => 'unset',
    is_paused => 'is_set',
  },
);

sub _build_pidfile    { Proc::tored::PidFile->new(file_path => shift->pidfile_path) }
sub _build_stop_flag  { Proc::tored::Flag->new(touch_file_path => shift->stop_path) }
sub _build_pause_flag { Proc::tored::Flag->new(touch_file_path => shift->pause_path) }

sub clear_flags {
  my $self = shift;
  $self->start;
  $self->resume;
}

sub run {
  my ($self, $code) = @_;

  my $acc = {
    pidfile => $self->pidfile,
    stopped => $self->stop_flag,
    paused  => $self->pause_flag,
    traps   => $self->traps,
    call    => $code,
    lock    => undef,
    started => 0,
    finish  => 0,
    quit    => 0,
  };

  my $service = $FSM->();

  $service->($acc);

  return $acc->{started};
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Proc::tored::Machine

=head1 VERSION

version 0.19

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
