package Mojo::TFTPd;
use Mojo::Base 'Mojo::EventEmitter';

use Mojo::IOLoop;
use Mojo::TFTPd::Connection;
use Scalar::Util qw(weaken);

use constant DEBUG          => !!$ENV{MOJO_TFTPD_DEBUG};
use constant OPCODE_RRQ     => 1;
use constant OPCODE_WRQ     => 2;
use constant OPCODE_DATA    => 3;
use constant OPCODE_ACK     => 4;
use constant OPCODE_ERROR   => 5;
use constant OPCODE_OACK    => 6;
use constant MIN_BLOCK_SIZE => 8;
use constant MAX_BLOCK_SIZE => 65464;                      # From RFC 2348

our $VERSION = '0.05';

has connection_class   => 'Mojo::TFTPd::Connection';
has inactive_timeout   => 15;
has ioloop             => sub { Mojo::IOLoop->singleton };
has listen             => 'tftp://*:69';
has max_connections    => 1000;
has retransmit         => 0;
has retransmit_timeout => 2;
has retries            => 1;

sub start {
  my $self = shift;
  return $self if $self->{connections};

  # split $self->listen into host and port
  my ($host, $port) = $self->_parse_listen;
  warn "[Mojo::TFTPd] Listen to $host:$port\n" if DEBUG;

  my $socket = IO::Socket::INET->new(LocalAddr => $host, LocalPort => $port, Proto => 'udp');
  return $self->emit(error => "Can't create listen socket: $!") unless $socket;

  my $reactor = $self->ioloop->reactor;
  weaken $self;
  $socket->blocking(0);
  $reactor->io($socket, sub { $self->_incoming });
  $reactor->watch($socket, 1, 0);    # watch read events
  $self->{connections} = {};
  $self->{socket}      = $socket;

  return $self;
}

sub _delete_connection {
  my ($self, $connection) = @_;
  delete $self->{connections}{$connection->peername};
  $self->ioloop->remove($connection->{timer}) if $connection->{timer};
  $self->emit(finish => $connection, $connection->error);
}

sub _incoming {
  my $self   = shift;
  my $socket = $self->{socket};

  # Add 4 Bytes of Opcode + Block#
  return $self->emit(error => "Read: $!")
    unless defined(my $read = $socket->recv(my $datagram, MAX_BLOCK_SIZE + 4));

  my $opcode = unpack 'n', substr $datagram, 0, 2, '';
  if ($opcode eq OPCODE_RRQ) {
    return $self->_new_request(rrq => $datagram);
  }
  elsif ($opcode eq OPCODE_WRQ) {
    return $self->_new_request(wrq => $datagram);
  }

  my $connection = $self->{connections}{$socket->peername};
  return $self->emit(error => "@{[$socket->peerhost]} has no connection") unless $connection;

  if ($opcode == OPCODE_ACK) {
    $connection->receive_ack($datagram)
      ? $self->_reset_timer($connection)
      : $self->_delete_connection($connection);
  }
  elsif ($opcode == OPCODE_DATA) {
    $connection->receive_data($datagram)
      ? $self->_reset_timer($connection)
      : $self->_delete_connection($connection);
  }
  elsif ($opcode == OPCODE_ERROR) {
    $connection->receive_error($datagram);
    $self->_delete_connection($connection);
  }
  else {
    $connection->error('Unknown opcode');
    $self->_delete_connection($connection);
  }
}

sub _new_request {
  my ($self, $type, $datagram) = @_;
  my ($file, $mode, @rfc) = split "\0", $datagram;
  my $socket = $self->{socket};
  warn "[Mojo::TFTPd] <<< @{[$socket->peerhost]} new request $type $file $mode @rfc\n" if DEBUG;

  return $self->emit(error => "Cannot handle $type requests") unless $self->has_subscribers($type);
  return $self->emit(error => "Max connections ($self->{max_connections}) reached")
    if $self->max_connections <= keys %{$self->{connections}};

  my %rfc        = @rfc;
  my $connection = $self->connection_class->new(
    type       => $type,
    file       => $file,
    mode       => $mode,
    peerhost   => $socket->peerhost,
    peername   => $socket->peername,
    retries    => $self->retries,
    timeout    => $self->retransmit ? $self->retransmit_timeout : $self->inactive_timeout,
    retransmit => $self->retransmit,
    rfc        => \%rfc,
    socket     => $socket,
  );

  if ($rfc{blksize}) {
    $rfc{blksize} = MIN_BLOCK_SIZE if $rfc{blksize} < MIN_BLOCK_SIZE;
    $rfc{blksize} = MAX_BLOCK_SIZE if $rfc{blksize} > MAX_BLOCK_SIZE;
    $connection->blocksize($rfc{blksize});
  }
  if ($rfc{timeout} and $rfc{timeout} >= 0 and $rfc{timeout} <= 255) {
    $connection->timeout($rfc{timeout});
  }
  if ($type eq 'wrq' and $rfc{tsize}) {
    $connection->filesize($rfc{tsize});
  }

  $self->emit($type => $connection);

  if (!$connection->filehandle) {
    $connection->send_error(file_not_found => $connection->error || 'No filehandle');
    $self->_reset_timer($connection);
  }
  elsif (%rfc and $connection->send_oack) {
    $self->{connections}{$connection->peername} = $connection;
    $self->_reset_timer($connection);
  }
  elsif ($type eq 'rrq' ? $connection->send_data : $connection->send_ack) {
    $self->{connections}{$connection->peername} = $connection;
    $self->_reset_timer($connection);
  }
  else {
    $self->emit(finish => $connection, $connection->error);
  }
}

