package Net::SSH::Perl::Packet;

use strict;
use Carp qw( croak );
use IO::Select;
use POSIX qw( :errno_h );
use Crypt::PRNG qw( random_bytes );

use Net::SSH::Perl;
use Net::SSH::Perl::Constants qw(
    :protocol
    SSH_MSG_DISCONNECT
    SSH_MSG_DEBUG
    SSH_MSG_IGNORE
    SSH2_MSG_GLOBAL_REQUEST
    SSH2_MSG_DISCONNECT
    SSH2_MSG_DEBUG
    SSH2_MSG_IGNORE
    MAX_PACKET_SIZE );
use Net::SSH::Perl::Buffer;

use Scalar::Util qw(weaken);

sub new {
    my $class = shift;
    my $ssh   = shift;
    my $pack  = bless { ssh => $ssh, @_ }, $class;
    weaken $pack->{ssh};
    unless ($pack->{data}) {
        $pack->{data} = Net::SSH::Perl::Buffer->new(
            MP => $ssh->protocol == PROTOCOL_SSH2 ? 'SSH2' : 'SSH1');
        if ($pack->{type}) {
            $pack->{data}->put_int8($pack->{type});
        }
    }
    $pack;
}

sub read {
    my $class = shift;
    my $ssh = shift;
    my $sock = $ssh->sock;

    while (1) {
        if (my $packet = $class->read_poll($ssh)) {
            return $packet;
        }
        my $s = IO::Select->new( $sock );
        my @ready = $s->can_read;
        my $buf;
        my $len = sysread $sock, $buf, 8192;
        croak "Connection closed by remote host." if $len == 0;
        if (!defined $len) {
            next if $! == EAGAIN || $! == EWOULDBLOCK;
            croak "Read from socket failed: $!";
        }

        ## Untaint data read from sshd. This is binary data,
        ## so there's nothing to taint-check against/for.
        ($buf) = $buf =~ /(.*)/s;
        $ssh->incoming_data->append($buf);
    }
}

sub read_poll {
    my $class = shift;
    my $ssh = shift;

    my($packet, $debug, $ignore);
    if ($ssh->protocol == PROTOCOL_SSH2) {
        $packet = $class->read_poll_ssh2($ssh);
        ($debug, $ignore) = (SSH2_MSG_DEBUG, SSH2_MSG_IGNORE);
    }
    else {
        $packet = $class->read_poll_ssh1($ssh);
        ($debug, $ignore) = (SSH_MSG_DEBUG, SSH_MSG_IGNORE);
    }
    return unless $packet;

    my $type = $packet->type;
    if ($ssh->protocol == PROTOCOL_SSH2) {   ## Handle DISCONNECT msg
        if ($type == SSH2_MSG_DISCONNECT) {
            $packet->get_int32;   ## reason
            croak "Received disconnect message: ", $packet->get_str, "\n";
        }
    }
    else {
        if ($type == SSH_MSG_DISCONNECT) {
            croak "Received disconnect message: ", $packet->get_str, "\n";
        }
    }

    if ($type == $debug) {
        $ssh->debug("Remote: " . $packet->get_str);
    }
    elsif ($type == $ignore) { }
    else {
        return $packet;
    }
    return $class->read_poll($ssh);
}

sub read_poll_ssh1 {
    my $class = shift;
    my $ssh = shift;

    unless (defined &_crc32) {
        eval "use Net::SSH::Perl::Util qw( _crc32 );";
        die $@ if $@;
    }

    my $incoming = $ssh->incoming_data;
    return if $incoming->length < 4 + 8;

    my $len = unpack "N", $incoming->bytes(0, 4);
    $len = 0 unless defined $len;
    my $pad_len = ($len + 8) & ~7;
    return if $incoming->length < 4 + $pad_len;

    my $buffer = Net::SSH::Perl::Buffer->new( MP => 'SSH1' );
    $buffer->append($incoming->bytes(0, $pad_len+4, ''));

    $buffer->bytes(0, 4, "");

    if (my $cipher = $ssh->receive_cipher) {
        my $decrypted = $cipher->decrypt($buffer->bytes);
        $buffer->empty;
        $buffer->append($decrypted);
    }

    my $crc = _crc32($buffer->bytes(0, -4));
    $buffer->bytes(0, 8 - $len % 8, "");

    my $stored_crc = unpack "N", $buffer->bytes(-4, 4);
    $ssh->fatal_disconnect("Corrupted check bytes on input")
        unless $crc == $stored_crc;

    $buffer->bytes(-4, 4, "");  ## Cut off checksum.

    if (my $comp = $ssh->compression) {
        my $inflated = $comp->uncompress($buffer->bytes);
        $buffer->empty;
        $buffer->append($inflated);
    }

    my $type = unpack "C", $buffer->bytes(0, 1, "");
    $class->new($ssh,
        type => $type,
        data => $buffer);
}

