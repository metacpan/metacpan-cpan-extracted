##########################################################################
#
# Module template
#
##########################################################################
package Pots::MessageQueue;

##########################################################################
#
# Modules
#
##########################################################################
use threads;
use threads::shared;

use strict;

use base qw(Pots::SharedObject);

use Thread::Queue;
use Storable qw(freeze thaw);

##########################################################################
#
# Global variables
#
##########################################################################

##########################################################################
#
# Private methods
#
##########################################################################

##########################################################################
#
# Public methods
#
##########################################################################
sub new {
    my $class = shift;

    my $self = $class->SUPER::new();

    lock(%{$self});

    $self->{_queue} = Thread::Queue->new();

    return $self;
}

sub postmsg {
    my $self = shift;
    my $msg = shift;

    my $smsg = freeze($msg);
    my $q : shared = $self->{_queue};
    $q->enqueue($smsg);
}

sub getmsg {
    my $self = shift;

    my $q : shared = $self->{_queue};

    my $smsg = $q->dequeue();

    return thaw($smsg);
}

sub nbmsg {
    my $self = shift;

    my $q : shared = $self->{_queue};

    return $q->pending();
}

1; #this line is important and will help the module return a true value
__END__

=head1 NAME

Pots::MessageQueue - Perl ObjectThreads thread safe message queue

=head1 SYNOPSIS

    use threads;

    use Pots::MessageQueue;
    use Pots::Message;

    my $q = Pots::MessageQueue->new();

    sub thread_proc {
        my $rmsg;
        my $quit = 0;

        while (!$quit) {
            $rmsg = $q->getmsg();

            for ($rmsg->type()) {
                if (/quit/) {
                    $quit = 1;
                } else {
                    print "thread received a message of type $_\n";
                }
            }
        }
    }

    my $th = threads->new("thread_proc");

    my $msg = Pots::Message->new('type');
    $q->postmsg($msg);

    $msg->type('quit');
    $q->postmsg($msg);

=head1 DESCRIPTION

C<Pots::MessageQueue> objects allows threads to communicate using messages.
It is built upon a standard C<Thread::Queue> object, and uses C<Storable> to
serialize and deserialize messages between threads.

=head1 METHODS

=over

=item new ()

Construct a new, shared, message queue object.

=item postmsg ($msg)

Posts a message in the queue, so that a thread can retrieve it using "getmsg()".

=item getmsg ()

Retrieves a message from the queue. If no message is available, this method will
wait until a message becomes available.

=item nbmsg ()

Returns the number of messages waiting in the queue.

=back

=head1 AUTHOR and COPYRIGHT

Remy Chibois E<lt>rchibois at free.frE<gt>

Copyright (c) 2004 Remy Chibois. All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