sub _parse_listen {
  my $self = shift;

  my ($scheme, $host, $port) = $self->listen =~ m!
      (?: ([^:/]+) :// )?   # part before ://
      ([^:]*)               # everyting until a :
      (?: : (\d+) )?        # any digits after the :
    !xms;

  $port = getservbyname($scheme, '') if $scheme && !defined $port;
  $port //= 69;
  $host = '0.0.0.0' if $host eq '*';

  return ($host, $port);
}

sub _reset_timer {
  my ($self, $connection) = @_;

  $self->ioloop->remove($connection->{timer}) if $connection->{timer};
  $connection->{timer} = $self->ioloop->recurring(
    $connection->timeout,
    sub {
      $connection->send_retransmit or $self->_delete_connection($connection);
    }
  );
}

sub DESTROY {
  return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
  my $self = shift;
  $self->ioloop->reactor->remove($self->{socket}) if $self->{socket};
}

1;

=encoding utf8

=head1 NAME

Mojo::TFTPd - Trivial File Transfer Protocol daemon

=head1 VERSION

0.04

=head1 SYNOPSIS

  use Mojo::TFTPd;
  my $tftpd = Mojo::TFTPd->new;

  $tftpd->on(error => sub ($tftpd, $error) { warn "TFTPd: $error\n" });

  $tftpd->on(rrq => sub ($tftpd, $connection) {
    open my $FH, '<', $connection->file;
    $connection->filehandle($FH);
    $connection->filesize(-s $connection->file);
  });

  $tftpd->on(wrq => sub ($tftpd, $connection) {
    open my $FH, '>', '/dev/null';
    $connection->filehandle($FH);
  });

  $tftpd->on(finish => sub ($tftpd, $connection, $error) {
    warn "Connection: $error\n" if $error;
  });

  $tftpd->start;
  $tftpd->ioloop->start unless $tftpd->ioloop->is_running;

=head1 DESCRIPTION

This module implements a server for the
L<Trivial File Transfer Protocol|http://en.wikipedia.org/wiki/Trivial_File_Transfer_Protocol>.

From Wikipedia:

  Trivial File Transfer Protocol (TFTP) is a file transfer protocol notable
  for its simplicity. It is generally used for automated transfer of
  configuration or boot files between machines in a local environment.

The connection which is referred to in this document is an instance of
L<Mojo::TFTPd::Connection>.

=head1 EVENTS

=head2 error

  $tftpd->on(error => sub ($tftpd, $str) { ... });

This event is emitted when something goes wrong: Fail to L</listen> to socket,
read from socket or other internal errors.

=head2 finish

  $tftpd->on(finish => sub ($tftpd, $connection, $error) { ... });

This event is emitted when the L<Mojo::TFTPd::Connection> finish, either
successfully or due to an error. C<$error> will be an empty string on success.

=head2 rrq

  $tftpd->on(rrq => sub ($tftpd, $connection) { ... });

This event is emitted when a new read request arrives from a client. The
callback should set L<Mojo::TFTPd::Connection/filehandle> or the connection
will be dropped.
L<Mojo::TFTPd::Connection/filehandle> can also be a L<Mojo::Asset> reference.

=head2 wrq

  $tftpd->on(wrq => sub ($tftpd, $connection) { ... });

This event is emitted when a new write request arrives from a client. The
callback should set L<Mojo::TFTPd::Connection/filehandle> or the connection
will be dropped.
L<Mojo::TFTPd::Connection/filehandle> can also be a L<Mojo::Asset> reference.

=head1 ATTRIBUTES

=head2 connection_class

  $str = $tftpd->connection_class;
  $tftpd = $tftpd->connection_class($str);

Used to set a custom connection class. Defaults to L<Mojo::TFTPd::Connection>.

=head2 inactive_timeout

  $num = $tftpd->inactive_timeout;
  $tftpd = $tftpd->inactive_timeout(15);

How long a L<connection|Mojo::TFTPd::Connection> can stay idle before
being dropped. Default is 15 seconds.

=head2 ioloop

  $loop = $tftpd->ioloop;
  $tftpd = $tftpd->ioloop(Mojo::IOLoop->new);

Holds an instance of L<Mojo::IOLoop>.

=head2 listen

  $str = $tftpd->listen;
  $tftpd = $tftpd->listen('127.0.0.1:69');
  $tftpd = $tftpd->listen('tftp://*:69');

The bind address for this server.

=head2 max_connections

  $int = $tftpd->max_connections;
  $tftpd = $tftpd->max_connections(1000);

How many concurrent connections this server can handle. Default to 1000.

=head2 retransmit

  $int = $tftpd->retransmit;
  $tftpd = $tftpd->retransmit(1);

How many times the server should try to retransmit the last packet on timeout before
dropping the L<connection|Mojo::TFTPd::Connection>. Default is 0 (disable retransmits)

=head2 retransmit_timeout

  $num = $tftpd->retransmit_timeout;
  $tftpd = $tftpd->retransmit_timeout(2);

How long a L<connection|Mojo::TFTPd::Connection> can stay idle before last packet
being retransmitted. Default is 2 seconds.

=head2 retries

  $int = $tftpd->retries;
  $tftpd = $tftpd->retries(1);

How many times the server should try to send ACK or DATA to the client before
dropping the L<connection|Mojo::TFTPd::Connection>.

=head1 METHODS

=head2 start

  $tftpd = $tftpd->start;

Starts listening to the address and port set in L</Listen>. The L</error>
event will be emitted if the server fail to start.

=head1 AUTHOR

Svetoslav Naydenov - C<harryl@cpan.org>

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
