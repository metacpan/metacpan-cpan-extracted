# -*- perl -*-
#
# Copyright (C) 2006 Red Hat
# Copyright (C) 2006-2007 Daniel P. Berrange
#
# This program is free software; You can redistribute it and/or modify
# it under either:
#
# a) the GNU General Public License as published by the Free
#   Software Foundation; either version 2, or (at your option) any
#   later version,
#
# or
#
# b) the "Artistic License"
#
# The file "LICENSE" distributed along with this file provides full
# details of the terms and conditions of the two licenses.

=pod

=head1 NAME

Sys::Virt::EventImpl - Event loop implementation parent class

=head1 DESCRIPTION

The C<Sys::Virt::EventImpl> module represents the contract for integrating
libvirt with an event loop. This package is abstract and intended to
be subclassed to provide an actual implementation.

This module is new in 9.5.0. To use this module while also supporting pre-9.5.0
versions, could may consider the code below to set up inheritance.


  package YourImpl;

  use strict;
  use warnings;

  BEGIN {
    if (require Sys::Virt::EventImpl) {
       eval "use parent 'Sys::Virt::EventImpl';";
    }
    else {
       eval "use parent 'Sys::Virt::Event';";
    }
  }

=cut

package Sys::Virt::EventImpl;

use strict;
use warnings;


=head1 EVENT LOOP IMPLEMENTATION

When implementing an event loop, the implementation must be a sub-class
of the C<Sys::Virt::EventImpl> class.  It must override these functions:


=over 4

=item my $watch_id = $self->add_handle( $fd, $events, $callback, $opaque, $ff )

Registers C<$callback> to be invoked for C<$events> on C<$fd>. Use
C<_run_handle_callback> to do the actual invocation from the event
loop (see L</"Callback helpers"> below).

Next to the events explicitly indicated by C<$events>,
C<Sys::Virt::Event::HANDLE_ERROR> and C<Sys::Virt::Event::HANDLE_HANGUP>
should I<always> trigger the callback.

Returns a positive integer C<$watch_id> or C<-1> on error.

=item $self->update_handle($watch_id, $events)

Replaces the events currencly triggering C<$watch_id> with C<$events>.

=item my $ret = $self->remove_handle($watch_id)

Removes the C<$callback> from the C<$fd>.

Returns C<0> on success or C<-1> on failure.

B<IMPORTANT> This should also make sure that C<_free_callback_opaque> is
called I<after> this function has been executed: not doing so will prevent
the connection from being garbage collected.

=item my $timer_id = $self->add_timeout($frequency, $callback, $opaque, $ff)

=item $self->update_timeout($timer_id, $frequency)

Replaces the interval on the timer with C<$frequency>.

=item my $ret = $self->remove_timeout($timer_id)

Discards the timer.

Returns C<0> on success or C<-1> on failure.

B<IMPORTANT> This should also make sure that C<_free_callback_opaque> is
called I<after> this function has been executed: not doing so will prevent
the connection from being garbage collected.

=back

=cut

sub add_handle {
    my $self = shift;
    die ref($self) . " must provide an impl of 'add_handle'";
}
sub update_handle {
  my $self = shift;
  die ref($self) . " must provide an impl of 'update_handle'";
}
sub remove_handle {
  my $self = shift;
  die ref($self) . " must provide an impl of 'remove_handle'";
}
sub add_timeout {
  my $self = shift;
  die ref($self) . " must provide an impl of 'add_timeout'";
}
sub update_timeout {
  my $self = shift;
  die ref($self) . " must provide an impl of 'update_timeout'";
}
sub remove_timeout {
  my $self = shift;
  die ref($self) . " must provide an impl of 'remove_timeout'";
}

=head2 Callback helpers

=over 4

=item $self->_run_handle_callback($watch_id, $fd, $events, $cb, $opaque)

A helper method for executing a callback in response to one of more
C<$events> on the file handle C<$fd>. The C<$watch> number is the
unique identifier associated with the file descriptor. The C<$cb>
and C<$opaque> parameters are the callback and data registered for
the handle.

=cut

sub _run_handle_callback {
    my $self = shift;
    my $watch = shift;
    my $fd = shift;
    my $events = shift;
    my $cb = shift;
    my $opaque = shift;
    _run_handle_callback_helper($watch, $fd, $events, $cb, $opaque);
}

=item $self->_run_timeout_callback($timer_id, $cb, $opaque)

A helper method for executing a callback in response to the
expiry of a timeout identified by C<$timer>. The C<$cb>
and C<$opaque> parameters are the callback and data registered for
the timeout.

=cut

sub _run_timeout_callback {
    my $self = shift;
    my $timer = shift;
    my $cb = shift;
    my $opaque = shift;
    _run_timeout_callback_helper($timer, $cb, $opaque);
}

=item $self->_free_callback_opaque($ff, $opaque)

A helper method for freeing the data associated with a callback.
The C<$ff> and C<$opaque> parameters are the callback and data
registered for the handle/timeout.

B<IMPORTANT> This helper must be called outside of any callbacks; that is
I<after> the C<remove_handle> or C<remove_timeout> callbacks complete.

=cut

sub _free_callback_opaque {
    my $self = shift;
    my $ff = shift;
    my $opaque = shift;
    _free_callback_opaque_helper($ff, $opaque);
}

1;

=back

=head1 AUTHORS

Daniel P. Berrange <berrange@redhat.com>

=head1 COPYRIGHT

Copyright (C) 2006-2009 Red Hat
Copyright (C) 2006-2009 Daniel P. Berrange

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of either the GNU General Public License as published
by the Free Software Foundation (either version 2 of the License, or at
your option any later version), or, the Artistic License, as specified
in the Perl README file.

=head1 SEE ALSO

L<Sys::Virt>,  C<http://libvirt.org>

=cut
