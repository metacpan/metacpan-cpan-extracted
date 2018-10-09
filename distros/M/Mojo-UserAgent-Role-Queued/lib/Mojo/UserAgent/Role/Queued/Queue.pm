package Mojo::UserAgent::Role::Queued::Queue;

use strict;
use warnings;

use Mojo::Base 'Mojo::EventEmitter';

has jobs => sub { [] };
has active => 0;
has max_active => 4;
has callback => undef;


sub process {
   my ($self) = @_;
  # we have jobs and can run them:
  while ($self->active < $self->max_active
    and my $job = shift @{$self->jobs})
  {
    $self->active($self->active + 1);
    my $tx = shift @$job;
    my $cb = shift @$job;
    weaken $self;
    $tx->on(finish => sub { $self->tx_finish(); });
    $self->callback->( $tx, $cb );
  }
  if (scalar @{$self->jobs} == 0 && $self->active == 0) {
    $self->emit('queue_empty');
  }
}

sub tx_finish {
    my ($self) = @_;
    $self->active($self->active - 1);
    $self->process();
}

sub enqueue {
    my ($self, $tx, $cb) = @_;
    my $job = [$tx, $cb];
    push @{$self->jobs}, $job;
    $self->process();
}

1;
