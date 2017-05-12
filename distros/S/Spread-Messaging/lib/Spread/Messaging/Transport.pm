package Spread::Messaging::Transport;

use 5.008;
use strict;
use warnings;

use Spread;
use Spread::Messaging::Exception;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Spread::Transport ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    UNRELIABLE_MESS
    RELIABLE_MESS
    FIFO_MESS
    CAUSAL_MESS
    AGREED_MESS
    SAFE_MESS
    REGULAR_MESS
    SELF_DISCARD
    DROP_RECV
    REG_MEMB_MESS
    TRANSITION_MESS
    CAUSED_BY_JOIN
    CAUSED_BY_LEAVE
    CAUSED_BY_DISCONNECT
    CAUSED_BY_NETWORK
    MEMBERSHIP_MESS
    ACCEPT_SESSION
    ILLEGAL_GROUP
    ILLEGAL_MESSAGE
    ILLEGAL_SERVICE
    ILLEGAL_SESSION
    ILLEGAL_SPREAD
    CONNECTION_CLOSED
    COULD_NOT_CONNECT
    BUFFER_TOO_SHORT
    GROUPS_TOO_SHORT
    MESSAGE_TOO_LONG
    REJECT_ILLEGAL_NAME
    REJECT_NOT_UNIQUE
    REJECT_NO_NAME
    REJECT_QUOTA
    REJECT_VERSION
);

our $VERSION = '0.03';

# -------------------------------------------------------------------------
# public methods
# -------------------------------------------------------------------------

