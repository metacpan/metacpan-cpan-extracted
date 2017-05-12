package Spread::Queue::ManagedWorker;

require 5.005_03;
use strict;
use vars qw($VERSION);
$VERSION = '0.3';

=head1 NAME

  Spread::Queue::ManagedWorker - utility class for Spread::Queue::Manager

=head1 DESCRIPTION

Tracks each worker that is registered with the queue manager.
Retains worker state.

Eventually add activity metrics (# messages assigned, uptime,
utilization, etc.).

States are:

=over 4

=item ready - available for task assignment

Worker controls this by sending a 'ready' message to the queue manager.

=item assigned - allocated to a task

Set by manager, after a message is transmitted to a ready worker.

=item acknowledged - worker is working on a task

When a 'working' message is received from an assigned worker.

=item terminated - no longer available for task assignment

'terminated' message has been received from worker, or an expected
status update has not been received so queue manager marks the worker
as dead.

If an assigned worker is terminated, then the task that was assigned
to that worker will be re-assigned to another worker.

=back

=head1 METHODS

=cut

my $AGE_THRESHOLD = 5;

sub new {
    my $proto = shift;
    my $class = ref ($proto) || $proto;

    my $self  = {};
    bless ($self, $class);

    $self->{PRIVATE} = shift;

    return $self;
}

sub private {
    my ($self) = shift;

    return $self->{PRIVATE};
}

sub status {
    my ($self) = shift;

    return $self->{STATUS};
}

sub is_ready {
    my ($self) = shift;

    return $self->{STATUS} eq "ready";
}

sub ready {
    my ($self) = shift;

    $self->{STATUS} = "ready";
    $self->{LAST_PING} = time;
}

# In this state, a message has been assigned to a worker
# but it hasn't confirmed yet that it is working on it.
sub assigned {
    my ($self) = shift;

    $self->{STATUS} = "assigned";
    $self->{LAST_PING} = time;
}

sub is_assigned {
    my ($self) = shift;

    return $self->{STATUS} eq "assigned";
}

sub working {
    my ($self) = shift;

    $self->{STATUS} = "working";
    delete $self->{LAST_PING};
}

sub is_working {
    my ($self) = shift;

    return $self->{STATUS} eq "working";
}

sub acknowledged {
    my ($self) = shift;

    $self->{STATUS} = "ack";
    $self->{LAST_PING} = time;
}

sub terminated {
    my ($self) = shift;

    $self->{STATUS} = "dead";
    delete $self->{LAST_PING};
}

sub is_terminated {
    my ($self) = shift;

    return $self->{STATUS} eq "terminated";
}

sub is_talking {
    my ($self) = shift;

    return $self->is_ready && ($self->{LAST_PING} > time-$AGE_THRESHOLD);
}

sub is_stuck {
    my $self = shift;

    # task was assigned to the worker, but it never acknowledged
    return $self->is_assigned && ($self->{LAST_PING} < time-$AGE_THRESHOLD);
}

1;


=head1 AUTHOR

Jason W. May <jmay@pobox.com>

=head1 COPYRIGHT

Copyright (C) 2002 Jason W. May.  All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

The license for the Spread software can be found at 
http://www.spread.org/license

=head1 SEE ALSO

  L<Spread::Queue>

=cut