sub read_poll_ssh2 {
    my $class = shift;
    my $ssh = shift;
    my $kex = $ssh->kex;

    my($ciph, $mac, $comp);
    my $authlen = 0;
    if ($kex) {
        $ciph = $kex->receive_cipher;
        $mac  = $kex->receive_mac;
        $comp = $kex->receive_comp;
        undef $mac if $authlen = $ciph && $ciph->authlen;
    }
    my $maclen = $mac && $mac->enabled ? $mac->len : 0;
    my $block_size = $ciph && $ciph->enabled ? $ciph->blocksize : 8;
    my $aadlen = ($mac && $mac->enabled && $mac->etm) || $authlen ? 4 : 0;
    my $seqnr = $ssh->{session}{seqnr_in};

    my $incoming = $ssh->incoming_data;
    if (!$ssh->{session}{_last_packet_length}) {
        return if $incoming->length < $block_size;
        my $b = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );

        if ($authlen) {
            $b->append($ciph->get_length($incoming->bytes(0,$block_size),
                $seqnr));
        } elsif ($aadlen) {
            $b->append($incoming->bytes(0, $block_size));
        } else {
            $b->append( $ciph && $ciph->enabled ?
                $ciph->decrypt($incoming->bytes(0, $block_size)) :
                $incoming->bytes(0, $block_size)
            );
            # replace first block of incoming buffer with decrypted contents
            $incoming->bytes(0, $block_size, $b->bytes);
        }
        my $plen = $ssh->{session}{_last_packet_length} = $b->get_int32;
        if ($plen < 1 + 4 || $plen > 256 * 1024) {
            $ssh->fatal_disconnect("Bad packet length $plen");
        }
    }
    my $need = $aadlen ? $ssh->{session}{_last_packet_length} :
        4 + $ssh->{session}{_last_packet_length} - $block_size;
    croak "padding error: need $need block $block_size"
        if $need % $block_size;
    return if ( $aadlen && ($incoming->length < $aadlen + $need + $maclen + $authlen)) ||
              (!$aadlen && ($incoming->length < $need + $block_size + $maclen));

    my $buffer = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    my ($macbuf,$p_str);
    if ($mac && $mac->enabled) {
        if ($mac->etm) {
            $p_str = $incoming->bytes(0, $aadlen + $need, '');
            $macbuf = $mac->hmac(pack("N", $seqnr) . $p_str);
            # remove packet length bytes
            substr($p_str,0,$aadlen,'');
        } else {
            # not etm mac, append bytes already decrypted above
            $buffer->append( $incoming->bytes(0, $block_size, '') );
            $p_str = $incoming->bytes(0, $need, '');
        }
    } elsif ($authlen) {
        # cipher with auth
        $p_str = $incoming->bytes(0, $aadlen + $need + $authlen, '');
    } else {
        $buffer->append( $incoming->bytes(0, $block_size, '') );
        $p_str = $incoming->bytes(0, $need, '');
    }

    if ($mac && $mac->enabled) {
        unless ($mac->etm) {
            $buffer->append( $ciph && $ciph->enabled ?
                $ciph->decrypt($p_str) : $p_str );
            $macbuf = $mac->hmac(pack("N", $seqnr) . $buffer->bytes);
        }
        my $stored_mac = $incoming->bytes(0, $maclen, '');
        $ssh->fatal_disconnect("Corrupted MAC on input")
            unless $macbuf eq $stored_mac;
        # with etm macs, do not decrypt until after mac verified
        $buffer->append( $ciph && $ciph->enabled ?
            $ciph->decrypt($p_str) : $p_str ) if $mac->etm;
    } else {
        $buffer->append( $ciph && $ciph->enabled ?
            $ciph->decrypt($p_str,$seqnr,$aadlen) : $p_str );
    }

    $ssh->{session}{seqnr_in}++;

    my $padlen = unpack "C", $buffer->bytes(4-$aadlen, 1);
    $ssh->fatal_disconnect("Corrupted padlen $padlen on input")
        unless $padlen >= 4;

    # Cut off packet size + padlen, discard padding
    $buffer->bytes(0, 5-$aadlen, '');
    $buffer->bytes(-$padlen, $padlen, '');

    if ($comp && $comp->enabled) {
        my $inflated = $comp->uncompress($buffer->bytes);
        $buffer->empty;
        $buffer->append($inflated);
    }

    my $type = unpack "C", $buffer->bytes(0, 1, '');
    $ssh->{session}{_last_packet_length} = 0;
    $class->new($ssh, type => $type, data => $buffer);
}

