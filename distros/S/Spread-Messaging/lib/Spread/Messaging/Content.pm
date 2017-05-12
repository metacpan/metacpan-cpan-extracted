package Spread::Messaging::Content;

use 5.008;
use strict;
use warnings;

require Exporter;

use Spread::Messaging::Transport;
use Spread::Messaging::Exception;

our @ISA = qw(Exporter Spread::Messaging::Transport);

our @EXPORT = qw(
 UNRELIABLE_MESS
 RELIABLE_MESS
 FIFO_MESS
 CAUSAL_MESS
 AGREED_MESS
 SAFE_MESS
);

our $VERSION = '0.01';

# ------------------------------------------------------------------------
# Public methods
# ------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{message_type} = undef;
    $self->{sender} = undef;
    $self->{group} = undef;
    $self->{type} = 0;
    $self->{endian} = undef;
    $self->{message} = undef;

    return($self);

}

sub is_unreliable_mess {
    my ($self) = @_;

    return($self->message_type & UNRELIABLE_MESS);

}

sub is_reliable_mess {
    my ($self) = @_;

    return($self->message_type & RELIABLE_MESS);

}

sub is_fifo_mess {
    my ($self) = @_;

    return($self->message_type & FIFO_MESS);

}

sub is_causal_mess {
    my ($self) = @_;

    return($self->message_type & CAUSAL_MESS);

}

sub is_agreed_mess {
    my ($self) = @_;

    return($self->message_type & AGREED_MESS);

}

sub is_regular_mess {
    my ($self) = @_;

    return($self->message_type & REGULAR_MESS);

}

sub is_private_mess {
    my ($self) = @_;

    return ((index(@{$self->group}[0], '#') == 0) &&
            (index(@{$self->group}[0], '#', 1)));

}

sub is_self_discard_mess {
    my ($self) = @_;

    return($self->message_type & SELF_DISCARD);

}

sub is_reg_memb_mess {
    my ($self) = @_;

    return($self->message_type & REG_MEMB_MESS);

}

sub is_transition_mess {
    my ($self) = @_;

    return($self->message_type & TRANSITION_MESS);

}

sub is_safe_mess {
    my ($self) = @_;

    return($self->message_type & SAFE_MESS);

}

sub is_caused_by_join {
    my ($self) = @_;

    return($self->message_type & CAUSED_BY_JOIN);

}

sub is_caused_by_leave {
    my ($self) = @_;

    return($self->message_type & CAUSED_BY_LEAVE);

}

sub is_caused_by_disconnect {
    my ($self) = @_;

    return($self->message_type & CAUSED_BY_DISCONNECT);

}

sub is_caused_by_network {
    my ($self) = @_;

    return($self->message_type & CAUSED_BY_NETWORK);

}

sub is_membership_mess {
    my ($self) = @_;

    return($self->message_type & MEMBERSHIP_MESS);

}

sub is_self_leave_mess {
    my ($self) = @_;

    return(($self->message_type & CAUSED_BY_LEAVE) &&
           !($self->message_type & (REG_MEMB_MESS | TRANSITION_MESS)));

}

sub group {
    my ($self, $p) = @_;

    $self->{group} = $p if defined $p;
    return($self->{group});

}

sub type {
    my ($self, $p) = @_;

    $self->{type} = $p if defined $p;
    return($self->{type});

}

sub message {
    my ($self, $p) = @_;

    $self->{message} = $p if defined $p;
    return($self->{message});

}

sub message_type {
    my ($self, $p) = @_;

    $self->{message_type} = $p if defined $p;
    return($self->{message_type});

}

sub endian {
    my ($self, $p) = @_;

    $self->{endian} = $p if defined $p;
    return($self->{endian});

}

sub sender {
    my ($self, $p) = @_;

    $self->{sender} = $p if defined $p;
    return($self->{sender});

}

sub send {
    my ($self) = @_;

    $self->SUPER::send($self->group, $self->message, $self->type);

}

sub recv {
    my ($self) = @_;

    my ($message_type, $sender, $group,
        $type, $endian, $message) = $self->SUPER::recv($self);

    $self->message_type($message_type);
    $self->sender($sender);
    $self->group($group);
    $self->type($type);
    $self->endian($endian);
    $self->message($message);

}

1;

__END__

=head1 NAME

Spread::Messaging::Content - A Perl extension for the Spread Group Communications toolkit

=head1 SYNOPSIS

This module attempts to provide a simple and easy to use interface to the 
Spread Group Commuications toolkit. It builds upon the framework defined
within Spread::Messaging::Transport.

=head1 DESCRIPTION

