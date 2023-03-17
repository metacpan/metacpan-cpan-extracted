package Mojo::TFTPd::Connection;
use Mojo::Base -base;

use Socket();
use Scalar::Util qw(blessed);

use constant DEBUG        => !!$ENV{MOJO_TFTPD_DEBUG};
use constant OPCODE_DATA  => 3;
use constant OPCODE_ACK   => 4;
use constant OPCODE_ERROR => 5;
use constant OPCODE_OACK  => 6;
use constant ROLLOVER     => 256 * 256;

our %ERROR_CODES = (
  not_defined         => [0, 'Not defined, see error message'],
  unknown_opcode      => [0, 'Unknown opcode: %s'],
  no_connection       => [0, 'No connection'],
  file_not_found      => [1, 'File not found'],
  access_violation    => [2, 'Access violation'],
  disk_full           => [3, 'Disk full or allocation exceeded'],
  illegal_operation   => [4, 'Illegal TFTP operation'],
  unknown_transfer_id => [5, 'Unknown transfer ID'],
  file_exists         => [6, 'File already exists'],
  no_such_user        => [7, 'No such user'],
);

BEGIN {
  # do not use MSG_DONTWAIT on platforms that do not support it (Win32)
  my $msg_dontwait = 0;
  eval { $msg_dontwait = Socket::MSG_DONTWAIT };
  sub MSG_DONTWAIT() {$msg_dontwait}
}

has blocksize        => 512;
has error            => '';
has file             => '/dev/null';
has filehandle       => undef;
has filesize         => undef;
has lastop           => undef;
has mode             => '';
has peerhost         => '';
has peername         => '';
has retransmit       => 0;
has retries          => 2;
has rfc              => sub { +{} };
has socket           => undef;
has timeout          => undef;
has type             => undef;
has _attempt         => 0;
has _sequence_number => 1;

sub receive_ack {
  my $self = shift;
  my ($n)  = unpack 'n', shift;
  my $seq  = $self->_sequence_number % ROLLOVER;

  DEBUG && warn "[Mojo::TFTPd] <<< %s ack %s %s\n", $self->peerhost, $n,
    ($n && $n != $seq ? "expected $seq" : '');

  return $self->send_data if $n == 0 and $self->lastop eq OPCODE_OACK;
  return 0                if $self->lastop eq OPCODE_ERROR;
  return 0 if $self->{last_sequence_number} and $n == $self->{last_sequence_number} % ROLLOVER;

  if ($n == $seq) {
    $self->{_attempt} = 0;
    $self->{_sequence_number}++;
    return $self->send_data;
  }

  return 1                if $self->retransmit and $n < $seq;
  return $self->send_data if $self->{retries}--;
  $self->error('Invalid packet number');
  return 0;
}

sub receive_data {
  my $self = shift;
  my ($n, $data) = unpack 'na*', shift;
  my $seq = $self->_sequence_number % ROLLOVER;

  DEBUG && warn "[Mojo::TFTPd] <<< %s data %s (%s) %s\n", $self->peerhost, $n, length $data,
    ($n != $seq ? " expected $seq" : '');

  unless ($n == $seq) {
    return 1               if $self->retransmit and $n < $seq;
    return $self->send_ack if $self->{retries}--;
    $self->error('Invalid packet number');
    return 0;
  }

  my $handle = $self->filehandle;
  if (blessed $handle and $handle->isa('Mojo::Asset')) {
    local $!;
    eval { $handle->add_chunk($data) };
    return $self->send_error(illegal_operation => "Unable to add chunk $!") if $!;
  }
  elsif (!$handle->syswrite($data)) {
    return $self->send_error(illegal_operation => "Write: $!");
  }

  unless (length $data == $self->blocksize) {
    $self->{last_sequence_number} = $n;
  }

  return $self->send_error(disk_full => 'tsize exceeded')
    if $self->filesize and $self->filesize < $self->blocksize * ($n - 1) + length $data;

  $self->{_sequence_number}++;
  return $self->send_ack;
}

