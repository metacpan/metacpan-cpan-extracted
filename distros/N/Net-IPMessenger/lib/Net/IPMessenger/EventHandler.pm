package Net::IPMessenger::EventHandler;

use warnings;
use strict;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub add_callback {
    my( $self, $name, $sub ) = @_;
    $self->{callback}->{$name} = $sub;
}

sub callback {
    my( $self, $name ) = @_;
    if ( exists $self->{callback}->{$name} ) {
        return $self->{callback}->{$name};
    }
    return;
}

1;
__END__

=head1 NAME

Net::IPMessenger::EventHandler - IP Messenger event handler base class.


=head1 SYNOPSIS

First of all, creates your event handler.

    package MyEventHandler;
    use base qw (Net::IPMessenger::EventHandler);

    sub BR_ENTRY {
        my( $self, $ipmsg, $user ) = @_;
        ...
    }

Next, add your event handler in the script.

    #!/usr/bin/perl

    use Net::IPMessenger;
    use MyEventHandler;

    my $ipmsg = Net::IPMessenger->new(
        ...
    );

    $ipmsg->add_event_handler( new MyEventHandler );

Then you receive a message, your handler method is invoked.


=head1 DESCRIPTION

This is a base event handler of Net::IPMessenger.

If you create method which name is same as 
%Net::IPMessenger::MessageCommand::COMMAND values name,
it will be invoked as you receive a message.

=head1 METHODS

=head2 new

Just creates object.

=head2 add_callback

    $self->add_callback( $name, \&sub );

Adds callback subroutine &sub and registers name $name.

=head2 callback

    goto $self->callback($name);

does callback $name.

=head1 SEE ALSO

L<Net::IPMessenger::RecvEventHandler>, L<Net::IPMessenger::ToStdoutEventHandler>

=cut
