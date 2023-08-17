package Sys::Virt::IO::Async::EventImpl;

=head1 NAME

Sys::Virt::IO::Async::EventImpl - Integration of libvirt into IO::Async event loop

=head1 SYNOPSIS

  use Sys::Virt;
  use Sys::Virt::Event;
  use Sys::Virt::IO::Async::EventImpl;

  use IO::Async::Loop;

  my $loop = IO::Async::Loop;
  my $impl = Sys::Virt::IO::Async::EventImpl->new;
  Sys::Virt::Event::register( $impl );


  my $conn = Sys::Virt->new( uri => 'qemu:///system' );
  $conn->domain_event_register(
     sub {
       # ... log some event data
     });

  $loop->add( $impl );
  $loop->run;

=head1 DESCRIPTION

This module implements an event loop integration for libvirt through
the L<Sys::Virt::Event> libvirt event interface bindings.

C<libvirt> is limited to a single registered event loop. Registration
must be done before the first libvirt connection is created.

=head2 LOGGING

This module implements logging using L<Log::Any> with the module name
as the logging category.

=cut

use strict;
use warnings;

BEGIN {
    local $@;
    if (eval { require 'Sys::Virt::EventImpl' }) {
        eval "use parent qw(Sys::Virt::EventImpl IO::Async::Notifier);";
    }
    else {
        eval "use parent qw(Sys::Virt::Event IO::Async::Notifier);";
    }
}

use Sys::Virt;
use Sys::Virt::Event;

use Feature::Compat::Try;
use IO::Async::Handle;
use IO::Async::Timer::Periodic;
use IO::Handle;

use Log::Any '$log';

our $VERSION = '0.0.5';

=head1 METHODS

=head2 new()

Constructor.

As there can only ever be a single event loop registered at a time, this
module implements a singleton class.  The C<new> method always returns the
same instance.

The returned instance is an C<IO::Async::Notifier> that can be used to
register an event loop implementation through C<Sys::Virt::Event::register>.

=cut

my $impl;
sub new {
    my ($class, %args) = @_;
    return $impl if $impl;

    $log->trace( 'Async event loop creation' );
    return $impl = bless {
        _watches => {},
    }, $class;
}

my $watch_count = 1;

sub _allocate_watch {
    my ($self, $opaque, $free_cb) = @_;
    my $watch_id = $watch_count++;
    my $watch = $self->{_watches}->{$watch_id} = {
        opaque => $opaque,
        free_cb => $free_cb,
    };
    $log->trace( 'watch allocated' );
    return (
        $watch_id,
        $watch
        );
}

sub _remove_watch {
    my ($self, $watch_id) = @_;
    my $watch = delete $self->{_watches}->{$watch_id};

    $self->remove_child( $watch->{notifier} );
    $self->loop->later(
        sub{
            $self->_free_callback_opaque($watch->{free_cb}, $watch->{opaque});
            $log->trace( 'opaque deallocated' );
        });
    $log->trace( 'watch removed' );
}

=head2 $self->add_handle( $fd, $events, $callback, $opaque, $opaque_free_cb )

Implements the event loop integration protocol C<add_handle> callback.

Adds the file handle C<$fd> to the event loop, calling C<$callback> for
the events in the mask C<$events>, returning an integer C<$watch_id>
for reference with C<update_handle> and C<remove_handle>.

Returns a non-negative int C<$watch_id> or -1 on error.

=cut

sub add_handle {
    my ($self, $fd, $events, $cb, $data, $free_cb) = @_;

    try {
        my $h = IO::Handle->new_from_fd($fd, "+<");
        my ($watch_id, $watch) = $self->_allocate_watch( $data, $free_cb );

        $log->trace( "original fd: $fd" );
        $log->trace( "IO::Handle fd: " . $h->fileno );
        $watch->{notifier} = IO::Async::Handle->new(
            handle => $h,
            on_error => sub {
                $log->trace( "on_error" );
                $self->_run_handle_callback( $watch_id, $fd,
                                             Sys::Virt::Event::HANDLE_ERROR,
                                             $cb, $data );
            },
            on_read_ready => sub {
                $log->trace( "on_read_ready" );
                $self->_run_handle_callback( $watch_id, $fd,
                                             Sys::Virt::Event::HANDLE_READABLE,
                                             $cb, $data );
            },
            on_write_ready => sub {
                $log->trace( "on_write_ready" );
                $self->_run_handle_callback( $watch_id, $fd,
                                             Sys::Virt::Event::HANDLE_WRITABLE,
                                             $cb, $data );
            },
            on_closed => sub {
                $log->trace( "on_closed" );
                $self->_run_handle_callback( $watch_id, $fd,
                                             Sys::Virt::Event::HANDLE_HANGUP,
                                             $cb, $data );
            });
        $self->{_watches}->{$watch_id} = $watch;
        $self->update_handle( $watch_id, $events );

        $self->add_child( $watch->{notifier} );
        $log->trace( 'handle added' );
        return $watch_id;
    }
    catch ($e) {
        $log->error( "Error adding handle: $e" );
        return -1;
    }
}