sub receive_error {
  my $self = shift;
  my ($code, $msg) = unpack 'nZ*', shift;

  warn "[Mojo::TFTPd] <<< $self->{peerhost} error $code $msg\n" if DEBUG;
  $self->error("($code) $msg");
  return 0;
}

sub send_ack {
  my $self = shift;
  $self->{lastop} = OPCODE_ACK;

  my $seq = ($self->_sequence_number - 1) % ROLLOVER;
  DEBUG && warn "[Mojo::TFTPd] <<< %s ack %s %s\n", $self->peerhost, $seq,
    ($self->_attempt ? " retransmit $self->{_attempt}" : '');

  my $sent = $self->socket->send(pack('nn', OPCODE_ACK, $seq), MSG_DONTWAIT, $self->peername);
  return 0 if defined $self->{last_sequence_number};
  return 1 if $sent or $self->{retries}--;
  $self->error("Send: $!");
  return 0;
}

sub send_data {
  my $self = shift;
  $self->{lastop} = OPCODE_DATA;

  my ($handle, $n, $data) = ($self->filehandle, $self->_sequence_number);
  if (blessed $handle and $handle->isa('Mojo::Asset')) {
    $data = $handle->get_chunk(($n - 1) * $self->blocksize, $self->blocksize);
    return $self->send_error(file_not_found => 'Unable to read chunk') unless defined $data;
  }
  elsif (not seek $handle, ($n - 1) * $self->blocksize, 0) {
    return $self->send_error(file_not_found => "Seek: $!");
  }
  elsif (not defined $handle->sysread($data, $self->blocksize)) {
    return $self->send_error(file_not_found => "Read: $!");
  }

  if (length $data < $self->blocksize) {
    $self->{last_sequence_number} = $n;
  }

  my $seq = $n % ROLLOVER;
  DEBUG && warn sprintf "[Mojo::TFTPd] >>> %s data %s (%s) %s\n", $self->{peerhost}, $seq,
    length $data, $self->_attempt ? "retransmit $self->{_attempt}" : '';

  my $sent
    = $self->socket->send(pack('nna*', OPCODE_DATA, $seq, $data), MSG_DONTWAIT, $self->peername);

  return 0 unless length $data;
  return 1 if $sent or $self->{retries}--;
  $self->error("Send: $!");
  return 0;
}

sub send_error {
  my ($self, $name) = @_;
  my $err = $ERROR_CODES{$name} || $ERROR_CODES{not_defined};

  $self->{lastop} = OPCODE_ERROR;
  warn "[Mojo::TFTPd] >>> $self->{peerhost} error @$err\n" if DEBUG;

  $self->error($_[2]);
  $self->socket->send(pack('nnZ*', OPCODE_ERROR, @$err), MSG_DONTWAIT, $self->peername);

  return 0;
}

sub send_oack {
  my $self = shift;
  $self->{lastop} = OPCODE_OACK;

  my @options;
  push @options, 'blksize', $self->blocksize if $self->rfc->{blksize};
  push @options, 'timeout', $self->timeout   if $self->rfc->{timeout};
  push @options, 'tsize',   $self->filesize  if exists $self->rfc->{tsize} and $self->filesize;

  warn "[Mojo::TFTPd] >>> $self->{peerhost} oack @options"
    . ($self->_attempt ? " retransmit $self->{_attempt}" : '') . "\n"
    if DEBUG;

  my $sent = $self->socket->send(pack('na*', OPCODE_OACK, join "\0", @options, ''),
    MSG_DONTWAIT, $self->peername);
  return 1 if $sent or $self->{retries}--;
  $self->error("Send: $!");
  return 0;
}

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
  return $self->send_ack  if $self->lastop eq OPCODE_ACK;
  return $self->send_data if $self->lastop eq OPCODE_DATA;
  return 0;
}

1;

=encoding utf8

