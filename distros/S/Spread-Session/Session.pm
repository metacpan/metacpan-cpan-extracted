package Spread::Session;

=head1 NAME

Spread::Session - OO wrapper for Spread messaging toolkit

=head1 SYNOPSIS

  use Spread::Session;

  my $session = new Spread::Session(
			MESSAGE_CALLBACK => \&message_callback,
			ADMIN_CALLBACK   => sub {},
				   );

  $session->subscribe("mygroup");
  $session->publish("othergroup", $message);

  $session->receive($timeout, $extra_param);

  sub message_callback {
    my ($message_info, $extra_param) = @_;
    # do something
    return $message_info->{BODY};
  }

=head1 DESCRIPTION

Wrapper module for Spread.pm, providing an object-oriented interface
to the Spread messaging toolkit.  The existing Spread.pm package is
a straightforward functional interface to the Spread C API.

A session represents a connection to a Spread messaging daemon.  The
publish and subscribe functions are for communication via spread groups.

Handling of incoming messages is supported via callbacks; the receive()
method does not directly return the incoming message parameters to the
calling code.

=head2 METHODS

Most methods check the value of the Spread error code, $sperrno, and
will die() if this value is set.

=cut

use 5.005;
use strict;
#use warnings;
use Carp;
use Spread;

use vars qw($VERSION);
$VERSION = '0.4';

my $DEFAULT_TIMEOUT = 5;

BEGIN {
    # don't make Spread::Session dependent on Log::Channel, but
    # use it if it's available.

    my ($sslog, $msglog);
    if (defined eval { require Log::Channel }) {
	$sslog = new Log::Channel;
	$msglog = new Log::Channel("message");
    } else {
	$sslog = sub {};
	$msglog = sub {};
    }

    sub sslog { $sslog->(@_) }
    sub msglog { $msglog->(@_) }
}


=item B<new>

  my $session = new Spread::Session(private_name => 'foo',
                                    spread_name => '4444@remotenode',
	#optional		    MESSAGE_CALLBACK => \&my_msg_callback,
	#optional		    ADMIN_CALLBACK => \&my_admin_callback,
	#optional		    TIMEOUT_CALLBACK => \&my_timeout_callback,
	#optional		    TIMEOUT => 5,
				   );

Establish a connection to a Spread messaging daemon at the host and
port specified in the 'spread_name' parameter.  Default value is
4803@localhost.

If 'private_name' is not provided, Spread will generate a unique private
address based on process id and hostname.  If a value is provided for this
parameter, you must ensure uniqueness.

Provided MESSAGE_CALLBACK and ADMIN_CALLBACK coderefs will be invoked
with a reference to a hash containing the components of the incoming
message in fields named SERVICE_TYPE, SENDER, GROUPS (arrayref),
MESSAGE_TYPE, ENDIAN, and BODY.  A reference back to the Spread::Session
object is provided in SESSION.  Any other parameters provided in the
receive() method call will be passed through to the callback as well.

The TIMEOUT parameter overrides the built-in 5-second default timeout
for the receive() call.

=cut

