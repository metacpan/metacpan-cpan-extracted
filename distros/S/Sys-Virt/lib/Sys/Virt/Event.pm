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

Sys::Virt::Event - Event loop access

=head1 DESCRIPTION

The C<Sys::Virt::Event> module represents the contract for integrating
libvirt with an event loop. This package is abstract and intended to
be subclassed to provide an actual implementation.

=head1 DEPRECATED FUNCTIONALITY

Event loop implementations used to be required to be instances of
sub-classes of C<Sys::Virt::Event>. Instead, they are now required to
inherit from C<Sys::Virt::EventImpl>. For backward compatibility with
versions 9.4 and older, inheriting from C<Sys::Virt::Event> is still
supported, but will be removed mid 2025.

=head1 METHODS

=over 4

=cut

package Sys::Virt::Event;

use strict;
use warnings;


#The line below exists for 9.4 backward compat; to be removed mid-2025
use parent 'Sys::Virt::EventImpl';


our $eventimpl = undef;

=item register_default()

Register the default libvirt event loop implementation

=item run_default()

Run a single iteration of the default event loop implementation

=item register($impl)

Register an event loop implementation. The implementation should be a
instance of a sub-class of the C<Sys::Virt::EventImpl> package. See the
section L</"EVENT LOOP IMPLEMENTATION"> below for more information.

=cut

sub register {
    my $impl = shift;

    if (!(ref($impl) &&
          $impl->isa("Sys::Virt::EventImpl"))) {
        die "event implementation must be a subclass of Sys::Virt::EventImpl";
    }
    if (ref($impl) &&
        $impl->isa("Sys::Virt::Event")) {
        warn "DECPRECATION WARNING: event implementation is a subclass of Sys::Virt::Event";
    }

    $eventimpl = $impl;

    Sys::Virt::Event::_register_impl();
}



sub _add_handle {
    $eventimpl->add_handle(@_);
}
sub _update_handle {
    $eventimpl->update_handle(@_);
}
sub _remove_handle {
    $eventimpl->remove_handle(@_);
}
sub _add_timeout {
    $eventimpl->add_timeout(@_);
}
sub _update_timeout {
    $eventimpl->update_timeout(@_);
}
sub _remove_timeout {
    $eventimpl->remove_timeout(@_);
}

1;

=item my $watch = Sys::Virt::Event::add_handle($fd, $events, $coderef)

Adds a watch on the file descriptor C<$fd> for the events C<$events>
which is a mask of the FILE HANDLE EVENTS constants listed later.
The C<$coderef> parameter is a subroutine to invoke when an event
is triggered. The subroutine will be passed three parameters, the
watch identifier, the file descriptor and the event mask. This
method returns the watch identifier which can be used to update or
remove the watch

=item Sys::Virt::Event::update_handle($watch, $events)

Update the event mask for the file descriptor watch C<$watch>
to use the events C<$events>.

=item Sys::Virt::Event::remove_handle($watch)

Remove the event mask for the file descriptor watch C<$watch>.

=item my $timer = Sys::Virt::Event::add_timeout($frequency, $coderef, $opaque)

Adds a timeout to trigger with C<$frequency> milliseconds interval.
The C<$coderef> parameter is a subroutine to invoke when an event
is triggered. The subroutine will be passed one parameter, the
timer identifier. This method returns the timer identifier which
can be used to update or remove the timer

=item Sys::Virt::Event::update_timeout($timer, $frequency)

Update the timeout C<$timer> to have the frequency C<$frequency>
milliseconds. The values C<0> and C<-1> have special meaning. The value C<0>
wants the callback to be invoked on each event loop iteration, where
C<-1> stops the callback from being invoked.

=item Sys::Virt::Event::remove_timeout($timer)

Remove the timeout C<$timer>

=back

=head1 CONSTANTS

=head2 FILE HANDLE EVENTS

When integrating with an event loop the following constants
define the file descriptor events

=over 4

=item Sys::Virt::Event::HANDLE_READABLE

The file descriptor has data available for read without blocking

=item Sys::Virt::Event::HANDLE_WRITABLE

The file descriptor has ability to write data without blocking

=item Sys::Virt::Event::HANDLE_ERROR

An error occurred on the file descriptor

=item Sys::Virt::Event::HANDLE_HANGUP

The remote end of the file descriptor closed

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
