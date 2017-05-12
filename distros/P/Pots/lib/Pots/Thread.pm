##########################################################################
#
# Module template
#
##########################################################################
package Pots::Thread;

##########################################################################
#
# Modules
#
##########################################################################
use threads;
use threads::shared;

use strict;

use base qw(Pots::SharedObject Pots::SharedAccessor);

use Thread::Semaphore;
use Pots::Semaphore;
use Pots::Message;
use Pots::MessageQueue;

Pots::Thread->mk_shared_accessors(
    qw(tid thread startcode stopped detached squeue rqueue startsem)
);

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
sub error {
    my $self = shift;

    print "Pots::Thread : error : ", join(' ', @_), "\n";
}

sub create_thread {
    my $self = shift;

    my $thread = threads->create($self->can("thread_proc"), $self, @_);
    $thread->detach() if $self->detached();
    $self->tid($thread->tid());
}

##########################################################################
#
# Public methods
#
##########################################################################
sub new {
    my $class = shift;
    my %p = @_;

    my $self = $class->SUPER::new();

    {
        lock(%{$self});
        $self->startsem(Pots::Semaphore->new(0));
        $self->squeue(Pots::MessageQueue->new());
        $self->rqueue(Pots::MessageQueue->new());
    }

    return undef unless $self->initialize(%p);

    $self->create_thread($p{args});

    return $self;
}

sub initialize {
    my $self = shift;
    my %p = @_;

    if (exists($p{detach}) && defined($p{detach})) {
        $self->detached(1) if ($p{detach} == 1);
    } else {
        $self->detached(0);
    }

    $self->stopped(0);
    $self->startcode(-1);
    $self->tid(-1);

    return 1;
}

sub postmsg {
    my $self = shift;

    if ($self->tid() == threads->tid()) {
        $self->squeue->postmsg(@_);
    } else {
        $self->rqueue->postmsg(@_);
    }
}

sub getmsg {
    my $self = shift;
    my $msg;

    if ($self->tid() == threads->tid()) {
        $msg = $self->rqueue->getmsg();
    } else {
        $msg = $self->squeue->getmsg();
    }

    return $msg;
}

sub sendmsg {
    my $self = shift;

    $self->postmsg(@_);
    return $self->getmsg();
}

sub start {
    my $self = shift;

    if ($self->startcode() == 1) {
        # Already started
        return 1;
    }

    if ($self->startcode() == 0) {
        # Already "started", in error
        return 0;
    }

    $self->startsem->up();

    my $msg = $self->getmsg();

    if ($msg->type() ne 'startcode') {
        $self->error("Did not received startcode message\n");
        return 0;
    }

    return $self->startcode($msg->get('startcode'));
}

sub stop {
    my $self = shift;
    my $ret = undef;

    return undef if ($self->stopped() || $self->startcode() != 1);

    $self->postmsg(Pots::Message->new('quit'));
    $self->stopped(1);

    threads->object($self->tid)->join()
        unless $self->detached();

    my $msg = $self->getmsg();

    return undef unless ($msg->type() eq 'stopped');

    return $msg->get('retval');
}

sub thread_proc {
    my $self = shift;
    my @args = @_;
    my $ret;

    # Wait for tid to be set by start method
    while ($self->tid() == -1) {
        threads->yield();
    }

    if ($self->can("pre_run")) {
        $ret = $self->pre_run(@args);
    } else {
        $ret = 1;
    }

    my $msg = Pots::Message->new(
        'startcode',
        { startcode => $ret }
    );

    $self->postmsg($msg);

    return 0 unless $ret;

    # Ready to go, wait for runflag to be signaled
    $self->startsem->down();

    $ret = $self->run(@args) if $self->can("run");
    $msg = Pots::Message->new('stopped');
    $msg->set('retval', $ret);
    $self->postmsg($msg);

    $self->post_run(@args) if $self->can("post_run");
}

sub destroy {
}

1; #this line is important and will help the module return a true value
__END__

=head1 NAME

Pots::Thread - Perl ObjectThreads Thread Object

=head1 SYNOPSIS

    # Simple useless example
    use Pots::Thread;
    my $th = Pots::Thread->new();
    $th->start();
    ...
    $th->stop();

    # Simple less useless example
    package MyThread;
    use base qw(Pots::Thread);

    sub new {
        my $class = shift;
        my %p = @_;

        my $self = $class->SUPER::new(%p);

        return $self;
    }

    sub initialize {
        my $self = shift;
        my %p = @_;

        $self->SUPER::initialize(%p);
        $self->{'my_option} = $p{'my_option'} if ($p{'my_option'});

        return 1;
    }

    sub pre_run {
        my $self = shift;

        ...
    }

    sub run {
        my $self = shift;
        my $quit = 0;
        my $msg;

        while (!$quit) {
            $msg = $self->getmsg();

            for ($msg->type()) {
                if (/quit/) {
                    $quit = 1;
                } else {
                }
            }
        }
    }

    sub post_run {
        my $self = shift;

        ...
    }

    package main;

    my $th = MyThread->new(
        my_option => 'foo',
        args => qw(arg1 arg2 arg3)
    );

    $th->start();
    ...
    $th->stop();

=head1 DESCRIPTION

C<Pots::Thread> allows you to use Perl 5.8 ithreads in an object-oriented way.
It is not very usefull on its own but rather as a base class.

It has a built-in message queue implemented using a C<Pots::MessageQueue>
object. Using that queue, you can send C<Pots::Message> objects to the
thread. See C<Pots::Tutorial> for examples.

=head1 METHODS

=over

=item new ([ARGS])

This will create a new Pots::Thread object. You can pass arguments, as
key-value pairs.

The following keys are automatically handled:

  detach     create a detached thread (default: 1)
  args       parameter(s) to be passed to the thread's "pre_run", "run"
             and "post_run" methods.

=item initialize ()

This method is called to allow you to initialize your object before the
thread is created. You should call the parent's initialize and return
a true value, otherwise object creation will fail.

The second argument is the parameter hash used when "new()" was called.

=item start ()

Pots::Thread objects do not start by default when created. You must call
"start()" on them so they start running.

=item pre_run ()

This method, if implemented in your derived class, is called just after
the thread is created and runs in the new thread context. It is passed
the "args" parameter(s) specified when you called "new()".

It should return a true value to indicate success, or the thread will
stop.

=item run ()

This method, if implemented in your derived class, is called after the
thread is started (with "start()") if the "pre_run()" method has succeeded.

This is the typical place to do something useful.

Its return value will be returned by the "stop()" method.

=item post_run ()

This method, if implemented in your derived class, is called after the
"run()" method.

=item postmsg ($msg)

Allows you to send a Pots::Message to the running thread.
If called in the thread context, it will send a message to the parent
thread.
After posting the message, the method returns immediately.
See C<Pots::Message> for further information.

=item getmsg ()

Allows you to retrieve messages sent by the thread (e.g.: in response to
a message sent with "postmsg()").
If called in the thread context, it will retrieve messages sent by the
parent thread.

Returns a Pots::Message object, see C<Pots::Message> for further information.

=item sendmsg ()

This is a combination of "postmsg()" and "getmsg()". This method sends a
message and waits for its reply.

=back

=head1 AUTHOR and COPYRIGHT

Remy Chibois E<lt>rchibois at free.frE<gt>

Copyright (c) 2004 Remy Chibois. All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
