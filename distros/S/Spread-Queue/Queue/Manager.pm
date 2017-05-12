package Spread::Queue::Manager;

=head1 NAME

Spread::Queue::Manager - coordinate one-of-many message delivery

=head1 SYNOPSIS

The provided 'sqm' executable does this:

  use Spread::Queue::Manager;
  my $queue_name = shift @ARGV || die "usage: sqm queue-name";
  my $session = new Spread::Queue::Manager($queue_name);
  $session->run;

=head1 DESCRIPTION

The queue manager is responsible for assigning incoming messages
(see Spread::Queue::Sender) to registered workers (see Spread::Queue::Worker).

When a message comes in, it is assigned to the first available worker,
otherwise it is put into a FIFO queue.

When a worker reports availability, it is sent the first pending message,
otherwise it is put into a FIFO queue.

When a message is sent to a worker, the worker should immediately
acknowledge receipt.  If the worker does not acknowledge, the message
will (eventually) be assigned to another worker.

If a queue manager is already running (detected via Spread group membership
messages), the new sqm should terminate.

=head1 METHODS

=cut

require 5.005_03;
use strict;
use vars qw($VERSION);
$VERSION = '0.4';

use Carp;

use Spread::Session;
use Spread;
use Data::Serializer;

use Spread::Queue::ManagedWorker;
use Spread::Queue::FIFO;

use Log::Channel;

BEGIN {
    my $qmlog = new Log::Channel;
    sub qmlog { $qmlog->(@_) }
}

my $DEFAULT_SQM_HEARTBEAT = 3;

my %Worker;

=item B<new>

  my $session = new Spread::Queue::Manager($queue_name);

Initialize Spread messaging environment, and prepare to act
as the queue manager.  If queue_name is omitted, environment
variable SPREAD_QUEUE will be checked.

=cut

sub new {
    my $proto = shift;
    my $class = ref ($proto) || $proto;

    my %config = @_;
    my $self  = \%config;
    bless ($self, $class);

    $self->{QUEUE} = $ENV{SPREAD_QUEUE} unless $self->{QUEUE};
    croak "Queue name is required" unless $self->{QUEUE};

    $self->{WQNAME} = "WQ_$self->{QUEUE}";
    $self->{MQNAME} = "MQ_$self->{QUEUE}";

    $self->{MQ} = new Spread::Queue::FIFO($self->{MQNAME});
    $self->{WQ} = new Spread::Queue::FIFO($self->{WQNAME});

    $self->{SESSION} = new Spread::Session (
					    MESSAGE_CALLBACK => \&message_callback,
					    ADMIN_CALLBACK => \&admin_callback,
					    TIMEOUT_CALLBACK => \&timeout_callback,
					   );
    $self->{SESSION}->subscribe($self->{MQNAME});
    $self->{SESSION}->subscribe($self->{WQNAME});

    $self->{SERIALIZER} = new Data::Serializer(serializer => 'Data::Denter');

    $self->{ACTIVE} = 1;

    $self->initialize_statistics;

    return $self;
}

sub initialize_statistics {
    my $self = shift;

    $self->{STATISTICS} = {
			   START_TIME => 0,
			   INBOUND_MESSAGES => 0,
			   ADMIN_MESSAGES => 0,
			   MESSAGES_DISPATCHED => 0,
			   MESSAGES_QUEUED => 0,
			   CURRENTLY_QUEUED => 0,
			   GROSS_PENDING_TIME => 0,
			   WORKER_NOTIFICATIONS => 0,
			   WORKER_REGISTRATIONS => 0,
			   WORKER_TERMINATIONS => 0,
			  };
}

=item B<new>

  $session->run;

Run loop for the queue manager.  Does not return unless interrupted.

=cut

sub run {
    my ($self) = shift;

    $self->{STATISTICS}->{START_TIME} = time;

    my $heartbeat = $ENV{SQM_HEARTBEAT} || $DEFAULT_SQM_HEARTBEAT;

    while ($self->{ACTIVE}) {
	$self->{SESSION}->receive($heartbeat, $self);
    }
}


sub message_callback {
    my ($msg, $self) = @_;

    if (grep { $_ eq $self->{MQNAME} } @{$msg->{GROUPS}}) {
	$self->handle_message($msg->{SENDER}, $msg->{BODY});
    } elsif (grep { $_ eq $self->{WQNAME} } @{$msg->{GROUPS}}) {
	$self->handle_worker($msg->{SENDER}, $msg->{BODY});
    }
}


sub handle_message {
    my ($self, $sender, $message) = @_;

    $self->handle_admin_command($sender, $message) && return;

    $self->{STATISTICS}->{INBOUND_MESSAGES}++;

    $self->_check_worker_queue;
    my ($available_worker, $pending_time) = $self->{WQ}->dequeue;
    if ($available_worker) {
	$self->dispatch($available_worker, {
					    originator => $sender,
					    body => $message
					   });
    } else {
	qmlog "ENQUEUE MESSAGE FROM $sender\n";
	$self->{MQ}->enqueue({
			      originator => $sender,
			      body => $message
			     });
	$self->{STATISTICS}->{MESSAGES_QUEUED}++;
    }
}


sub handle_admin_command {
    my ($self, $sender, $message) = @_;

    if ($message eq "^^status") {
	qmlog "STATUS request from $sender\n";

	$self->{STATISTICS}->{ADMIN_MESSAGES}++;

	$self->{SESSION}->publish($sender,
				  $self->snapshot);
	return 1;
    }
    return;
}