sub new {
    my $proto = shift;
    my $class = ref ($proto) || $proto;

    my %config = @_;

    if (!$config{private_name}) {
	my @foo = split(/\//, $0);
	$config{private_name} = sprintf ("%0s%05d",
					 substr($ENV{USER} || pop @foo, 0, 5),
					 $$);
    }
    $config{spread_name} = "4803\@localhost" unless $config{spread_name};

    undef $sperrno;
    my ($mailbox, $private_group) = Spread::connect(\%config);
    croak "Spread::connect failed: $sperrno" if $sperrno;
    sslog "Spread connection established as $private_group\n";

    my $self = \%config;

    $self->{MAILBOX} = $mailbox;
    $self->{PRIVATE_GROUP} = $private_group;

    $self->{MESSAGE_CALLBACK} ||= \&_message_callback;
    $self->{ADMIN_CALLBACK} ||= \&_admin_callback;
    $self->{TIMEOUT_CALLBACK} ||= \&_timeout_callback;

    $self->{TIMEOUT} ||= $DEFAULT_TIMEOUT;

    bless $self, $class;
    return $self;
}

=item B<callbacks - DEPRECATED>

  $session->callbacks(message => \&message_callback,
                      admin => \&admin_callback,
                      timeout => \&timeout_callback);

Define application callback functions for regular inbound messages
on subscribed groups, administrative messages regarding subscribed
groups (e.g. membership events), and timeouts (cf. receive).

If no value is provided for any one of these events, a trivial stub is
provided by Spread::Session.

=cut

sub callbacks {
    my $self = shift;

    my %callbacks = @_;
    $self->{OLD_CALLBACKS}->{MESSAGE} = $callbacks{message} if $callbacks{message};
    $self->{OLD_CALLBACKS}->{ADMIN} = $callbacks{admin} if $callbacks{admin};
    $self->{OLD_CALLBACKS}->{TIMEOUT} = $callbacks{timeout} if $callbacks{timeout};
}


=item B<subscribe>

  $session->subscribe("mygroup", ...);

Inform Spread that a copy of any message published to the named group(s)
should be dispatched to this process.

=cut

sub subscribe {
    my $self = shift;

    undef $sperrno;
    foreach my $group (@_) {
	Spread::join($self->{MAILBOX}, $group);
	croak "Spread::join failed: $sperrno" if $sperrno;

	sslog "Joined group $group\n";
    }
}

=item B<publish>

  $session->publish("othergroup", $message);

Transmit a message to the specified group.

$message is assumed to be a string; serialization of other data types
is not provided here.

=cut

sub publish {
    my $self = shift;
    my ($group, $message) = @_;

    undef $sperrno;
    Spread::multicast($self->{MAILBOX},		# mbox
		      SAFE_MESS,		# service_type
		      $group,			# groups (just one)
		      0,			# message type
		      $message);		# message
    croak "Spread::multicast failed: $sperrno" if $sperrno;

    msglog "Sent message to $group: ", length $message, " bytes\n";
}

=item B<poll>

  my $msize = $session->poll;

Non-blocking check to see if a message is available on any subscribed
group (including this session's private mailbox).  Returns the size of
the first pending message.  A zero indicates no message is pending.

=cut

sub poll {
    my $self = shift;

    undef $sperrno;
    my $msize = Spread::poll($self->{MAILBOX});
    croak "Spread::poll failed: $sperrno" if $sperrno;

    return $msize;
}

=item B<receive>

  $session->receive($timeout, $args...);

Waits for $timeout seconds for a message to arrive on any subscribed
group (including this session's private mailbox).  If a regular message
arrives, it is delivered to the message callback defined above.  If a
Spread administrative message arrives (e.g. a group membership notification),
it is transmitted to any admin callback that has been installed.  If no
message arrives, the timeout callback is called, if any.

Additional optional parameters may be provided to receive().  These will
be passed along to the callback routines.

=cut

sub receive {
    my $self = shift;
				# a 0-sec timeout is not the same as undef
    my $timeout = defined $_[0] ? shift : $self->{TIMEOUT};

    $sperrno = 0;
    my ($service_type, $sender, $groups, $message_type, $endian, $message) =
      Spread::receive($self->{MAILBOX}, $timeout);

    if ($sperrno == 3) {
	# timeout
	if ($self->{OLD_CALLBACKS}->{TIMEOUT}) {
	    return $self->{OLD_CALLBACKS}->{TIMEOUT}->(@_);
	} else {
	    return $self->{TIMEOUT_CALLBACK}->(@_);
	}
    }

    # any other error from Spread::receive besides timeout is fatal
    # *** MAKE SURE THIS MAKES SENSE ***

    croak "Spread::receive failed: $sperrno" if $sperrno;

    msglog "Received message from $sender: ", length $message, " bytes\n";

    my %message_container = (
 			     SERVICE_TYPE => $service_type,
 			     SENDER => $sender,
 			     GROUPS => $groups,
 			     MESSAGE_TYPE => $message_type,
 			     ENDIAN => $endian,
			     SESSION => $self,
 			     BODY => $message,
 			    );

    if ($service_type & REGULAR_MESS) {
	if (defined $self->{OLD_CALLBACKS}->{MESSAGE}) {
	    return $self->{OLD_CALLBACKS}->{MESSAGE}->($sender,
						       $groups,
						       $message,
						       @_);
	} else {
	    return $self->{MESSAGE_CALLBACK}->(\%message_container,
					       @_);
	}
    } else {
	if (defined $self->{OLD_CALLBACKS}->{ADMIN}) {
	    return $self->{OLD_CALLBACKS}->{ADMIN}->($service_type,
						     $sender,
						     $groups,
						     $message,
						     @_);
	} else {
	    return $self->{ADMIN_CALLBACK}->(\%message_container,
					     @_);
	}
    }
}

=head2 CALLBACKS

  sub my_message_callback {
    my ($sender, $groups, $message, @args) = @_;
  }

  sub my_admin_callback {
    my ($service_type, $sender, $groups, $message, @args) = @_;
  }

  sub my_timeout_callback {
    my (@args) = @_;
  }

Some trivial default callbacks (dump incoming message details to stdout)
are provided by Spread::Session.  Your application should override all
of these.

=cut

sub _message_callback {
    my ($container, @args) = @_;

    sslog "SENDER: $container->{SENDER}\n";
    sslog "GROUPS: [", join(",", @{$container->{GROUPS}}), "]\n";
    sslog "MESSAGE TYPE: $container->{MESSAGE_TYPE}\n";
    sslog "REG_MESSAGE: $container->{BODY}\n\n";
}


sub _admin_callback {
    my ($container, @args) = @_;

    if ($container->{SERVICE_TYPE} & TRANSITION_MESS) {
	sslog "> Transition message for $container->{SENDER}\n";
    } elsif ($container->{SERVICE_TYPE} & REG_MEMB_MESS) {
	sslog ("> New member(s) for $container->{SENDER}: ",
	       join(",", @{$container->{GROUPS}}),
	       "\n");
    } elsif ($container->{SERVICE_TYPE} & MEMBERSHIP_MESS) {
	sslog ("> Self-leave message for $container->{SENDER}:",
	       join(",", @{$container->{GROUPS}}),
	       "\n");
    }
}


sub _timeout_callback {
#    my @args = @_;
#    print "...timeout!\n";
}


=item B<err>

  my $sperrno = $session->err;

Retrieve the value of the current Spread error, if any.

=cut

sub err {
    return $sperrno;
}


DESTROY {
    my $self = shift;
    Spread::disconnect($self->{MAILBOX});
    sslog "Spread session $self->{PRIVATE_GROUP} disconnected\n";
}

1;


=head1 AUTHOR

Jason W. May <jmay@pobox.com>

Joshua Goodall <joshua@roughtrade.net> maintains the FreeBSD package for
this module.

=head1 COPYRIGHT

Copyright (C) 2002 Jason W. May.  All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

The license for the Spread software can be found at 
http://www.spread.org/license

=head1 SEE ALSO

  L<Spread>
  L<Log::Channel>

=cut
