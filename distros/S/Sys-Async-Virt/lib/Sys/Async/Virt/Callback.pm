####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1
#                   and LibVirt version v11.10.0
#
#      Don't edit this file, use the source template instead
#
#                 ANY CHANGES HERE WILL BE LOST !
#
####################################################################


use v5.26;
use warnings;
use experimental qw/ signatures /;
use Feature::Compat::Try;
use Future::AsyncAwait;
use Object::Pad 0.821;

class Sys::Async::Virt::Callback v0.2.1;


use Carp qw(croak);
use Future::Queue;
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v11.10.1;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';

field $_id              :reader :param;
field $_client          :reader :param;
field $_deregister_call :param;
field $_queue;
field $_cancelled;

ADJUST :params (:$queue_len //= 12, :$factory) {
    $_queue = Future::Queue->new(
        max_items => $queue_len,
        prototype => $factory
        );
}

async method next_event() {
    return unless $_queue; # simulate an empty queue
    return await $_queue->shift;
}

async method cancel() {
    return await $_cancelled if $_cancelled;

    $_cancelled = $_client->loop->new_future;
    $self->cleanup;
    await $_cancelled;

    return;
}

method cleanup() {
    return unless $_queue;

    $_queue->finish;
    $_queue = undef;
    $_client->_deregister_callback(
        $_cancelled,
        $_deregister_call,
        $_id );

    return;
}

method _dispatch_event($event) {
    return if $_cancelled;

    try {
        $_queue->push($event);
    }
    catch ($e) {
        $self->cleanup;
    }
}

method DESTROY() {
    $self->cleanup;
}


1;

__END__

=head1 NAME

Sys::Async::Virt::Callback - Client side proxy to remote LibVirt event source

=head1 VERSION

v0.2.1

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