=head2 $self->update_handle( $watch_id, $events )

Implements the event loop integration protocol C<update_handle> callback.

Changes the events for which the callback registered through C<add_handle>
will be triggered to those specified in C<$events>.

=cut

sub update_handle {
    my ($self, $watch_id, $events) = @_;
    my $watch = $self->{_watches}->{$watch_id};
    $watch->{events} = $events;

    my $notifier = $watch->{notifier};
    $notifier->want_readready( $events & Sys::Virt::Event::HANDLE_READABLE );
    $notifier->want_writeready( $events & Sys::Virt::Event::HANDLE_WRITABLE );
    $log->trace( "handle updated: $events" );
}

=head2 $self->remove_handle( $watch_id )

Implements the event loop integration protocol C<remove_handle> callback.

Returns 0 on success, -1 on failure.

=cut

sub remove_handle {
    my ($self, $watch_id) = @_;

    try {
        $self->_remove_watch( $watch_id );
        $log->trace( 'handle removed' );

        return 0;
    }
    catch ($e) {
        $log->error( "Failed to remove handle: $e" );
        return -1;
    }
}

=head2 $self->add_timeout( $frequency, $callback, $opaque, $opaque_free_cb )

Implements the event loop integration protocol C<add_timeout> callback.

Adds the file handle C<$fd> to the event loop, calling C<$callback> for
the events in the mask C<$events>, returning an integer C<$watch_id>
for reference with C<update_handle> and C<remove_handle>.

Returns a non-negative int C<$timer_id> or -1 on error.

=cut

sub add_timeout {
    my ($self, $freq, $cb, $data, $free_cb) = @_;

    try {
        my ($timer_id, $timer) = $self->_allocate_watch( $data, $free_cb );
        $timer->{cb} = $cb;

        $self->update_timeout( $timer_id, $freq );
        return $timer_id;
    }
    catch ($e) {
        $log->error( "Error adding timer: $e" );
        return -1;
    }
}

=head2 $self->update_handle( $timer_id, $frequency )

Implements the event loop integration protocol C<update_timeout> callback.

Changes the duration between callback triggers; C<$frequency> is an integer
in milliseconds, with the values C<0> (zero) and C<-1> taking special meaning:
C<0> means calling the callback on each event loop iteration and C<-1> pauses
the timer.

The semantics of C<0> are implemented using the C<watch_idle> function
of the event loop.

Frequency changes are implemented by stopping the current IO::Async timer
and creating a new one with the desired frequency. (Where C<-1> simply stops
the current IO::ASync timer.)

=cut

sub update_timeout {
    my ($self, $timer_id, $freq) = @_;
    my $timer = $self->{_watches}->{$timer_id};

    $self->remove_child( $timer->{notifier} )
        if $timer->{notifier};
    my $idler = delete $timer->{idle_watch};
    $self->loop->unwatch_idle( $idler );

    if ($freq < 0) {
        $log->trace( "Disabled timer" );
    }
    elsif ($freq == 0) {
        # $freq == 0: trigger callback on each iteration
        $timer->{idle_watch} = $self->loop->watch_idle(
            when => 'later',
            code => sub {
                $log->trace( "on_tick" );
                $self->_run_timeout_callback( $timer_id,
                                              $timer->{cb},
                                              $timer->{opaque} );
            });
    }
    else {
        $log->trace( "Updating timer: $freq" );
        $timer->{notifier} = IO::Async::Timer::Periodic->new(
            interval => ($freq / 1000),
            on_tick => sub {
                $log->trace( "on_tick" );
                $self->_run_timeout_callback( $timer_id,
                                              $timer->{cb},
                                              $timer->{opaque} );
            },
            reschedule => 'drift');
        $self->add_child( $timer->{notifier}->start );
    }
    return;
}

=head2 $self->remove_timeout( $timer_id )

Implements the event loop integration protocol C<remove_timeout> callback.

Returns 0 on success, -1 on failure.

=cut

sub remove_timeout {
    my ($self, $timer_id) = @_;

    try {
        $self->_remove_watch( $timer_id );
        return 0;
    }
    catch ($e) {
        $log->error( "Failed to remove timer: $e" );
        return -1;
    }
}


1;

__END__

=head1 AUTHORS

=over 4

=item * Erik Huelsmann C<< ehuels at gmail.com >>

=back

=head1 SUPPORT

Please report bugs and ask your questions on L<GitHub|https://github.com/ehuelsmann/Sys-Virt-IO-Async/issues>.

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023 by Erik Huelsmann.

This is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.
