package Mojo::TFTPd::Connection;

=head1 NAME

Mojo::TFTPd::Connection - A connection class for Mojo::TFTPd

=head1 SYNOPSIS

See L<Mojo::TFTPd>

=cut

use Mojo::Base -base;
use Socket();
use constant OPCODE_DATA => 3;
use constant OPCODE_ACK => 4;
use constant OPCODE_ERROR => 5;
use constant OPCODE_OACK => 6;
use constant DEBUG => $ENV{MOJO_TFTPD_DEBUG} ? 1 : 0;

our %ERROR_CODES = (
    not_defined => [0, 'Not defined, see error message'],
    unknown_opcode => [0, 'Unknown opcode: %s'],
    no_connection => [0, 'No connection'],
    file_not_found => [1, 'File not found'],
    access_violation => [2, 'Access violation'],
    disk_full => [3, 'Disk full or allocation exceeded'],
    illegal_operation => [4, 'Illegal TFTP operation'],
    unknown_transfer_id => [5, 'Unknown transfer ID'],
    file_exists => [6, 'File already exists'],
    no_such_user => [7, 'No such user'],
);

BEGIN {
    # do not use MSG_DONTWAIT on platforms that do not support it (Win32)
    my $msg_dontwait = 0;
    eval { $msg_dontwait = Socket::MSG_DONTWAIT };
    sub MSG_DONTWAIT() { $msg_dontwait };
}


=head1 ATTRIBUTES

=head2 type

Type of connection rrq or wrq

=head2 blocksize

The negotiated blocksize.
Default is 512 Byte.

=head2 error

Useful to check inside L<Mojo::TFTPd/finish> events to see if anything has
gone wrong. Holds a string describing the error.

=head2 file

The filename the client requested to read or write.

=head2 filehandle

This must be set inside the L<rrq|Mojo::TFTPd/rrq> or L<wrq|Mojo::TFTPd/wrq>
event or the connection will be dropped.
Can be either L<Mojo::Asset> or filehandle.

=head2 filesize

This must be set inside the L<rrq|Mojo::TFTPd/rrq>
to report "tsize" option if client requested.

If set inside L<wrq|Mojo::TFTPd/wrq> limits maximum upload size.
Set automatically on WRQ with "tsize" option.

Can be used inside L<finish|Mojo::TFTPd/finish> for uploads
to check if reported "tsize" and received data length match.

=head2 timeout

Retransmit/Inactive timeout.

=head2 lastop

Last operation.

=head2 mode

Either "netascii", "octet" or empty string if unknown.

=head2 peerhost

The IP address of the remote client.

=head2 peername

Packet address of the remote client.

=head2 retries

Number of times L</send_data>, L</send_ack> or L</send_oack> can be retried before the
connection is dropped.
This value comes from L<Mojo::TFTPd/retries> or set inside L<rrq|Mojo::TFTPd/rrq> or L<wrq|Mojo::TFTPd/wrq>
events.

=head2 retransmit

Number of times last operation (L</send_data>, L</send_ack> or L</send_oack>)
to be retransmitted on timeout before the connection is dropped.
This value comes from L<Mojo::TFTPd/retransmit> or set inside L<rrq|Mojo::TFTPd/rrq> or L<wrq|Mojo::TFTPd/wrq>
events.

Retransmits are disabled if set to 0.

=head2 socket

The UDP handle to send data to.

=head2 rfc

Contains RFC 2347 options the client has provided. These options are stored
in an hash ref.

=cut

has type => undef;
has blocksize => 512;
has error => '';
has file => '/dev/null';
has filehandle => undef;
has filesize => undef;
has timeout => undef;
has lastop => undef;
has mode => '';
has peerhost => '';
has peername => '';
has retries => 2;
has retransmit => 0;
has rfc => sub { {} };
has socket => undef;
has _attempt => 0;
has _sequence_number => 1;

use constant ROLLOVER => 256 * 256;

=head1 METHODS

=head2 send_data

This method is called when the server sends DATA to the client.

=cut

sub send_data {
    my $self = shift;
    my $FH = $self->filehandle;
    my $n = $self->_sequence_number;
    my $seq = $n % ROLLOVER;
    my($data, $sent);

    $self->{lastop} = OPCODE_DATA;

    if (UNIVERSAL::isa($FH, 'Mojo::Asset')) {
        $data = $FH->get_chunk(($n - 1) * $self->blocksize, $self->blocksize);
        return $self->send_error(file_not_found => 'Unable to read chunk') unless defined $data;
    }
    else {
        if(not seek $FH, ($n - 1) * $self->blocksize, 0) {
            return $self->send_error(file_not_found => "Seek: $!");
        }
        if(not defined read $FH, $data, $self->blocksize) {
            return $self->send_error(file_not_found => "Read: $!");
        }
    }

    if(length $data < $self->blocksize) {
        $self->{_last_sequence_number} = $n;
    }

    warn "[Mojo::TFTPd] >>> $self->{peerhost} data $seq (@{[length $data]})" .
        ($self->_attempt ? " retransmit $self->{_attempt}" : '') . "\n" if DEBUG;

    $sent = $self->socket->send(
                pack('nna*', OPCODE_DATA, $seq, $data),
                MSG_DONTWAIT,
                $self->peername,
            );

    return 0 unless length $data;
    return 1 if $sent or $self->{retries}--;
    $self->error("Send: $!");
    return 0;
}

=head2 receive_ack

This method is called when the client sends ACK to the server.

=cut

