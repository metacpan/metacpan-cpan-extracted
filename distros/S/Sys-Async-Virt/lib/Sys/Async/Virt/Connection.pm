####################################################################
#
#     This file was generated using XDR::Parse version v1.0.1
#                   and LibVirt version v11.10.0
#
#      Don't edit this file, use the source template instead
#
#                 ANY CHANGES HERE WILL BE LOST !
#
####################################################################


use v5.26;
use warnings;
use experimental 'signatures';
use Future::AsyncAwait;
use Object::Pad ':experimental(inherit_field)';

class Sys::Async::Virt::Connection v0.2.3;

field $_in  :inheritable = undef;
field $_out :inheritable = undef;

# Futures indicating status of the last read/write action
field $_read_f           = Future->done;
field $_write_f          = Future->done;
field $_eof;

use Carp qw(croak);
use Future::IO;
use Log::Any qw($log);

method _finalize_io() {
    $_eof = 1;
    $_write_f->cancel;
    $_write_f = Future->fail( 'closed' );
}

async method close() {
    die $log->fatal(
        "The 'close' method must be implemented by concrete sub-classes");
}

async method connect() {
    die $log->fatal(
        "The 'connect' method must be implemented by concrete sub-classes");
}

method connected() {
    return ($_in and $_out);
}

method is_read_eof() {
    return $_eof;
}

method is_secure() {
    return 0;
}

method is_write_eof() {
    return $_eof;
}

async method read($type, $len) {
    die $log->fatal( "Unsupported transfer type $type" ) unless $type eq 'data';
    return undef if $_eof;

    $log->trace( "Starting read of length $len" );
    $_read_f = $_read_f->then(sub { Future::IO->read_exactly( $_in, $len ) });

    my $data = await $_read_f;
    $log->trace( "Finished read of length $len" );
    $_eof = not defined $data;

    return $data;
}

method _write_chunk($data) {
    die "Write to closed file" if $_eof;

    $log->trace( 'Low-level write of ' . length($data) . ' bytes' );
    $_write_f = $_write_f->then(sub { Future::IO->write_exactly( $_out, $data ) });
    return $_write_f;
}


async method write(@data) {
    return if @data == 0;

    # use the first data element as backpressure
    # but don't await it here: we want to send
    # all data into the send queue at once, so
    # other write calls can't mix their data
    # with ours
    my $f = $self->_write_chunk( shift @data );

    while (@data) {
        my $data = shift @data;
        next unless $data;

        $self->_write_chunk( $data );
    }

    return await $f;
}

1;

__END__

=head1 NAME

Sys::Async::Virt::Connection - Connection to LibVirt server (abstract
 base class)

=head1 VERSION

v0.2.3

=head1 SYNOPSIS

  use v5.26;
  use Future::AsyncAwait;
  use Sys::Async::Virt::Connection::Factory;

  my $factory = Sys::Async::Virt::Connection::Factory->new;
  my $conn    = $factory->create_connection( 'qemu:///system' );

=head1 DESCRIPTION

This module presents an abstract base class.

=head1 METHODS

=head2 connect

  await $conn->connect;

Establishes a connection with the server indicated by the URL passed
to the C<new> method.

Note that implementing classes must provide a C<new> method.

=head2 is_secure

  my $bool = $self->is_secure;

Returns C<true> when the transport is considered secure. This default version
returns C<false>, failing on the safe side.

=head2 read

  my $data = await $conn->read( 'data', 42 );
  my $fds  = await $conn->read( 'fds',   2 );

Reads bytes or file descriptors from the connection, returning a string (when
requested to read data) or a reference to an array of file descriptors (when
requested to read file descriptors).

=head2 write

  await $conn->write( 'data1', 'data2', ... );
  await $conn->write( [ $fd1, $fd2, ... ] );

Writes data (passed as strings) and file descriptors (passed as arrays of
descriptors) to the connection.

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT


  Copyright (C) 2024-2025 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