=head1 NAME

Mojo::TFTPd::Connection - A connection class for Mojo::TFTPd

=head1 SYNOPSIS

See L<Mojo::TFTPd>

=head1 ATTRIBUTES

=head2 type

  $str = $connection->type;

Type of connection rrq or wrq

=head2 blocksize

  $int = $connection->blocksize;

The negotiated blocksize. Default is 512 Byte.

=head2 error

  $str = $connection->error;

Useful to check inside L<Mojo::TFTPd/finish> events to see if anything has
gone wrong. Holds a string describing the error.

=head2 file

  $str = $connection->file;

The filename the client requested to read or write.

=head2 filehandle

  $fh = $connection->filehandle;

This must be set inside the L<rrq|Mojo::TFTPd/rrq> or L<wrq|Mojo::TFTPd/wrq>
event or the connection will be dropped.
Can be either L<Mojo::Asset> or filehandle.

=head2 filesize

  $int = $connection->filesize;

This must be set inside the L<rrq|Mojo::TFTPd/rrq>
to report "tsize" option if client requested.

If set inside L<wrq|Mojo::TFTPd/wrq> limits maximum upload size.
Set automatically on WRQ with "tsize" option.

Can be used inside L<finish|Mojo::TFTPd/finish> for uploads
to check if reported "tsize" and received data length match.

=head2 timeout

  $num = $connection->timeout;

Retransmit/Inactive timeout.

=head2 lastop

  $str = $connection->lastop;

Last operation.

=head2 mode

  $str = $connection->mode;

Either "netascii", "octet" or empty string if unknown.

=head2 peerhost

  $str = $connection->peerhost;

The IP address of the remote client.

=head2 peername

  $bin = $connection->peername;

Packet address of the remote client.

=head2 retries

  $int = $connection->retries;

Number of times L</send_data>, L</send_ack> or L</send_oack> can be retried before the
connection is dropped.
This value comes from L<Mojo::TFTPd/retries> or set inside L<rrq|Mojo::TFTPd/rrq> or L<wrq|Mojo::TFTPd/wrq>
events.

=head2 retransmit

  $int = $connection->retransmit;

Number of times last operation (L</send_data>, L</send_ack> or L</send_oack>)
to be retransmitted on timeout before the connection is dropped.
This value comes from L<Mojo::TFTPd/retransmit> or set inside L<rrq|Mojo::TFTPd/rrq> or L<wrq|Mojo::TFTPd/wrq>
events.

Retransmits are disabled if set to 0.

=head2 socket

  $fh = $connection->socket;

The UDP handle to send data to.

=head2 rfc

  $hash_ref = $connection->rfc;

Contains RFC 2347 options the client has provided.

=head1 METHODS

=head2 receive_ack

  $bool = $connection->receive_ack($bytes);

This method is called when the client sends ACK to the server.

=head2 receive_data

  $bool = $connection->receive_data($bytes);

This method is called when the client sends DATA to the server.

=head2 receive_error

  $bool = $connection->receive_error($bytes);

This method is called when the client sends ERROR to the server.

=head2 send_ack

  $bool = $connection->send_ack;

This method is called when the server sends ACK to the client.

=head2 send_data

  $bool = $connection->send_data;

This method is called when the server sends DATA to the client.

=head2 send_error

  $bool = $connection->send_error($key => $descr);

Used to report error to the client.

=head2 send_oack

  $bool = $connection->send_oack;

Used to send RFC 2347 OACK to client

Supported options are

=over

=item RFC 2348 blksize

Report L</blocksize>.

=item RFC 2349 timeout

Report L</timeout>.

=item RFC 2349 tsize

Report L</filesize> if set inside the L<rrq|Mojo::TFTPd/rrq>.

=back

=head2 send_retransmit

  $bool = $connection->send_retransmit;

Used to retransmit last packet to the client.

=head1 SEE ALSO

L<Mojo::TFTPd>

=cut
