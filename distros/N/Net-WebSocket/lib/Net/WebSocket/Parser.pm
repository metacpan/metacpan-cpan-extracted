package Net::WebSocket::Parser;

=encoding utf-8

=head1 NAME

Net::WebSocket::Parser - Parse WebSocket from a filehandle

=head1 SYNOPSIS

    my $iof = IO::Framed->new($fh);

    my $parse = Net::WebSocket::Parser->new($iof);

    #See below for error responses
    my $frame = $parse->get_next_frame();

C<$iof> should normally be an instance of L<IO::Framed::Read>. You’re free to
pass in anything with a C<read()> method, but that method must implement
the same behavior as C<IO::Framed::Read::read()>.

=head1 METHODS

=head2 I<OBJ>->get_next_frame()

A call to this method yields one of the following:

=over

=item * If a frame can be read, it will be returned.

=item * If we hit an empty read (i.e., indicative of end-of-file),
empty string is returned.

=item * If only a partial frame is ready, undef is returned.

=back

=head1 I/O DETAILS

L<IO::Framed> was born out of work on this module; see that module’s
documentation for the particulars of working with it. In particular,
note the exceptions L<IO::Framed::X::EmptyRead> and
L<IO::Framed::X::ReadError>.

Again, you can use an equivalent interface for frame chunking if you wish.

=head1 CONCERNING EMPTY READS

An empty read is how we detect that a file handle (or socket, etc.) has no
more data to read. Generally we shouldn’t get this in WebSocket since it
means that a peer endpoint has gone away without sending a close frame.
It is thus recommended that applications regard an empty read on a WebSocket
stream as an error condition; e.g., if you’re using L<IO::Framed::Read>,
you should NOT enable the C<allow_empty_read()> behavior.

Nevertheless, this module (and L<Net::WebSocket::Endpoint>) do work when
that flag is enabled.

=head1 CUSTOM FRAMES SUPPORT

To support reception of custom frame types you’ll probably want to subclass
this module and define a specific custom constant for each supported opcode,
e.g.:

    package My::WebSocket::Parser;

    use parent qw( Net::WebSocket::Parser );

    use constant OPCODE_CLASS_3 => 'My::WebSocket::Frame::booya';

… where C<My::WebSocket::Frame::booya> is itself a subclass of
C<Net::WebSocket::Base::DataFrame>.

You can also use this to override the default
classes for built-in frame types; e.g., C<OPCODE_CLASS_10()> will override
L<Net::WebSocket::Frame::pong> as the class will be used for pong frames
that this module receives. That could be useful, e.g., for compression
extensions, where you might want the C<get_payload()> method to
decompress so that that detail is abstracted away.

=cut

use strict;
use warnings;

use Module::Load ();

use Net::WebSocket::Constants ();
use Net::WebSocket::X ();

use constant {
    OPCODE_CLASS_0 => 'Net::WebSocket::Frame::continuation',
    OPCODE_CLASS_1 => 'Net::WebSocket::Frame::text',
    OPCODE_CLASS_2 => 'Net::WebSocket::Frame::binary',
    OPCODE_CLASS_8 => 'Net::WebSocket::Frame::close',
    OPCODE_CLASS_9 => 'Net::WebSocket::Frame::ping',
    OPCODE_CLASS_10 => 'Net::WebSocket::Frame::pong',
};

sub new {
    my ($class, $reader) = @_;

    if (!(ref $reader)->can('read')) {
        die "“$reader” needs a read() method!";
    }

    return bless {
        _reader => $reader,
    }, $class;
}