sub read_expect {
    my $class = shift;
    my($ssh, $type) = @_;
    my $pack = $class->read($ssh);
    if ($pack->type != $type) {
        if ($pack->type == SSH2_MSG_GLOBAL_REQUEST) {
            $ssh->debug("Unprocessed global request encountered");
            # now repeat read_expect for expected type
            return $class->read_expect($ssh,$type);
        } else {
            $ssh->fatal_disconnect(sprintf
              "Protocol error: expected packet type %d, got %d",
                $type, $pack->type);
        }
    }
    $pack;
}

sub send {
    my $pack = shift;
    if ($pack->{ssh}->protocol == PROTOCOL_SSH2) {
        $pack->send_ssh2(@_);
    }
    else {
        $pack->send_ssh1(@_);
    }
}

sub send_ssh1 {
    my $pack = shift;
    my $buffer = shift || $pack->{data};
    my $ssh = $pack->{ssh};

    unless (defined &_crc32) {
        eval "use Net::SSH::Perl::Util qw( _crc32 );";
    }

    if ($buffer->length >= MAX_PACKET_SIZE - 30) {
        $ssh->fatal_disconnect(sprintf
            "Sending too big a packet: size %d, limit %d",
            $buffer->length, MAX_PACKET_SIZE);
    }

    if (my $comp = $ssh->compression) {
        my $compressed = $comp->compress($buffer->bytes);
        $buffer->empty;
        $buffer->append($compressed);
    }

    my $len = $buffer->length + 4;

    my $cipher = $ssh->send_cipher;
    #if ($cipher) {
        $buffer->insert_padding;
    #}

    my $crc = _crc32($buffer->bytes);
    $buffer->put_int32($crc);

    my $output = Net::SSH::Perl::Buffer->new( MP => 'SSH1' );
    $output->put_int32($len);
    my $data = $cipher ? $cipher->encrypt($buffer->bytes) : $buffer->bytes;
    $output->put_chars($data);

    my $sock = $ssh->sock;
    syswrite $sock, $output->bytes, $output->length;
}

sub send_ssh2 {
    my $pack = shift;
    my $buffer = shift || $pack->{data};
    my $ssh = $pack->{ssh};

    my $kex = $ssh->kex;
    my($ciph, $mac, $comp, $authlen);
    if ($kex) {
        $ciph = $kex->send_cipher;
        $mac  = $kex->send_mac;
        $comp = $kex->send_comp;
        undef $mac if $authlen = $ciph && $ciph->authlen;
    }
    my $block_size = $ciph && $ciph->enabled ? $ciph->blocksize : 8;
    my $aadlen = ($mac && $mac->enabled && $mac->etm) || $authlen ? 4 : 0;
    my $seqnr = $ssh->{session}{seqnr_out};

    if ($comp && $comp->enabled) {
        my $compressed = $comp->compress($buffer->bytes);
        $buffer->empty;
        $buffer->append($compressed);
    }

    my $len = $buffer->length + 4 + 1;
    my $padlen = $block_size - (($len - $aadlen) % $block_size);
    $padlen += $block_size if $padlen < 4;
    my $junk = $ciph ? random_bytes($padlen) : ("\0" x $padlen);
    $buffer->append($junk);

    my $packet_len = $buffer->length + 1;
    $buffer->bytes(0, 0, pack("C", $padlen));
    $buffer->bytes(0, 0, pack("N", $packet_len)) unless $mac && $mac->etm;

    my $out = $ciph && $ciph->enabled ? $ciph->encrypt($buffer->bytes,$seqnr,$aadlen) : $buffer->bytes;
    substr($out,0,0,pack("N", $packet_len)) if $mac && $mac->etm;

    my($macbuf);
    if ($mac && $mac->enabled) {
        my $data = $mac->etm ? $out : $buffer->bytes;
        $macbuf = $mac->hmac(pack("N", $seqnr) . $data);
    }

    my $output = Net::SSH::Perl::Buffer->new( MP => 'SSH2' );
    $output->append($out);
    $output->append($macbuf) if $mac && $mac->enabled;

    $ssh->{session}{seqnr_out}++;

    my $sock = $ssh->sock;
    syswrite $sock, $output->bytes, $output->length;
}