sub handle_worker {
    my ($self, $sender, $message) = @_;

    $self->{STATISTICS}->{WORKER_NOTIFICATIONS}++;

    my $data = $self->{SERIALIZER}->deserialize($message);
    my $status = $data->{status};

    my $worker = $Worker{$sender};
    if (!$worker) {
	$worker = new Spread::Queue::ManagedWorker($sender);
	$Worker{$sender} = $worker;

	$self->{STATISTICS}->{WORKER_REGISTRATIONS}++;
    }

#    qmlog "WORKER ", $worker->private, " status change: $status\n";

    if ($status eq 'ready') {
	$self->worker_ready($worker);
    } elsif ($status eq 'working') {
	$self->worker_working($worker);
    } elsif ($status eq 'terminate') {
	$self->worker_terminated($worker);
    } else {
	qmlog "**** INVALID STATUS '$status' FROM WORKER $sender ***\n";
    }

    $self->_clear_stuck_workers;
}


sub worker_ready {
    my ($self, $worker) = @_;

    delete $worker->{TASK};

    my ($pending_message, $pending_time) = $self->{MQ}->dequeue;
    if ($pending_message) {
	$self->dispatch($worker, $pending_message);
	$self->{STATISTICS}->{GROSS_PENDING_TIME} += $pending_time;
	qmlog "PENDING TIME: $pending_time\n";
    } else {
	if ($worker->is_ready) {
	    qmlog "WORKER ", $worker->private, " ALREADY PENDING\n";
	} else {
	    qmlog "WORKER ", $worker->private, " IS PENDING\n";
	    $self->{WQ}->enqueue($worker);
	}
	$worker->ready;
    }
}


sub worker_working {
    my ($self, $worker) = @_;

    if ($worker->is_assigned) {
	qmlog "WORKER ", $worker->private, " ACKNOWLEDGED\n";
	$worker->acknowledged;
    } else {
	qmlog "WHAT THE HECK IS ", $worker->private, " DOING???\n";
    }
}


sub worker_terminated {
    my ($self, $worker) = @_;

    $self->_dispose($worker);
#    $self->_check_worker_queue;

    $self->{STATISTICS}->{WORKER_TERMINATIONS}++;
}


sub dispatch {
    my ($self, $worker, $message) = @_;

    qmlog "DISPATCH MESSAGE FROM $message->{originator} TO ", $worker->private, "\n";

    $self->{SESSION}->publish($worker->private,
			      $self->{SERIALIZER}->serialize($message));
    $worker->{TASK} = $message;
    $worker->assigned;

    $self->{STATISTICS}->{MESSAGES_DISPATCHED}++;
}


sub timeout_callback {
    my ($self) = shift;

    # scrub workers from the front of the queue
    # who haven't signalled readiness lately

    foreach my $worker ($self->{WQ}->all) {
	qmlog "\t...worker $worker->{PRIVATE} is $worker->{STATUS}\n";
    }

    foreach my $worker ($self->{WQ}->all) {
	if ($worker->is_talking) {
	    # leader looks OK
	    last;
	}
	my $worker = $self->{WQ}->dequeue;
	$self->_dispose($worker);
    }

    $self->_clear_stuck_workers;
}

sub _check_worker_queue {
    my ($self) = shift;

    # scrub workers from the front of the queue
    # who haven't signalled readiness lately

    foreach my $worker ($self->{WQ}->all) {
	if ($worker->is_talking) {
	    # this one is fine
	    return;
	}
	my $worker = $self->{WQ}->dequeue;
	$self->_dispose($worker);
    }
}

sub _dispose {
    my ($self, $worker) = @_;

    qmlog "WORKER ", $worker->private, " TERMINATED\n";

    # reassign the task, and retire the worker
    my $task = $worker->{TASK};
    if ($task) {
	qmlog "Reassigning stuck message\n";
	$self->handle_message($task->{originator},
			      $task->{body});
    }
    delete $worker->{TASK};
    $worker->terminated;
}

sub _clear_stuck_workers {
    my $self = shift;

    foreach my $worker (values %Worker) {
	if ($worker->is_stuck) {
	    qmlog "WORKER ", $worker->private, " IS STUCK\n";
	    $self->_dispose($worker);
	}
    }
}

# Called for Spread admin messages - in particular, changes in
# group membership.  There should only be one listener subscribed
# to the MQ_ and WQ_ groups for this queue.

sub admin_callback {
    my ($msg, $self) = @_;

    if ($msg->{SERVICE_TYPE} & REG_MEMB_MESS) {
	foreach my $group (@{$msg->{GROUPS}}) {
	    if ($group ne $self->{SESSION}->{PRIVATE_GROUP}) {
		if (!$self->{INCUMBENT}) {
		    carp "Duplicate sqm $group detected for $self->{QUEUE}; aborting";
		    $self->{ACTIVE} = 0;
		} else {
		    carp "Duplicate sqm $group detected for $self->{QUEUE}; other should abort";
		}
	    }
	}
	$self->{INCUMBENT} = 1;
    }
}

sub snapshot {
    my $self = shift;

    $self->{STATISTICS}->{RUN_TIME} =
      time - $self->{STATISTICS}->{START_TIME};

    $self->{STATISTICS}->{CURRENTLY_QUEUED} =
      $self->{MQ}->length;

    return $self->{SERIALIZER}->serialize({
					   type => "status",
					   body => $self->{STATISTICS}
					  });
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

  L<Spread::Session>
  L<Spread::Queue::FIFO>
  L<Spread::Queue::Sender>
  L<Spread::Queue::Worker>
  L<Spread::Queue::ManagedWorker>
  L<Data::Serializer>

=cut
