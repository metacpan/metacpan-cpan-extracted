package Protocol::DBus::Peer;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Protocol::DBus::Peer - base class for a D-Bus peer

=head1 SYNOPSIS

    $dbus->send_call(
        interface => 'org.freedesktop.DBus.Properties',
        member => 'GetAll',
        signature => 's',
        path => '/org/freedesktop/DBus',
        destination => 'org.freedesktop.DBus',
        body => [ 'org.freedesktop.DBus' ],
        on_return => sub { my ($msg) = @_ },
    );

    my $msg = $dbus->get_message();

    # Same pattern as the IO::Handle method.
    $dbus->blocking(0);

    my $fileno = $dbus->fileno();

    $dbus->flush_write_queue() if $dbus->pending_send();

    # I’m not sure why you’d want to do this, but …
    $dbus->big_endian();

=head1 DESCRIPTION

This class contains D-Bus logic that is useful in both client and
server contexts. (Currently this distribution does not include a server
implementation.)

=cut

use Call::Context;

use Protocol::DBus::Message;
use Protocol::DBus::Parser;
use Protocol::DBus::WriteMsg;

#----------------------------------------------------------------------

=head1 METHODS

=head2 $msg = I<OBJ>->get_message()

This returns a single instace of L<Protocol::DBus::Message>, or undef if
no message is available. It will also fire the appropriate “on_return”
method on METHOD_RETURN messages.

The backend I/O logic reads data in chunks; thus, if there is a message
already available in the read buffer, no I/O is done. If you’re doing
non-blocking I/O then it is thus B<vital> that, every time the DBus socket
is readable, you call this function until undef is returned.

=cut

sub get_message {
    my $msg = $_[0]->{'_parser'}->get_message();

    if ($msg) {
        if (my $serial = $msg->get_header('REPLY_SERIAL')) {
            if (my $cb = delete $_[0]->{'_on_return'}{$serial}) {
                $cb->($msg);
            }
        }
    }

    return $msg;
}

#----------------------------------------------------------------------

=head2 I<OBJ>->flush_write_queue()

Same as L<IO::Framed::Write>’s method of the same name.

=cut

sub flush_write_queue {
    if ($_[0]->{'_io'}->get_write_queue_count()) {
        return $_[0]->{'_io'}->flush_write_queue();
    }

    return 1;
}

#----------------------------------------------------------------------

=head2 I<OBJ>->send_call( %OPTS )

Send a METHOD_CALL message to the server.

%OPTS are C<path>, C<interface>, C<member>, C<destination>, C<signature>,
C<body>, and C<on_return>. These do as you’d expect, with the following
caveats:

=over

=item * C<body>, if given, must be an array reference. See
L<Protocol::DBus::Message> for a discussion of how to map between D-Bus and
Perl.

=item * The C<on_return> callback receives the server’s response
message (NB: either METHOD_RETURN or ERROR) as argument.

=back

=cut

sub send_call {
    my ($self, %opts) = @_;

    my $cb = delete $opts{'on_return'};

    my $ret = $self->_send_msg(
        %opts,
        type => 'METHOD_CALL',
    );

    if ($cb) {
        my $serial = $self->{'_last_sent_serial'};
        $self->{'_on_return'}{$serial} = $cb;
    }

    return $ret;
}

sub send_signal {
    my ($self, %opts) = @_;

    return $self->_send_msg(
        %opts,
        type => 'SIGNAL',
    );
}

#----------------------------------------------------------------------

=head2 I<OBJ>->big_endian()

Same interface as C<blocking()>, but this sets/gets/toggles whether to send
big-endian messages instead of little-endian.

(I’m not sure why it would matter?)

=cut

sub big_endian {
    my ($self) = @_;

    if (@_ > 0) {
        my $old = $self->{'_big_endian'};
        $self->{'_big_endian'} = !!$_[1];

        $self->{'_to_str_fn'} = 'to_string_' . ($_[1] ? 'be' : 'le');

        return $self->{'_big_endian'};
    }

    return !!$self->{'_big_endian'};
}

#----------------------------------------------------------------------

=head2 I<OBJ>->preserve_variant_signatures()

Same interface as C<blocking()>, but when this is enabled
variants are given as two-member array references ([ signature => value ]),
blessed as C<Protocol::DBus::Type::Variant> instances.

For most Perl applications this is probably counterproductive.

=cut

sub preserve_variant_signatures {
    my $self = shift;

    return $self->{'_parser'}->preserve_variant_signatures(@_);
}

#----------------------------------------------------------------------

=head2 I<OBJ>->blocking()

Same interface as L<IO::Handle>’s method of the same name.

=cut

sub blocking {
    my $self = shift;

    return $self->{'_socket'}->blocking(@_);
}

#----------------------------------------------------------------------

=head2 I<OBJ>->fileno()

Returns the connection socket’s file descriptor.

=cut

sub fileno {
    return fileno $_[0]->{'_socket'};
}

#----------------------------------------------------------------------

=head2 I<OBJ>->pending_send()

Returns a boolean that indicates whether there is data queued up to send
to the server.

=cut

sub pending_send {
    return !!$_[0]->{'_io'}->get_write_queue_count();
}

#----------------------------------------------------------------------

sub _set_up_peer_io {
    my ($self, $socket) = @_;

    $self->{'_io'} = Protocol::DBus::WriteMsg->new( $socket )->enable_write_queue();
    $self->{'_parser'} = Protocol::DBus::Parser->new( $socket );

    return;
}

sub _send_msg {
    my ($self, %opts) = @_;

    my ($type, $body_ar, $flags) = delete @opts{'type', 'body', 'flags'};

    my @hargs = map {
        my $k = $_;
        $k =~ tr<a-z><A-Z>;
        ( $k => $opts{$_} );
    } keys %opts;

    my $serial = ++$self->{'_last_sent_serial'};

    my $msg = Protocol::DBus::Message->new(
        type => $type,
        hfields => \@hargs,
        flags => $flags,
        body => $body_ar,
        serial => $serial,
    );

    $self->{'_endian'} ||= 'le';
    $self->{'_to_str_fn'} ||= "to_string_$self->{'_endian'}";

    my ($buf_sr, $fds_ar) = $msg->can($self->{'_to_str_fn'})->($msg);

    if ($fds_ar && @$fds_ar && !$self->supports_unix_fd()) {
        die "Cannot send file descriptors without UNIX FD support!";
    }

    $self->{'_io'}->enqueue_message( $buf_sr, $fds_ar );

    return $self->{'_io'}->flush_write_queue();
}

1;
