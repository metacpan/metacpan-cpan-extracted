package Spread::Messaging;

use 5.008;
use strict;
use warnings;

require Exporter;
use Spread::Messaging::Content;
use Spread::Messaging::Exception;

our @ISA = qw(Exporter Spread::Messaging::Content);

our $VERSION = '0.03';

our @EXPORT = qw(
 UNRELIABLE_MESS
 RELIABLE_MESS
 FIFO_MESS
 CAUSAL_MESS
 AGREED_MESS
 SAFE_MESS
);

# ------------------------------------------------------------------------
# public methods
# ------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{entity} = "";
    $self->{joined_groups} = undef;
    $self->{callback_private} = undef;
    $self->{callback_group} = undef;
    $self->{callback_join} = undef;
    $self->{callback_leave} = undef;
    $self->{callback_disconnect} = undef;
    $self->{callback_network} = undef;
    $self->{callback_transition} = undef;
    $self->{callback_other} = undef;

    return $self;

}

sub callbacks {
    my $self = shift;
    my %params = @_;

    my ($k, $v);
    local $_;

    if (defined($v = delete $params{'-private'})) {

        $self->{callback_private} = $v;

    }

    if (defined($v = delete $params{'-group'})) {

        $self->{callback_group} = $v;

    }

    if (defined($v = delete $params{'-join'})) {

        $self->{callback_join} = $v;

    }

    if (defined($v = delete $params{'-leave'})) {

        $self->{callback_leave} = $v;

    }

    if (defined($v = delete $params{'-disconnect'})) {

        $self->{callback_disconnect} = $v;

    }

    if (defined($v = delete $params{'-network'})) {

        $self->{callback_network} = $v;

    }

    if (defined($v = delete $params{'-transition'})) {

        $self->{callback_transition} = $v;

    }

    if (defined($v = delete $params{'-other'})) {

        $self->{callback_other} = $v;

    }

}

sub process {
    my ($self) = @_;

    $self->SUPER::recv();

    if ($self->is_regular_mess) {

        if ($self->is_private_mess) {

            $self->entity($self->sender);
            return $self->{callback_private}->($self) 
                   if defined $self->{callback_private};

        } else {

            $self->entity($self->sender);
            return $self->{callback_group}->($self)
                   if defined $self->{callback_group};

        }

    } elsif ($self->is_membership_mess) {

        if ($self->is_reg_memb_mess) {

            if ($self->is_caused_by_join) {

                $self->entity(@{$self->message}[3]);
                _do_groups($self);
                return $self->{callback_join}->($self) 
                       if defined $self->{callback_join};

            } elsif ($self->is_caused_by_leave) {

                $self->entity(@{$self->message}[3]);
                _do_groups($self);
                return $self->{callback_leave}->($self) 
                       if defined $self->{callback_leave};

            } elsif ($self->is_caused_by_disconnect) {

                $self->entity(@{$self->message}[3]);
                _do_groups($self);
                return $self->{callback_disconnect}->($self) 
                       if defined $self->{callback_disconnect};

            } elsif ($self->is_caused_by_network) {

                $self->entity("");
                return $self->{callback_network}->($self) 
                       if defined $self->{callback_network};

            }

        } elsif ($self->is_transition_mess) {

            $self->entity("");
            return $self->{callback_transition}->($self) 
                   if defined $self->{callback_transition};

        }

    } else {

        $self->entity("");
        return $self->{callback_other}->($self)
               if defined $self->{callback_other};

    }

}

# ------------------------------------------------------------------------
# public accessors
# ------------------------------------------------------------------------

sub entity {
    my ($self, $p) = @_;

    $self->{entity} = $p if defined $p;
    return($self->{entity});

}

sub groups_joined {
    my ($self) = @_;

    my @groups;

    foreach my $group (@{$self->{joined_groups}}) {

        push(@groups, $group->{name});

    }

    return @groups;

}

sub group_members {
    my ($self, $name) = @_;

    my @groups;

    foreach my $group (@{$self->{joined_groups}}) {

        if ($group->{name} =~ /$name/i) {

            @groups = split(',', $group->{members});
            return @groups;

        }

    }

    return undef;

}

# ------------------------------------------------------------------------
# private functions
# ------------------------------------------------------------------------

