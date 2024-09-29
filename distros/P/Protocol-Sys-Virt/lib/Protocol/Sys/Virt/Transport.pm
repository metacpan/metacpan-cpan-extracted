####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1,
#        XDR::Gen version 0.0.5 and LibVirt version v10.3.0
#
#      Don't edit this file, use the source template instead
#
#                 ANY CHANGES HERE WILL BE LOST !
#
####################################################################


use v5.14;
use warnings;

package Protocol::Sys::Virt::Transport v10.3.11;

use Carp qw(croak);
use Log::Any qw($log);

use Protocol::Sys::Virt::Transport::XDR;

my $msgs = 'Protocol::Sys::Virt::Transport::XDR';

sub new {
    my ($class, %args) = @_;
    return bless {
        buf         => '',
        fds         => undef,
        expect      => 'START', # first state of the state machine...
        want        => -1,
        need_length => 4,
        need_type   => 'data',
        role        => $args{role},
        serial      => 1,
        prog_cb     => {},
        on_send     => $args{on_send},
    }, $class;
};

sub register {
    my ($self, $prog, $version, $callbacks) = @_;
    $self->{prog_cb}->{$prog} = $callbacks;

    return sub {
        return $self->_send( $prog, $version, @_  );
    };
}

my @dispatch = qw(
    on_call on_reply on_message on_stream
    on_call on_reply on_stream );


sub _dispatch {
    my ($self) = @_;
    my $data   = $self->{payload};
    my $fds    = $self->{fds};
    my $hdr    = $self->{hdr};
    my $status = $hdr->{status};
    my $type   = $hdr->{type};
    my $prog   = $hdr->{prog};

    if ($status == $msgs->OK) {
        if ($type < 0 or $type > $#dispatch) {
            croak $log->fatal("Unsupported frame type $type");
        }

        my $hole;
        if ($type == $msgs->STREAM_HOLE) {
            my $idx = 0;
            $msgs->deserialize_StreamHole( $hole, $idx, $self->{buf} );
            $self->{buf} = substr( $self->{buf}, $idx );

            $data = undef;
        }
        $log->trace("Invoking callback $dispatch[$type] on program $prog");
        return $self->{prog_cb}->{$prog}->{$dispatch[$type]}->(
            header => $hdr,
            data   => $data,
            fds    => $fds,
            hole   => $hole
            );
    }
    elsif ($status == $msgs->ERROR) {
        if ($type == $msgs->STREAM
            and $self->{role} eq 'server') { # client message
            # no payload
            return $self->{prog_cb}->{$prog}->{on_stream}->(
                header => $hdr,
                );
        }

        #deserialize the server error...
        my $err;
        my $idx = 0;
        $msgs->deserialize_Error( $err, $idx, $data );
        if ($type == $msgs->REPLY
            or $type == $msgs->STREAM
            or $type == $msgs->STREAM_HOLE
            or $type == $msgs->REPLY_WITH_FDS) {
            $log->trace("Invoking callback $dispatch[$type] on program $prog");
            return $self->{prog_cb}->{$prog}->{$dispatch[$type]}->(
                header => $hdr,
                error  => $err,
                );
        }
        else {
            croak $log->fatal( "Status ERROR not supported on frame type $type" );
        }
    }
    elsif ($status == $msgs->CONTINUE) {
        if ($type == $msgs->STREAM) {
            return $self->{prog_cb}->{$prog}->{on_stream}->(
                header => $hdr,
                data => $data
                );
        }
        elsif ($type == $msgs->STREAM_HOLE) {
            my $hole;
            my $idx = 0;
            $msgs->deserialize_StreamHole( $hole, $idx, $self->{buf} );
            $log->trace("Invoking callback $dispatch[$type] on program $prog");
            return $self->{prog_cb}->{$prog}->{on_stream}->(
                header => $hdr,
                hole => $hole
                );
        }
        else {
            croak $log->fatal( "Status CONTINUE not supported on frame type $type" );
        }
    }
    else {
        croak $log->fatal( "Unsupported 'status' value ($status)" );
    }

    # unreachable
}

# state machine
#
# states:
#  START (nothing happened yet)
#  FRAMELEN (awaiting 4 bytes of data)
#  FRAMEDATA (awaiting remaining data)
#  FD (awaiting file descriptors)