Your application could be as simple as this.

 use Spread::Messaging::Content;

 $spread = Spread::Messaging::Content->new();
 $spread->join_group("test1");

 for (;;) {

     if ($spread->poll()) {

         $spread->recv();
         do_something();

     }

     sleep(1);

 }

 sub do_something {

     if ($spread->is_regular_mess) {

         printf("Service Type: %s\n", $spread->message_type);
         printf("Sender      : %s\n", $spread->sender);
         printf("Groups      : %s\n", join(',', @{$spread->group}));
         printf("Message Type: %s\n", $spread->type);
         printf("Endian      : %s\n", $spread->endian);
         printf("Message     : %s\n", $spread->message);

     } elsif ($spread->is_membership_mess) {

         printf("Service Type: %s\n", $spread->message_type);
         printf("Sender      : %s\n", $spread->sender);
         printf("Groups      : %s\n", join(',', @{$spread->group}));
         printf("Message Type: %s\n", $spread->type);
         printf("Endian      : %s\n", $spread->endian);
         printf("Message     : %s\n", join(',', @{$spread->message});

     }

 }

But of course, this is never the case. This module will allow you to build 
your application as you see fit. It builds upon the framework of 
Spread::Messaging::Transport by objectifing the returned messages. This allows you to
not to worry about the actual data structure of the message.

=head1 METHODS

=over 4

=item new

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

=item Example:

 $spread = Spread::Messaging::Content->new(
     -port => "8000",
     -timeout => "10",
     -host => "spread.example.com",
     -private_name => "mymailbox"
 );

=back

=item is_unreliabe_mess 

This returns true or false depending on the message type.

=item is_reliable_mess

This returns true or false depending on the message type.

=item is_fifo_mess

This returns true or false depending on the message type.

=item is_causal_mess

This returns true or false depending on the message type.

=item is_agreed_mess

This returns true or false depending on the message type.

=item is_regular_mess

This returns true or false depending on the message type.

=item is_private_mess

This returns true or false depending on the message type.

=item is_self_discard_mess

This returns true or false depending on the message type.

=item is_reg_memb_mess

This returns true of false depending on the message type.

=item is_transition_mess

This returns true or false depending on the message type.

=item is_safe_mess

This returns true or false depending on the message type.

=item is_caused_by_join

This returns true or false depending on the message type.

=item is_caused_by_leave

This returns true or false depending on the message type.

=item is_caused_by_leave

This returns true or false depending on the message type.

=item is_caused_by_disconnect

This returns true or false depending on the message type.

=item is_caused_by_network

This returns true or false depending on the message type.

=item is_membership_mess

This returns truw or false depending on the message type.

=item is_self_leave_mess

This returns true or false depending on the message type.

=item Example usage for the above

 $spread->recv();

 if ($spread->is_regular_mess) {

     if ($spread->is_private_mess) {

         printf("Private message from %s\n", @{$spread->group}[0]);

     } else {

         printf("Group message from %s\n", join(',', @{$spread->group}));

     }

 } elsif ($spread->is_membership_mess) {

     if ($spread->is_transitional_mess) {

         if ($spread->is_caused_by_leave) {

             printf("%s has left the group\n", $spread->group);

         } elsif ($spread->is_caused_by_join) {

             printf("%s has joined the group\n", $spread->group);

         } else {

            printf("Something unexpected has happend: %s\n", 
                   $spread->message_type);

         }

     }

 }

=item group

This method returns or sets the group.

=over 4

=item Example:

 $groups = $spread->group;
 $spread->group("test1,test2");

=back

=item type

This method returns or sets the application specific message type.

=over 4

=item Example

 $type = $spread->type;
 $spread->type("2");

=back

=item  message

This method returns or sets the message. No form or structure is imposed 
upon the message before it is sent.

=over 4

=item Example

 $message = $spread->message;
 $spread->message("this is neato");

=back

=item send

This allows you to send messages to a group. You may only send a message to
one group at a time. A group may be a either a public group or a private
mailbox. 

=over 4

=item Examples:

 $spread->group("test1");
 $spread->type("0");
 $spread->message("cooking with fire");
 $spread->send();

 or

 $msg->{command} => "jump";
 $msg->{command}->{parameter} => "how high";
 $data = objToJson($msg);
 $spread->group("test1");
 $spread->message($data);
 $spread->send();

=back

=item recv

This method allows you to receive messages from the Spread server. The method
will wait the default timeout period if no messages are pending. 

=over 4

=item Example:

 for (;;) {

     $spread->recv();

     if ($spread->is_regular_mess) {

         printf("Service Type: %s\n", $spread->message_type);
         printf("Sender      : %s\n", $spread->sender);
         printf("Groups      : %s\n", join(',', @{$spread->group}));
         printf("Message Type: %s\n", $spread->type);
         printf("Endian      : %s\n", $spread->endian);
         printf("Message     : %s\n", $spread->message);

     } elsif ($spread->is_membership_mess) {

         printf("Service Type: %s\n", $spread->message_type);
         printf("Sender      : %s\n", $spread->sender);
         printf("Groups      : %s\n", join(',', @{$spread->group}));
         printf("Message Type: %s\n", $spread->type);
         printf("Endian      : %s\n", $spread->endian);
         printf("Message     : %s\n", join(',', @{$spread->message});

     }

     sleep(1);

 }

=back

This example is not recommened, there are better ways to wait for 
messages from the network. One is to use Event and construct an event 
loop. For example:

 use Event;
 use Spread::Messaging::Content:

 sub put_output {

    $spread->recv();

    printf("Service Type: %s\n", $spread->message_type);
    printf("Sender      : %s\n", $spread->sender);
    printf("Groups      : %s\n", join(',', @{$spread->group}));
    printf("Message Type: %s\n", $spread->type);
    printf("Endian      : %s\n", $spread->endian);
    printf("Message     : %s\n", ref($spread->message) eq "ARRAY" ? 
                                     join(',', @{$spread->message}) :
                                     $spread->message);

 }

 $spread = Spread::Messaging::Content->new();
 $spread->join_group("test1");

 Event->io(fd => $spread->fd, cb => \&put_output);
 Event::loop();

=back

=head1 ACCESSORS

=over 4

=item endian

This accessor will return the endianness of the message.

=item sender

This accessor will return the sender of the message. Sender has differant
meanings depending on the messages service type.

=back

=head1 EXPORTS

This module exports the following constants from Spread.pm.

 UNRELIABLE_MESS
 RELIABLE_MESS
 FIFO_MESS
 CAUSAL_MESS
 AGREED_MESS
 SAFE_MESS

=head1 SEE ALSO

 Spread::Messaging
 Spread::Transport

There are several other modules located on CPAN that already handle the Spread
Group Communications toolkit. They are:

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

=back

You also need to read the Spread documentation located at www.spread.org.
This is the definative description on what the Spread system is all about.
And should be considered mandatory reading for anybody attempting to use the
toolkit.

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
