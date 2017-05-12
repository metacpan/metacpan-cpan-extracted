package Spread::Queue::Worker;

=head1 NAME

Spread::Queue::Worker - accept Spread::Queue message assignments

=head1 SYNOPSIS

  use Spread::Queue::Worker;

  my $worker = new Spread::Queue::Worker(QUEUE => "myqueue",
                                         CALLBACK => \&mycallback,
                                        );
  $worker->run;

  sub mycallback {
    my ($worker, $originator, $input) = @_;

    my $result = {
		  response => "I heard you!",
		 };
    $worker->respond($originator, $result);
  }

=head1 DESCRIPTION

A process that declares itself to be a Spread::Queue::Worker will be
assigned messages in FIFO fashion by the sqm queue manager.

Messages as supported by Spread::Queue are serialized Perl hashes.
Spread::Queue does not enforce structure on message contents.

A running sqm for the queue is required before any messages will
be routed to the worker.  Worker will not terminate if sqm is not
running, or if it goes away.  If the sqm terminates and restarts,
it will reacquire any running workers (via heartbeat status signals).

=head1 METHODS

=cut

require 5.005_03;
use strict;
use vars qw($VERSION);
$VERSION = '0.4';

use Spread::Session;
use Data::Serializer;
use Carp;
use Log::Channel;

my $DEFAULT_HEARTBEAT = 2;

BEGIN {
    my $sqwlog = new Log::Channel;
    sub sqwlog { $sqwlog->(@_) }
}

=item B<new>

  my $worker = new Spread::Queue::Worker("myqueue");

Establish link to Spread messaging environment, and prepare to receive
messages on specific queue.  Queue name will be obtained from
SPREAD_QUEUE environment variable if not provided here.

=cut

sub new {
    my $proto = shift;
    my $class = ref ($proto) || $proto;

    my %config = @_;
    my $self  = \%config;
    bless ($self, $class);

    $self->{QUEUE} = $ENV{SPREAD_QUEUE} unless $self->{QUEUE};
    croak "Queue name is required" unless $self->{QUEUE};
    croak "Callback function is required" unless $self->{CALLBACK};

    $self->{HEARTBEAT} = $DEFAULT_HEARTBEAT unless $self->{HEARTBEAT};

    $self->{WQNAME} = "WQ_$self->{QUEUE}";
    my $session = new Spread::Session (
				       MESSAGE_CALLBACK => \&_message_callback,
				       TIMEOUT_CALLBACK => \&_timeout_callback,
				      );
    $self->{SESSION} = $session;
    $self->{SERIALIZER} = new Data::Serializer;

    sqwlog "Message queue worker activated on $self->{QUEUE}\n";

    $self->{STATUS} = 'ready';
    $self->{METRICS} = {
			start_time => time,
			num_messages => 0,
		       };
    return $self;
}

=item B<run>

  $worker->run;

Main loop for queue processing.  Each incoming message will trigger a
call to the user-specified callback function.

The loop will exit when $worker->terminate is called.

=cut

sub run {
    my ($self) = shift;

    $self->_timeout_callback;

    for (;;) {
	$self->{SESSION}->receive($self->{HEARTBEAT}, $self);

	last if $self->{TERMINATED};
    }
}

=item B<setup_Event>

  use Event;
  $worker->setup_Event;
  Event::loop;

Configure Event.pm callback for processing incoming messages.
$worker->terminate is still recommended in this configuration, to
advise the queue manager to no longer assign tasks to this worker.

=cut

sub setup_Event {
    my ($self) = shift;

    $self->{IS_EVENT} = 1;
    Event->io(fd => $self->{SESSION}->{MAILBOX},
	      cb => sub { $self->{SESSION}->receive(0, $self) },
	     );
    $self->{EVENT_TIMER} = Event->timer(interval => $self->{HEARTBEAT},
					cb => sub { $self->_timeout_callback },
				       );
}

sub _message_callback {
    my ($msg, $self) = @_;

    $self->{STATUS} = 'busy';

    if ($self->{EVENT_TIMER}) {
	$self->{EVENT_TIMER}->cancel
    }

    # set status with the queue manager
    $self->_notify('working');

    my $content = $self->{SERIALIZER}->deserialize($msg->{BODY});

    my $body = $self->{SERIALIZER}->deserialize($content->{body});

    $self->{METRICS}->{num_messages}++;

    $self->{SESSION}->publish($content->{originator},
			      $self->{SERIALIZER}->serialize({
							      type => "ack",
							     }));

    # use eval so the loop doesn't die if there's bad code
    eval {
	$self->{CALLBACK}->($self,
			    $content->{originator},
			    $body);
    };
    if ($@) {
	# @@@@ may want some more sophisticated handling here.
	carp $@;
    }
    # ready for next task
    $self->{STATUS} = 'ready';
    $self->_notify('ready');

    if ($self->{EVENT_TIMER}) {
	$self->{EVENT_TIMER} = Event->timer(interval => $self->{HEARTBEAT},
					    cb => sub { $self->_timeout_callback },
					   );
    }
}

sub _timeout_callback {
    my ($self) = @_;

#    sqwlog "TIMEOUT\n";

    if ($self->{STATUS} eq 'ready') {
	# ping the sqm so it knows we're available
	$self->_notify('ready');
    }
#    return if $self->{TERMINATED};
}

=item B<respond>

    $worker->respond($originator, $result);

If the worker wants to send a reply back to the originator of the
request (e.g. in a request-reply environment).  $originator is the
Spread private mailbox address sent to the callback function.
$result is a reference to a Perl hash.

=cut

sub respond {
    my ($self, $originator, $payload) = @_;

    sqwlog "Responding to $originator\n";
    $self->{SESSION}->publish($originator,
			      $self->{SERIALIZER}->serialize({
							      type => "response",
							      body => $payload
							     }));
#    $self->_notify('ready');
}


sub _status {
    my ($self, $status) = @_;

    return $self->{SERIALIZER}->serialize({ status => $status });
}

sub _notify {
    my ($self, $status) = @_;

    sqwlog "Advising $self->{QUEUE} queue manager: $status\n";
    $self->{SESSION}->publish($self->{WQNAME},
			      $self->_status($status));
}

sub acknowledge {
    my ($self, $originator) = @_;

    sqwlog "Acknowledgement to $originator\n";
    # end-to-end delivery acknowledgement back to the originator
    $self->{SESSION}->publish($originator,
			      $self->_status('working'));
}

=item B<terminate>

    $worker->terminate;

Advises the queue manager that this worker is no longer available for
task assignment.  This will cause the runloop to exit.

Note that this is not automatically called on process termination.
This means that the sqm might not realize that the worker is gone
until its next automatic internal review cycle in a few seconds.
For best messaging performance, it is important to notify the sqm
as quickly as possible when a worker aborts.

=cut

sub terminate {
    my $self = shift;

    sqwlog "Terminating $self->{QUEUE}\n";
    $self->_notify('terminate');
    $self->{TERMINATED}++;
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
  L<Data::Serializer>
  L<Event>

=cut