sub _receive {
    my ($self, $data)   = @_;
    my @dispatch_values = ();

    if ($data) {
        if ($self->{expect} eq 'FD') {
            push @{ $self->{fds} }, $data;
        }
        else {
            $self->{buf} .= $data;
        }
    }

    while (1) {
        if ($self->{expect} eq 'START') {
            $self->{want}     = 4;
            $self->{want_fds} = 0;
            $self->{fds}      = undef;
            $self->{payload}  = '';

            $self->{expect}   = 'FRAMELEN';
        }
        if ($self->{expect} eq 'FRAMELEN') {
            my $len = length($self->{buf});
            if ($self->{want} > $len) {
                $self->{need_length} = $self->{want} - $len;
                $self->{need_type}   = 'data';
                last;
            }
            $self->{want} = unpack('L>', $self->{buf} );
            if ($self->{want} < ($msgs->LEN_MAX
                                 + $msgs->HEADER_MAX)) {
                croak $log->fatal(
                    "Received message too short (length: $self->{want})" );
            }
            if ($self->{want} > $msgs->STRING_MAX) {
                croak $log->fatal(
                    "Received message too big (length: $self->{want})" );
            }

            $self->{expect} = 'FRAMEDATA';
        }
        if ($self->{expect} eq 'FRAMEDATA') {
            my $len = length($self->{buf});
            if ($self->{want} > $len) {
                $self->{need_length} = $self->{want} - $len;
                $self->{need_type}   = 'data';
                last;
            }

            # we have our frame
            my $idx = 4;
            my $hdr = {};
            $msgs->deserialize_Header( $hdr, $idx, $self->{buf} );
            $self->{hdr} = $hdr;

            my $type = $hdr->{type};
            my $status = $hdr->{status};
            if ($status == $msgs->OK
                and ($type == $msgs->CALL_WITH_FDS
                     or $type == $msgs->REPLY_WITH_FDS)) {
                $self->{want_fds} =
                    unpack('L>', substr( $self->{buf}, $idx, 4 ));
                $self->{fds} = [];
                $idx += 4;

                $self->{expect}   = 'FD';
            }
            $self->{payload} =
                substr( $self->{buf}, $idx, $self->{want} - $idx );
            $self->{buf} = '' . substr( $self->{buf}, $self->{want} );
        }
        if ($self->{expect} eq 'FD') {
            my $len = scalar( @{ $self->{fds} } );
            if ($self->{want_fds} > $len) {
                $self->{need_length} = $self->{want_fds} - $len;
                $self->{need_type}   = 'fd';
                last;
            }
        }
        # we have our frame *and* (optionally) FDs

        my $dv = $self->_dispatch;
        push @dispatch_values, $dv if defined $dv;

        $self->{expect} = 'START';
    }

    return @dispatch_values;
}


sub need {
    my $self = shift;
    return ($self->{need_length}, $self->{need_type});
}

sub receive {
    my ($self, $data, %args) = @_;

    return $self->_receive($data, %args);
}