sub new {
    my $proto = shift;
    my %params = @_;

    my $self = {};
    my @foo = split(/\//, $0);
    my $class = ref ($proto) || $proto;

    # Initialize variables - these are defaults.

    $self->{port} = '4803';
    $self->{timeout} = '5';
    $self->{host} = 'localhost';
    $self->{service_type} = SAFE_MESS;
    $self->{private_name} = sprintf("%0s%05d", 
                                    substr($ENV{USER} || pop @foo, 0, 5), $$);

    # Parse named parameters, these may overwrite, or suppliment the above.

    my ($k, $v);
    local $_;

    if (defined ($v = delete $params{'-port'})) {

        $self->{port} = $v;

    }

    if (defined ($v = delete $params{'-host'})) {

        $self->{host} = $v;

    }

    if (defined ($v = delete $params{'-private_name'})) {

        $self->{private_name} = $v;

    }

    if (defined ($v = delete $params{'-timeout'})) {

        $self->{timeout} = $v;

    }

    if (defined ($v = delete $params{'-service_type'})) {

        $self->{service_type} = $v;

    }

    bless($self, $class);

    # Open the connection

    $self->connect();

    return $self;

}

sub connect {
    my ($self) = @_;

    my $connection;

    $connection->{spread_name} = $self->{port} . '@' . $self->{host};
    $connection->{private_name} = $self->{private_name};

    undef $sperrno;
    ($self->{mailbox}, $self->{private_group}) = Spread::connect($connection);
    if ($sperrno) {
        
        Spread::Messaging::Exception->throw(
            errno => $sperrno + 0,
            errstr => $sperrno
        );

    }

}

sub join_group {
    my ($self, $groups) = @_;

    my @groupss = split(',', $groups);

    foreach my $group (@groupss) {

        undef $sperrno;
        Spread::join($self->{mailbox}, $group);
        if ($sperrno) {

            Spread::Messaging::Exception->throw(
                errno => $sperrno + 0,
                errstr => $sperrno
            );

        }

    }

}

sub leave_group {
    my ($self, $groups) = @_;

    my @groupss = split(',', $groups);
    
    foreach my $group (@groupss) {

        undef $sperrno;
        Spread::leave($self->{mailbox}, $group);
        if ($sperrno) {

            Spread::Messaging::Exception->throw(
                errno => $sperrno + 0,
                errstr => $sperrno
            );

        }

    }

}

sub poll {
    my ($self) = @_;

    undef $sperrno;
    my $size = Spread::poll($self->{mailbox});
    if ($sperrno) {

        Spread::Messaging::Exception->throw(
            errno => $sperrno + 0,
            errstr => $sperrno
        );

    }

    return $size;

}

sub send {
    my ($self, $group, $message, $type) = @_;

    undef $sperrno;
    Spread::multicast($self->{mailbox}, $self->{service_type}, $group, $type, $message);
    if ($sperrno) {

        Spread::Messaging::Exception->throw(
            errno => $sperrno + 0,
            errstr => $sperrno
        );

    }

}

sub recv {
    my ($self) = @_;

    my ($data, $content);

    undef $sperrno;
    my ($service_type, $sender, $groups, $msg_type, $endian, $message) =
        Spread::receive($self->{mailbox}, $self->{timeout});
    if ($sperrno) {

        Spread::Messaging::Exception->throw(
            errno => $sperrno + 0,
            errstr => $sperrno
        );

    }

    $data = $message;

    if ($service_type & MEMBERSHIP_MESS) {

        if ($service_type & REG_MEMB_MESS) {

            $data = _decode_reg_memb_mess($self, $service_type, $message);

        } elsif ($service_type & TRANSITION_MESS) {

            $data = _decode_transition_mess($self, $service_type, $message);

        }

    }

    return $service_type, $sender, $groups, $msg_type, $endian, $data;

}

sub disconnect {
    my ($self) = @_;

    undef $sperrno;
    Spread::disconnect($self->{mailbox});
    if ($sperrno) {

        Spread::Messaging::Exception->throw(
            errno => $sperrno + 0,
            errstr => $sperrno
        );

    }

}

# -------------------------------------------------------------------------
# public accessors
# -------------------------------------------------------------------------

sub fd {
    my ($self) = @_;

    return($self->{mailbox});

}

sub service_type {
    my ($self, $p) = @_;

    $self->{service_type} = $p if ((defined $p) && 
                                   (($p == UNRELIABLE_MESS) ||
                                    ($p == RELIABLE_MESS) ||
                                    ($p == FIFO_MESS) ||
                                    ($p == CAUSAL_MESS) ||
                                    ($p == AGREED_MESS) ||
                                    ($p == SAFE_MESS)));
    return($self->{service_type});

}

sub timeout {
    my ($self, $p) = @_;

    $self->{timeout} = $p if defined $p;
    return($self->{timeout});

}

sub host {
    my ($self, $p) = @_;

    $self->{host} = $p if defined $p;
    return($self->{host});

}

sub port {
    my ($self, $p) = @_;

    $self->{port} = $p if defined $p;
    return($self->{port});

}

sub private_group {
    my ($self, $p) = @_;

    $self->{private_group} = $p if defined $p;
    return($self->{private_group});

}

sub private_name {
    my ($self, $p) = @_;

    $self->{private_name} = $p if defined $p;
    return($self->{private_name});

}

DESTROY {
    my ($self) = @_;

    Spread::disconnect($self->{mailbox}) if defined $self->{mailbox};

}

# -------------------------------------------------------------------------
# Private methods
# -------------------------------------------------------------------------

sub _decode_reg_memb_mess {
    my ($self, $service_type, $message) = @_;

    # Try to decode the message buffer. This really should
    # be done in the xs code, not here in perl. And the returned
    # buffer doesn't match what the Spread C API documentation says 
    # should be there. Arrgh...
    #
    # The first 12 bytes is the group ID, the remainer of the
    # buffer is the current private group of this session. 
    #
    # It would have been really nice if the buffer had been broken up into
    # delimited fields, of which the first three fields would be the group ID, 
    # the next field the private group, the next field a count 
    # and the rest the fields were the actual names of the group memebers,
    # the number of whom would have matched the count. This would have
    # been a nice approximation of the actual C data structure. 
    #
    # Oh well, such is life.

    my @data;

    if (($service_type & CAUSED_BY_JOIN) || 
        ($service_type & CAUSED_BY_LEAVE) ||
        ($service_type & CAUSED_BY_DISCONNECT)) {

        @data = unpack("I[3]A*", $message);

    } elsif ($service_type & CAUSED_BY_NETWORK) {

        @data = unpack("I[3]A*", $message);

    }

    return \@data;

}

sub _decode_transition_mess {
    my ($self, $service_type, $message) = @_;

    # Try to decode the message buffer. This really should
    # be done in the xs code, not here in perl. 

    my @data = unpack("I3", $message);

    return \@data;

}

1;

__END__

=head1 NAME

Spread::Messaging::Transport - A Perl extension to the Spread Group Communications toolkit

=head1 SYNOPSIS

This module attempts to provide a simple and easy to use interface to the 
Spread Group Communications toolkit. It is a thin, object oriented layer 
over the toolkits Spread.pm.

=head1 DESCRIPTION

Your application could be as simple as this, to receive messages from a 
Spread network.

  use Spread::Messaging::Transport;

  $spread = Spread::Messaging::Transport->new();
  $spread->join_group("test");

  for (;;) {

      if ($spread->poll()) {

         my ($service_type, $sender, $groups, 
             $msg_type, $endian, $message) = $spread->recv();

         do_something($service_type, $sender, $groups, 
                      $msg_type, $endian, $message);

      }

      sleep(1);

  }

Or, your application could be as simple as this, to send messages over a 
Spread network.

  use Spread::Messaging::Transport;

  $spread = Spread::Messaging::Transport->new();
  $spread->join_group("test");

  for (;;) {

      $buffer = readline();
      $spread->send("test", $buffer, 0);

  }

But of course, this is never the case. This module will allow you to build
your application as you see fit. All errors are thrown as a 
Spread::Messaging::Exception object using Exception::Class as the base class.
No structure is enforced upon the messages being sent. This module is 
designed for maximum flexibility.

=head1 METHODS

=over 4

=item  new

This method inializes the object. Reasonable defaults are provided during
this initializaion. By default, your program will connect to a Spread 
server on port 4803, on host "localhost", with a timeout of 5 seconds, 
along with a self generated private name, using a message type of 
"SAFE_MESS". To override these defaults you can use the following 
named parameters.

=over 4

=item -port

This allows you to indicate which port number to use.

=item -host

This allows you to choose which host the Spread server is located on.

=item -timeout

This allows you to select a timeout.

=item -service_type

This allows you to choose a differant service type. The following types
are valid:

=over 4

 UNRELIABLE_MESS
 RELIABLE_MESS
 FIFO_MESS
 CAUSAL_MESS
 AGREED_MESS
 SAFE_MESS

=back

Please see the Spread documentation for the meaning of these service types.

=item -private_name

This allows you to choose a specifc private name for your private mailbox. 
This name can be used for unicast messages.

=item Example

 $spread = Spread::Messaging::Transport->new(
      -port => "8000",
      -timeout => "10",
      -host => "spread.example.com",
      -private_name => "mymailbox"
 );

=back

=item connect

This method allows you to connect to a Spread server. It is useful if you
have disconnected from your current server. You may also use this method to 
reconnect to another Spread server. It does not create a new object.

=over 4

=item Examples:

 $spread->connect();

 or

 $spread->disconnect();
 $spread->host("spread.example.com");
 $spread->connect();

=back

=item disconnect

This method will disconnect from your current Spread server. It does not
destroy the spread object.

=over 4

=item Example

 $spread->disconnect();

=back

=item poll

This methed allows you to check for pending messages. The number of 
message bytes is returned, when messages are pending.

=over 4

=item Example

 $size = $spread->poll();
 do_something() if $size;

=back

=item join_group

This allows you to join one or more Spread groups. To receive any multicast 
messages you need to join a group. The group may be a comma delimted 
list of names.

=over 4

=item Example

 $spread->join_group("test1,test2");

=back

=item leave_group

This allows you to leave a Spread group. Once you leave a group, you will
stop receiving any multicast messages for that group. A comma delimted list 
may be used to leave more then one group.

=over 4

=item Example

 $spread->leave_group("test1");

=back

=item send

This allows you to send messages to a group. You may only send a message to 
one group at a time. A group may be a either a public group or a private 
mailbox. The third parameter is an application specific message type. This
allows the application to segregate message types.

=over 4

=item Examples:

 $spread->send("test1", "This is cool", 0);

 or

 $msg->{command} => "jump";
 $msg->{command}->{parameter} => "how high";
 $data = objToJson($msg);
 $spread->send("test2", $data, 1);

=back

=item recv

This method allows you to receive messages from the Spread server. The method
will wait the default timeout period if no messages are pending. It returns
five data items. Those items are as follows:

=over 4

=item $service_type 

This is the service type of the recieved message. This module tries to 
decode the message depending on the service type. This allows the application
to do whatever with the message.

=item $sender

This is the sender of the message. The sender is ususally the mailbox the
message originated from. But may contain other data depending on the 
service type.

=item $groups

This is the groups the message was sent too.

=item $message_type

This is the application specific message type. It is defined when the message
was sent.

=item $endinan

This indicates if the endianness of the sending platform is differant from
the receiving platform.

=item $message

This is the acutal data that was sent from the sender. Depending on the
service type is may also contain one the following types of data.

=over 4

If the service type was a MEMBERSHIP_MESS with a sub type of REG_MEMB_MESS 
the message will contain the following array:

=over 4

If the sub type is CAUSED_BY_LEAVE, CAUSED_BY_JOIN or CAUSED_BY_DISCONNECT
the first three array elements are the group id, the last element is the
group name.

If the sub type is CAUSED_BY_NETWORK, the first three array elements is the
group id, the next one is the number of elements for the groups effected, 
while the last element is those groups.

=back

If the service type was a MEMBERSHIP_MESS with a sub type of TRANSITIONAL_MESS
the message will contain an array with the elements containing the 
group id.

=back

=item Example

 my ($service_type, $sender, 
     $groups, $message_type, $endian, $message) = 
       $spread->recv();

 if ($service_type & REGULAR_MESS) {

     handle_regular_message($service_type, $sender, 
                            $groups, $message_type, 
                            $endian, $message);

 } else { 

     handle_membership_message($service_type, $sender, 
                               $groups, $message_type, 
                               $endian, $message);

 }

=back

See the documentation for the Spread C API to fully understand the service
types and what data can be returned for each type.

=back

=head1 ACCESSORS

=over 4

=item  fd

This returns the file descriptor for the Spread connection. This
descriptor can be used with select() or one of the event handling modules 
to wait for messages from the server.

=over 4

=item Example

 $fd = $spread->fd;

=back

=item private_group

This returns the name of your private group.

=over 4

=item Example

 $private_group = $spread->private_group;

=back

=item port

This returns or sets the port number for the Spread server.

=over 4

=item Example

 $port = $spread->port;
 $spread->port("8000");

=back

=item host

This returns or sets the host name for the Spread server.

=over 4

=item Example

 $host = $spread->host;
 $spread->host("spread.example.com");

=back

=item timeout

This returns or sets the timeout value for your Spread connection.

=over 4

=item Example

 $timeout = $spread->timeout;
 $spread->timeout("10");

=back

=item private_name

This returns or sets the private name for your Spread connection.

=over 4

=item Example

 $name = $spread->private_name;
 $spread->private_name("myname");

=back

=item service_type

This returns or sets the service type of the Spread connection. 

=over 4

=item Example

 $service_type = $spread->service_type;
 $spread->service_type("SAFE_MESS");

=back

=back

=head1 EXPORTS

This module exports the constants that Spread.pm exposes. This is to allow
your application access to those constants.

=head1 SEE ALSO

 Spread::Messaging
 Spread::Messaging::Content

There are several other modules located on CPAN that already handle the Spread
Group Communication toolkit. They are:

=over 4

=item Spread.pm

This module is provided by the Spread toolkit to enable basic 
connectivity to a Spread server. It works, the interface is smiliar to
the C API and you need to do all of the heavy hitting on your own.

=item Spread::Message

Another wrapper module for Spread.pm. Please see this modules 
documentation for usage.

=item Spread::Session

Another wrapper modules for Spread.pm. This module is the base for these 
modules:

=over 4

 Spread::Queue
 Spread::Queue::Fifo
 Spread::Queue::Sender
 Spread::Queue::Worker
 Spread::Queue::Manager
 Spread::Queue::ManagedWorker

=back

Please read the documentation for these modules to see how they interact.

=item Messaging::Courier

Another wrapper module for Spread.pm. Please see this modules  
documentation for usage.

You also need to read the Spread documentation located at www.spread.org.
This is the definative description on what the Spread system is all about.
And should be considered mandatory reading for anybody attempting to use the
toolkit.

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesetb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