sub receive_ack {
    my $self = shift;
    my($n) = unpack 'n', shift;
    my $seq = $self->_sequence_number % ROLLOVER;

    warn "[Mojo::TFTPd] <<< $self->{peerhost} ack $n" .
        ($n && $n != $seq ? " expected $seq" : '') . "\n" if DEBUG;

    return $self->send_data if $n == 0 and $self->lastop eq OPCODE_OACK;
    return 0 if $self->lastop eq OPCODE_ERROR;
    return 0 if $self->{_last_sequence_number} and $n == $self->{_last_sequence_number} % ROLLOVER;
    if ($n == $seq) {
        $self->{_attempt} = 0;
        $self->{_sequence_number}++;
        return $self->send_data;
    }

    return 1 if $self->retransmit and $n < $seq;

    return $self->send_data if $self->{retries}--;
    $self->error('Invalid packet number');
    return 0;
}

=head2 receive_data

This method is called when the client sends DATA to the server.

=cut

sub receive_data {
    my $self = shift;
    my($n, $data) = unpack 'na*', shift;
    my $FH = $self->filehandle;
    my $seq = $self->_sequence_number % ROLLOVER;

    warn "[Mojo::TFTPd] <<< $self->{peerhost} data $n (@{[length $data]})" .
        ($n != $seq ? " expected $seq" : '') . "\n" if DEBUG;

    unless ($n == $seq) {
        return 1 if $self->retransmit and $n < $seq;
        return $self->send_ack if $self->{retries}--;
        $self->error('Invalid packet number');
        return 0;
    }

    if (UNIVERSAL::isa($FH, 'Mojo::Asset')) {
        local $!;
        eval { $FH->add_chunk($data) };
        return $self->send_error(illegal_operation => "Unable to add chunk $!") if $!;
    }
    else {
        unless(print $FH $data) {
            return $self->send_error(illegal_operation => "Write: $!");
        }
    }

    unless(length $data == $self->blocksize) {
        $self->{_last_sequence_number} = $n;
    }

    return $self->send_error(disk_full => 'tsize exceeded')
        if $self->filesize and $self->filesize < $self->blocksize * ($n-1) + length $data;

    $self->{_sequence_number}++;
    return $self->send_ack;
}

=head2 send_ack

This method is called when the server sends ACK to the client.

=cut

sub send_ack {
    my $self = shift;
    my $n = $self->_sequence_number - 1;
    my $seq = $n % ROLLOVER;
    my $sent;

    $self->{lastop} = OPCODE_ACK;
    warn "[Mojo::TFTPd] >>> $self->{peerhost} ack $seq" .
        ($self->_attempt ? " retransmit $self->{_attempt}" : '') . "\n" if DEBUG;

    $sent = $self->socket->send(
                pack('nn', OPCODE_ACK, $seq),
                MSG_DONTWAIT,
                $self->peername,
            );

    return 0 if defined $self->{_last_sequence_number};
    return 1 if $sent or $self->{retries}--;
    $self->error("Send: $!");
    return 0;
}

=head2 receive_error

This method is called when the client sends ERROR to the server.

=cut

sub receive_error {
    my $self = shift;
    my($code, $msg) = unpack 'nZ*', shift;

    warn "[Mojo::TFTPd] <<< $self->{peerhost} error $code $msg\n" if DEBUG;

    $self->error("($code) $msg");
    return 0;
}


=head2 send_error

Used to report error to the client.

=cut

sub send_error {
    my($self, $name) = @_;
    my $err = $ERROR_CODES{$name} || $ERROR_CODES{not_defined};

    $self->{lastop} = OPCODE_ERROR;
    warn "[Mojo::TFTPd] >>> $self->{peerhost} error @$err\n" if DEBUG;

    $self->error($_[2]);
    $self->socket->send(
        pack('nnZ*', OPCODE_ERROR, @$err),
        MSG_DONTWAIT,
        $self->peername,
    );

    return 0;
}


=head2 send_oack

Used to send RFC 2347 OACK to client

Supported options are

=over

=item RFC 2348 blksize - report $self->blocksize

=item RFC 2349 timeout - report $self->timeout

=item RFC 2349 tsize - report $self->filesize if set inside the L<rrq|Mojo::TFTPd/rrq>

=back

=cut

sub send_oack {
    my $self = shift;
    my $sent;

    $self->{lastop} = OPCODE_OACK;

    my @options;
    push @options, 'blksize', $self->blocksize if $self->rfc->{blksize};
    push @options, 'timeout', $self->timeout if $self->rfc->{timeout};
    push @options, 'tsize', $self->filesize if exists $self->rfc->{tsize} and $self->filesize;

    warn "[Mojo::TFTPd] >>> $self->{peerhost} oack @options" .
        ($self->_attempt ? " retransmit $self->{_attempt}" : '') . "\n" if DEBUG;

    $sent = $self->socket->send(
                pack('na*', OPCODE_OACK, join "\0", @options),
                MSG_DONTWAIT,
                $self->peername,
            );

    return 1 if $sent or $self->{retries}--;
    $self->error("Send: $!");
    return 0;
}

=head2 send_retransmit

Used to retransmit last packet to the client.

=cut

sub send_retransmit {
    my $self = shift;

    return 0 unless $self->lastop;

    unless ($self->retransmit) {
        $self->error('Inactive timeout');
        return 0;
    }

    # Errors are not retransmitted
    return 0 if $self->lastop == OPCODE_ERROR;

    if ($self->_attempt >= $self->retransmit) {
        $self->error('Retransmit timeout');
        return 0;
    }

    $self->{_attempt}++;

    return $self->send_oack if $self->lastop eq OPCODE_OACK;
    return $self->send_ack if $self->lastop eq OPCODE_ACK;
    return $self->send_data if $self->lastop eq OPCODE_DATA;

    return 0;
 }


=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