sub get_next_frame {
    my ($self) = @_;

    local $@;

    if (!exists $self->{'_partial_frame'}) {
        $self->{'_partial_frame'} = q<>;
    }

    #It is really, really inconvenient that Perl has no “or” operator
    #that considers q<> falsey but '0' truthy. :-/
    #That aside, if indeed all we read is '0', then we know that’s not
    #enough, and we can return.
    my $first2 = $self->_read_with_buffer(2);
    if (!$first2) {
        return defined($first2) ? q<> : undef;
    }

    #Now that we’ve read our header bytes, we’ll read some more.
    #There may not actually be anything to read, though, in which case
    #some readers will error (e.g., EAGAIN from a non-blocking filehandle).
    #From a certain ideal we’d return #on each individual read to allow
    #the reader to wait until there is more data ready; however, for
    #practicality (and speed) let’s go ahead and try to read the rest of
    #the frame. That means we need to set some flag to let the reader know
    #not to die() if there’s no more data currently, as we’re probably
    #expecting more soon to complete the frame.
    local $self->{'_reading_frame'} = 1;

    my ($oct1, $oct2) = unpack('CC', $first2 );

    my $len = $oct2 & 0x7f;

    my $mask_size = ($oct2 & 0x80) && 4;

    my $len_len = ($len == 0x7e) ? 2 : ($len == 0x7f) ? 8 : 0;
    my $len_buf = q<>;

    my ($longs, $long);

    if ($len_len) {
        $len_buf = $self->_read_with_buffer($len_len);
        if (!$len_buf) {
            substr( $self->{'_partial_frame'}, 0, 0, $first2 );
            return defined($len_buf) ? q<> : undef;
        };

        if ($len_len == 2) {
            ($longs, $long) = ( 0, unpack('n', $len_buf) );
        }
        else {
            ($longs, $long) = ( unpack('NN', $len_buf) );
        }
    }
    else {
        ($longs, $long) = ( 0, $len );
    }

    my $mask_buf;
    if ($mask_size) {
        $mask_buf = $self->_read_with_buffer($mask_size);
        if (!$mask_buf) {
            substr( $self->{'_partial_frame'}, 0, 0, $first2 . $len_buf );
            return defined($mask_buf) ? q<> : undef;
        };
    }
    else {
        $mask_buf = q<>;
    }

    my $payload = q<>;

    for ( 1 .. $longs ) {

        #32-bit systems don’t know what 2**32 is.
        #MacOS, at least, also chokes on sysread( 2**31, … )
        #(Is their size_t signed??), even on 64-bit.
        for ( 1 .. 4 ) {
            my $append_ok = $self->_append_chunk( 2**30, \$payload );
            if (!$append_ok) {
                substr( $self->{'_partial_frame'}, 0, 0, $first2 . $len_buf . $mask_buf . $payload );
                return defined($append_ok) ? q<> : undef;
            };
        }
    }

    if ($long) {
        my $append_ok = $self->_append_chunk( $long, \$payload );
        if (!$append_ok) {
            substr( $self->{'_partial_frame'}, 0, 0, $first2 . $len_buf . $mask_buf . $payload );
            return defined($append_ok) ? q<> : undef;
        }
    }

    $self->{'_partial_frame'} = q<>;

    my $opcode = $oct1 & 0xf;

    my $frame_class = $self->{'_opcode_class'}{$opcode} ||= do {
        my $class;
        if (my $cr = $self->can("OPCODE_CLASS_$opcode")) {
            $class = $cr->();
        }
        else {

            #Untyped because this is a coding error.
            die "$self: Unrecognized frame opcode: “$opcode”";
        }

        Module::Load::load($class) if !$class->can('new');

        $class;
    };

    return $frame_class->create_from_parse(\$first2, \$len_buf, \$mask_buf, \$payload);
}

#This will only return exactly the number of bytes requested.
#If fewer than we want are available, then we return undef.
sub _read_with_buffer {
    my ($self, $length) = @_;

    #Prioritize the case where we read everything we need.

    if ( length($self->{'_partial_frame'}) < $length ) {
        my $deficit = $length - length($self->{'_partial_frame'});
        my $read = $self->{'_reader'}->read($deficit);

        if (!defined $read) {
            return undef;
        }
        elsif (!length $read) {
            return q<>;
        }

        return substr($self->{'_partial_frame'}, 0, length($self->{'_partial_frame'}), q<>) . $read;
    }

    return substr( $self->{'_partial_frame'}, 0, $length, q<> );
}

sub _append_chunk {
    my ($self, $length, $buf_sr) = @_;

    my $start_buf_len = length $$buf_sr;

    my $cur_buf;

    while (1) {
        my $read_so_far = length($$buf_sr) - $start_buf_len;

        $cur_buf = $self->_read_with_buffer($length - $read_so_far);
        return undef if !defined $cur_buf;

        return q<> if !length $cur_buf;

        $$buf_sr .= $cur_buf;

        last if (length($$buf_sr) - $start_buf_len) >= $length;
    }

    return 1;
}

1;
