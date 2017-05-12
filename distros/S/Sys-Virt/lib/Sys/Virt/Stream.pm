# -*- perl -*-
#
# Copyright (C) 2011 Red Hat
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

Sys::Virt::Stream - Represent & manage a libvirt stream

=head1 DESCRIPTION

The C<Sys::Virt::Stream> module represents a stream managed
by the virtual machine monitor.

=head1 METHODS

=over 4

=cut

package Sys::Virt::Stream;

use strict;
use warnings;


sub _new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %params = @_;

    my $con = exists $params{connection} ? $params{connection} : die "connection parameter is requried";
    my $self = Sys::Virt::Stream::_new_obj($con, $params{flags});

    bless $self, $class;

    return $self;
}


=item my $st Sys::Virt::Stream->new($conn, $flags);

Creates a new data stream, ready for use with a stream based
API. The optional C<$flags> parameter can be used to configure
the stream as non-blocking

=item $st->abort()

Abort I/O on the stream. Either this function or C<finish> must
be called on any stream which has been activated

=item $st->finish()

Complete I/O on the stream. Either this function or C<abort> must
be called on any stream which has been activated

=item $rv = $st->recv($data, $nbytes)

Receive upto C<$nbytes> worth of data, copying into C<$data>.
Returns the number of bytes read, or -2 if I/O would block,
or -1 on error.

=item $rv = $st->send($data, $nbytes)

Send upto C<$nbytes> worth of data, copying from C<$data>.
Returns the number of bytes sent, or -2 if I/O would block,
or -1 on error.

=item $st->recv_all($handler)

Receive all data available from the stream, invoking
C<$handler> to process the data. The C<$handler>
parameter must be a function which expects three
arguments, the C<$st> stream object, a scalar containing
the data received and a data byte count. The function
should return the number of bytes processed, or -1
upon error.

=item $st->send_all($handler)

Send all data produced by C<$handler> to the stream.
The C<$handler> parameter must be a function which
expects three arguments, the C<$st> stream object, a
scalar which must be filled with data and a maximum
data byte count desired. The function should return
the number of bytes filled, 0 on end of file, or
-1 upon error

=item $st->add_callback($events, $coderef)

Register a callback to be invoked whenever the stream has
one or more events from C<$events> mask set. The C<$coderef>
must be a subroutine that expects 2 parameters, the original
C<$st> object and the new C<$events> mask

=item $st->update_callback($events)

Change the event mask for a previously registered
callback to C<$events>

=item $st->remove_callback();

Remove a previously registered callback

=back

=head1 CONSTANTS

=over 4

=item Sys::Virt::Stream::NONBLOCK

Create a stream which will not block when performing I/O

=item Sys::Virt::Stream::EVENT_READABLE

The stream has data available for read without blocking

=item Sys::Virt::Stream::EVENT_WRITABLE

The stream has ability to write data without blocking

=item Sys::Virt::Stream::EVENT_ERROR

An error occurred on the stream

=item Sys::Virt::Stream::EVENT_HANGUP

The remote end of the stream closed



=cut


1;

=back

=head1 AUTHORS

Daniel P. Berrange <berrange@redhat.com>

=head1 COPYRIGHT

Copyright (C) 2006-2009 Red Hat
Copyright (C) 2006-2007 Daniel P. Berrange

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of either the GNU General Public License as published
by the Free Software Foundation (either version 2 of the License, or at
your option any later version), or, the Artistic License, as specified
in the Perl README file.

=head1 SEE ALSO

L<Sys::Virt>, L<Sys::Virt::Error>, C<http://libvirt.org>

=cut