sub _do_groups {
    my ($self) = @_;

    my ($groups, $x);

    $x = 0;
    $groups->{name} = $self->sender;
    $groups->{members} = join(',', @{$self->group});

    foreach my $group (@{$self->{joined_groups}}) {

        if ($group->{name} eq $groups->{name}) {

            @{$self->{joined_groups}}[$x] = $groups;
            return;

        }

        $x++;

    }

    push(@{$self->{joined_groups}}, $groups);

}

1;

__END__

=head1 NAME

Spread::Messaging - A Perl extension to the Spread Group Communications toolkit

=head1 SYNOPSIS

This module attempts to provide a simple and easy to use interface to the 
Spread Group Communications toolkit. It is a thin, object oriented layer
over the toolkits Spread.pm. To use this module you also need Spread::Transport
and Spread::Content, which this module inherits from.

=head1 DESCRIPTION

To receive messages from a Spread network, your application could be as simple 
as this:

 use Spread::Messaging;

 sub handle_group {
    my $spread = shift;

    printf("Message: %s\n", $spread->message);

 }

 main: {

    my $spread;

    $spread = Spread::Messaging->new();
    $spread->join_group("test1");
    $spread->callbacks(-group => \&handle_group);

    for (;;} {

        if ($spread->poll()) {

            $spread->process();

        }

        sleep(1);

     }

 }

Or you could use an event module and do the following:

 use Event;
 use Spread::Messaging;

 sub handle_group {
    my $spread = shift;

    printf("Message: %s\n", $spread->message);

 }

 main: {

    my $spread;

    $spread = Spread::Messaging->new();
    $spread->join_group("test1");
    $spread->callbacks(-group => \&handle_group);

    Event->io(fd => $spread->fd, cb => sub { $spread->process(); });
    Event::loop();

 }

But of course, this is never the case. This module will allow you to build
your application as you see fit. All errors are signaled thru die(). The
errors are returned thru object accessors. No structure is enforced upon 
the messages being sent. This module is designed for maximum flexibility.

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

=item Example

 $spread = Spread::Messaging->new(
     -port => "8000",
     -timeout => "10",
     -host => "spread.example.com",
     -private_name => "mymailbox"
 );

=back

=item callbacks

This method defines how message types are handled. Each callback will handle
one type of message. If no callback is defined for a message type, the message
will be discarded. There is no "default" message handler. The following 
named parameters have meaning.

=over 4

=item -private

Use this callback if you want to handle private message exchanges. Private
messages are delivered to the mailbox defined by $spread->private_group.

=item -group

Use this callback if you want to handle any group messages. What groups you
receive messages from, is defined by your usage of $spread->join_group().

=item -join

Use this callback if you want to handle join messages from your groups. A 
message is sent whenever another entity joins a group.

=item -leave

Use this callback if you want to handle leave messages from your groups. A
message is sent whenever another entity leaves a group. The differance
between leaving and disconnecting is that "leave" is voluntary.

=item -disconnect

Use this callback if you want to handle disconnect messages from your groups. 
A message is sent whenever another entity disconnects from a group. The 
differance between leaving and disconnecting is that "disconnect" is 
involuntary.

=item -network

Use this callback if you want to handle network messages from your groups. 
This usually indicates a error within the Spread network.

=item -transition

Use this callback if you want to handle transistion messages from your groups. 
This usually indicates a state transititon within the Spread network.

=over 4

=item Example

 sub handle_private {
    my ($spread) = @_;

    printf("Private message recieved\n");

 }

 sub handle_group {
    my ($spread) = @_;

    if ($spread->group eq 'mygroup') {

        printf("Group message received from \"mygroup\"\n");

    }

 }

 $spread->callbacks(-private => \&handle_private,
                    -group => \&handle_group);

=back

=back

=item process

This method performs the actual message retrieval and dispatch depending on
message type. If no callbacks are defined, nothing is done and the message
is discarded.

=back

=head1 ACCESSORS

=over 4

=item entity

This method returns the entity that sent the message.

=item groups_joined

This accessor returns the current groups that your application has joined. 
The returned value is an array or undef if no groups have been joined yet.

=item group_members

This accessor returns the members of a group. This is an array.

=over 4

=item Example

 @groups = $spread->groups_joined;

 foreach my $group (@groups) {

     @members = $spread->group_members($group);

     foreach my $member (@members) {

         printf("%s is a member of %s\n", $member, $group);

     }

 }

=back

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

 Spread::Messaging::Transport
 Spread::Messaging::Content

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

You also need to read the Spread documentation located at www.spread.org.
This is the definative description on what the Spread system is all about.
And should be considered mandatory reading for anybody attempting to use the
toolkit.

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