sub type {
    my $pack = shift;
    $pack->{type} = shift if @_;
    $pack->{type};
}

sub data { $_[0]->{data} }

use vars qw( $AUTOLOAD );
sub AUTOLOAD {
    my $pack = shift;
    (my $meth = $AUTOLOAD) =~ s/.*://;
    return if $meth eq "DESTROY";

    if ( $pack->{data}->can($meth) ) {
        $pack->{data}->$meth(@_);
    }
    else {
        croak "Can't dispatch method $meth to Net::SSH::Perl::Buffer object.";
    }
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Packet - Packet layer of SSH protocol

=head1 SYNOPSIS

    use Net::SSH::Perl::Packet;

    # Send a packet to an ssh daemon.
    my $pack = Net::SSH::Perl::Packet->new($ssh, type => SSH_MSG_NONE);
    $pack->send;

    # Receive a packet.
    my $pack = Net::SSH::Perl::Packet->read($ssh);

=head1 DESCRIPTION

I<Net::SSH::Perl::Packet> implements the packet-layer piece
of the SSH protocol. Messages between server and client
are sent as binary data packets, which are encrypted
(once the two sides have agreed on the encryption
cipher, that is).

Packets are made up primarily of a packet type, which
describes the type of message and data contained
therein, and the data itself. In addition, each packet:
indicates its length in a 32-bit unsigned integer;
contains padding to pad the length of the packet to
a multiple of 8 bytes; and is verified by a 32-bit crc
checksum.

Refer to the SSH RFC for more details on the packet
protocol and the SSH protocol in general.

=head1 USAGE

=head2 Net::SSH::Perl::Packet->new($ssh, %params)

Creates/starts a new packet in memory. I<$ssh> is
a I<Net::SSH::Perl> object, which should already be connected
to an ssh daemon. I<%params> can contain the following
keys:

=over 4

=item * type

The message type of this packet. This should be one of
the values exported by I<Net::SSH::Perl::Constants> from the
I<msg> tag; for example, I<SSH_MSG_NONE>.

=item * data

A I<Net::SSH::Perl::Buffer> object containing the data in this
packet. Realistically, there aren't many times you'll need
to supply this argument: when sending a packet, it will be
created automatically; and when receiving a packet, the
I<read> method (see below) will create the buffer
automatically, as well.

=back

=head2 Net::SSH::Perl::Packet->read($ssh)

Reads a packet from the ssh daemon and returns that packet.

This method will block until an entire packet has been read.
The socket itself is non-blocking, but the method waits (using
I<select>) for data on the incoming socket, then processes
that data when it comes in. If the data makes up a complete
packet, the packet is returned to the caller. Otherwise I<read>
continues to try to read more data.

=head2 Net::SSH::Perl::Packet->read_poll($ssh)

Checks the data that's been read from the sshd to see if that
data comprises a complete packet. If so, that packet is
returned. If not, returns C<undef>.

This method does not block.

=head2 Net::SSH::Perl::Packet->read_expect($ssh, $type)

Reads the next packet from the daemon and dies if the
packet type does not match I<$type>. Otherwise returns
the read packet.

=head2 $packet->send([ $data ])

Sends a packet to the ssh daemon. I<$data> is optional,
and if supplied specifies the buffer to be sent in
the packet (should be a I<Net::SSH::Perl::Buffer> object).
In addition, I<$data>, if specified, I<must> include
the packed message type.

If I<$data> is not specified, I<send> sends the buffer
internal to the packet, which you've presumably filled
by calling the I<put_*> methods (see below).

=head2 $packet->type

Returns the message type of the packet I<$packet>.

=head2 $packet->data

Returns the message buffer from the packet I<$packet>;
a I<Net::SSH::Perl::Buffer> object.

=head2 Net::SSH::Perl::Buffer methods

Calling methods from the I<Net::SSH::Perl::Buffer> class on
your I<Net::SSH::Perl::Packet> object will automatically
invoke those methods on the buffer object internal
to your packet object (which is created when your
object is constructed). For example, if you executed
the following code:

    my $packet = Net::SSH::Perl::Packet->new($ssh, type => SSH_CMSG_USER);
    $packet->put_str($user);

this would construct a new packet object I<$packet>,
then fill its internal buffer by calling the
I<put_str> method on it.

Refer to the I<Net::SSH::Perl::Buffer> documentation
(the I<GET AND PUT METHODS> section) for more details
on those methods.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