sub _send {
    my ($self, $prog, $version, $proc, $type, %args) = @_;

    my $hdr = '';
    my $serial;
    my $idx    = 0;
    my $status = $args{status} // $msgs->OK;
    if ($type == $msgs->CALL
        or $type == $msgs->CALL_WITH_FDS) {
        $serial = $self->{serial}++;
    }
    elsif ($type == $msgs->MESSAGE) {
        $serial = 0;
    }
    elsif (defined $args{serial}) {
        $serial = $args{serial};
    }
    else {
        croak $log->fatal( "Missing 'serial' argument for frame type $type" );
    }
    $msgs->serialize_Header(
        {
            prog   => $prog,
            vers   => $version,
            proc   => $proc,
            type   => $type,
            serial => $serial,
            status => $status,
        },
        $idx, $hdr );

    if ($status == $msgs->OK) {
        if ($type == $msgs->CALL_WITH_FDS
            or $type == $msgs->REPLY_WITH_FDS) {
            # Add FD count before the call arguments data
        }

        my $len = pack('L>',
                       4 + length($hdr) + length($args{data} // 0));
        return $self->{on_send}->( $serial, $len, $hdr, $args{data} );
        ###BUG: Send FDs
    }
    elsif ($status == $msgs->ERROR) {
        my $payload = '';
        unless ($type == $msgs->STREAM
                and $self->{role} eq 'client') { # client message
            my $i = 0;
            $msgs->serialize_Error( $args{error}, $i, $payload );
        }

        my $len = pack('L>', 4 + length($hdr) + length($payload));
        return $self->{on_send}->( $serial, $len, $hdr, $payload );
    }
    elsif ($status == $msgs->CONTINUE) {
        my $payload;
        my $i = 0;
        if ($type == $msgs->STREAM_HOLE) {
            $msgs->serialize_StreamHole( $args{hole}, $i, $payload );
        }
        elsif ($type == $msgs->STREAM) {
            $payload = $args{data};
        }
        else {
            croak $log->fatal( "Unsupported frame type $type with status CONTINUE" );
        }

        my $len = pack('L>', 4 + length($hdr) + length($payload // ''));
        return $self->{on_send}->( $serial, $len, $hdr, $payload );
    }
    else {
        croak $log->fatal( "Unsupported frame status $status" );
    }

    # unreachable
}

1;

__END__

=head1 NAME

Protocol::Sys::Virt::Transport - Low level Libvirt connection protocol

=head1 VERSION

v10.3.11

Based on LibVirt tag v10.3.0

=head1 SYNOPSIS

  use Protocol::Sys::Virt::Transport;
  use Protocol::Sys::Virt::Remote;

  open my $fh, 'rw', '/run/libvirt/libvirt.sock';
  my $transport = Protocol::Sys::Virt::Transport->new(
       role => 'client',
       on_send => sub { my $opaque = shift; syswrite( $fh, $_ ) for @_; $opaque }
  );

  my $remote = Protocol::Sys::Virt::Remote->new;
  $remote->register( $transport );


=head1 DESCRIPTION

This module implements an abstract transport with the low level mechanics
to talk to (remote) LibVirt deamons like libvirtd, libvirt-qemud, libvirt-lockd
or libvirtd-admin.  Instances do not directly communicate over a connection
stream; instead, they expect the caller to handle incoming data and call the
C<receive> method for handling by the protocol.  Similarly, the C<on_send> event
is invoked with data to be transmitted.

=head1 EVENTS

=head2 on_send

  $on_send->( $opaque, $chunk [, ..., $chunkN ] );

Invoked with any number of arguments, each a chunk of data to be transmitted
over the connection stream, except the first (C<$opaque>) value.

In case the chunk is an arrayref, the chunk contains file descriptors to be
transferred.

Must return the C<$opaque> value after transferring the data, or C<die>
in case of an error.

=head1 CONSTRUCTOR

=head2 new

  my $transport = Protocol::Sys::Virt::Transport->new(
     role => 'client',
     on_send => sub { ... }
  );

Creates an instance on the client side (C<< role => 'client' >>) or server
(C<< role => 'server' >>) side of the connection.

The C<on_send> event is triggered with data to be transmitted.  It may
be called with multiple arguments:

  sub _transmitter {
     my $opaque = shift;
     syswrite( $fh, $_ ) for (@_);
     return $opaque;
  }

The first argument must be returned when the routine finishes transmitting
its data.

=head1 METHODS

=head2 need

  my ($length, $type) = $transport->need;

Returns the C<$type> of data expected by the next call to C<receive>
(values are C<data> and C<fd>) as well as the number of file handles
(in case of C<fd> type) or bytes (in case of C<data> type) expected.

When the C<fd> type is indicated, the protocol expects a file descriptor
as the next C<$data> argument.  File descriptors can only be passed over
Unix domain sockets; over any other connection, this should result in a
fatal error at the caller.

=head2 receive

  my @cb_values = $transport->receive( $data, [ type => 'fd' ] );

Feed data received on the connection stream to the protocol transport
instance.  When C<$data> is a file descriptor, the C<< type => 'fd' >>
should be passed.

The function collects and returns the values of the event callbacks as they
are invoked as part of processing the protocol input.

=head2 register

   my $sender = $transport->register($remote->PROG, $remote->PROTOCOL_VERSION, {
      on_call    => ...,
      on_reply   => ...,
      on_message => ...,
      on_stream  => ...
   });

  my $serial = $sender->($proc, $type, data => $data,
                [status => $status], [fds => $fds], [serial => $serial]);

Registers callbacks for a 'program' (remote, keep alive, admin, ...) with a
version of the protocol and a series of callbacks to be invoked when the
specific type of input is received.

In case where C<$type> is C<CALL> or C<CALL_WITH_FDS>, the C<$serial> returned
by the sender function must be used to link messages passed to C<on_reply> or
C<on_stream> to the call that triggered the replies.

B<Note:> the C<on_send> function may be marked C<async> (as in
L<Future::AsyncAwait>), in which case the C<$sender> function returns a L<Future>
which eventually resolves to the C<$serial>.

The callbacks are called as follows, with any return values collected and returned
by the C<receive> function:

=over 8

=item * on_call

  my $rv = $on_call->(header => $hdr, data => $data, [fds => $fds]);

Called for messages of type C<CALL> and C<CALL_WITH_FDS>.  The difference
between the two is that the latter is passed an array of file descriptors
in the C<fds> key.  The C<header> key contains the deserialized header.

The C<data> key contains the undecoded data of the C<*_args> structure
associated with C<< $hdr->{proc} >>.

=item * on_reply

  my $rv = $on_reply->(header => $hdr, data  => $data, [fds => $fds]);
  my $rv = $on_reply->(header => $hdr, error => $err);

Called for messages of type C<REPLY> or C<REPLY_WITH_FDS>.  The difference
between the two is that the latter is passed an array of file descriptors
in the C<fds> key.  The C<header> key contains the deserialized header.

The C<data> key contains the undecoded data of the C<*_ret> structure
associated with C<$hdr->{proc}>.

In case the server sends an error, the C<error> key contains the deserialized
error structure and neither C<data> nor C<fds> keys are supplied.

=item * on_message

  my $rv = $on_message->(header => $hdr, data  => $data);

Called for messages of type C<MESSAGE>.  The C<data> key contains the undecoded
data of the C<*_msg> structure associated with C<$hdr->{proc}>.

=item * on_stream

  my $rv = $on_stream->(header => $hdr, data => $data);
  my $rv = $on_stream->(header => $hdr, hole => $hole);
  my $rv = $on_stream->(header => $hdr, error => $err);

Called for messages of type C<STREAM> or C<STREAM_HOLE>.  C<$data> is the raw
stream data to be written to the stream.  C<$hole> is the deserialized stream
hole structure.  C<$err> is the deserialized error structure.

=back

=head1 LICENSE AND COPYRIGHT

See the LICENSE file in this distribution.

