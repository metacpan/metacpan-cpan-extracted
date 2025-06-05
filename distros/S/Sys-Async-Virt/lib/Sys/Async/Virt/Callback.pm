####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1
#                   and LibVirt version v11.4.0
#
#      Don't edit this file, use the source template instead
#
#                 ANY CHANGES HERE WILL BE LOST !
#
####################################################################


use v5.26;
use warnings;
use experimental 'signatures';
use Feature::Compat::Try;
use Future::AsyncAwait;

package Sys::Async::Virt::Callback v0.0.20;

use Carp qw(croak);
use Future::Queue;
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v0.0.20;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';

sub new($class, %args) {
    return bless {
        id => $args{id},
        client => $args{client},
        deregister_call => $args{deregister_call},
        queue => Future::Queue->new(
            max_items => $args{queue_len} // 12,
            prototype => $args{factory}
            ),
    }, $class;
}

async sub next_event($self) {
    return unless $self->{queue}; # simulate an empty queue
    return await $self->{queue}->shift;
}

async sub cancel($self) {
    return if ($self->{cancelled}
               and $self->{cancelled}->is_ready);
    return await $self->{cancelled} if $self->{cancelled};

    $self->{cancelled} = $self->{client}->_call(
        $self->{deregister_call},
        { callbackID => $self->{id} });
    await $self->{cancelled};

    $self->cleanup;
    return;
}

sub cleanup($self) {
    $self->{queue}->finish;
    $self->{queue} = undef;
    delete $self->{client}->{_callbacks}->{$self->{id}};
    return;
}

sub _dispatch_event($self, $event) {
    return if $self->{cancelled};

    try {
        $self->{queue}->push($event);
    }
    catch ($e) {
        ###TODO: Rather not RETAIN here?
        $self->cancel->retain;
    }
}

sub DESTROY($self) {
    $self->cancel->retain unless $self->{cancelled};
}


1;

__END__

=head1 NAME

Sys::Async::Virt::Callback - Client side proxy to remote LibVirt event source

=head1 VERSION

v0.0.20

=head1 SYNOPSIS

  my $cb = await $client->domain_event_register_any(
     $client->DOMAIN_EVENT_ID_LIFECYCLE );

  while (my $event = await $cb->next_event) {
     my $dom = $event->{dom};

     # process the event
     if ($event->{event} == $dom->EVENT_STOPPED) {
        # Act on stopped domain
     }
  );

=head1 DESCRIPTION

This class provides access to events generated on the remote; its design
allows linear handling of the generated events, by presenting the events
as a stream of futures coming from the server.

Events are buffered until they're read off the callback object. No events
will get lost. However, since the server continues its operations, a domain
could disappear if an event's handling is delayed too long.

=head1 CONSTRUCTOR

=head2 new

Not to be called directly; used internally by methods returning
instances of this class.

=head1 DESTRUCTOR

=head2 DESTROY

Unregisters the callback from the server if it hasn't already been cancelled;
not to be called directly: Perl calls this method when the value goes out of
scope.

=head1 METHODS

=head2 next_event

  my $f = $cb->next_event;

Returns a future which will resolve once the next event is available
or until the callback is terminated using the C<cancel> method.

Returns C<undef> when the event stream has been cancelled and all pending
events have been handled.

=head2 cancel

  my $f = $cb->cancel;

Returns a future which will resolve once the callback has been unregistered
from the server and all pending events (on the client) have been cleared.

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT


  Copyright (C) 2024-2025 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
