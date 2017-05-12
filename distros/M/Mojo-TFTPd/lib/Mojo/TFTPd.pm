package Mojo::TFTPd;

=head1 NAME

Mojo::TFTPd - Trivial File Transfer Protocol daemon

=head1 VERSION

0.04

=head1 SYNOPSIS

    use Mojo::TFTPd;
    my $tftpd = Mojo::TFTPd->new;

    $tftpd->on(error => sub {
        warn "TFTPd: $_[1]\n";
    });

    $tftpd->on(rrq => sub {
        my($tftpd, $c) = @_;
        open my $FH, '<', $c->file;
        $c->filehandle($FH);
        $c->filesize(-s $c->file);
    });

    $tftpd->on(wrq => sub {
        my($tftpd, $c) = @_;
        open my $FH, '>', '/dev/null';
        $c->filehandle($FH);
    });

    $tftpd->on(finish => sub {
        my($tftpd, $c, $error) = @_;
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

The connection ($c) which is referred to in this document is an instance of
L<Mojo::TFTPd::Connection>.

=cut

use Mojo::Base 'Mojo::EventEmitter';
use Mojo::IOLoop;
use Mojo::TFTPd::Connection;
use constant OPCODE_RRQ => 1;
use constant OPCODE_WRQ => 2;
use constant OPCODE_DATA => 3;
use constant OPCODE_ACK => 4;
use constant OPCODE_ERROR => 5;
use constant OPCODE_OACK => 6;
use constant MIN_BLOCK_SIZE => 8;
use constant MAX_BLOCK_SIZE => 65464; # From RFC 2348
use constant DEBUG => $ENV{MOJO_TFTPD_DEBUG} ? 1 : 0;

our $VERSION = '0.04';

=head1 EVENTS

=head2 error

    $self->on(error => sub {
        my($self, $str) = @_;
    });

This event is emitted when something goes wrong: Fail to L</listen> to socket,
read from socket or other internal errors.

=head2 finish

    $self->on(finish => sub {
        my($self, $c, $error) = @_;
    });

This event is emitted when the client finish, either successfully or due to an
error. C<$error> will be an empty string on success.

=head2 rrq

    $self->on(rrq => sub {
        my($self, $c) = @_;
    });

This event is emitted when a new read request arrives from a client. The
callback should set L<Mojo::TFTPd::Connection/filehandle> or the connection
will be dropped.
L<Mojo::TFTPd::Connection/filehandle> can also be a L<Mojo::Asset> reference.

=head2 wrq

    $self->on(wrq => sub {
        my($self, $c) = @_;
    });

This event is emitted when a new write request arrives from a client. The
callback should set L<Mojo::TFTPd::Connection/filehandle> or the connection
will be dropped.
L<Mojo::TFTPd::Connection/filehandle> can also be a L<Mojo::Asset> reference.

=head1 ATTRIBUTES

=head2 connection_class

  $str = $self->connection_class;
  $self = $self->connection_class($str);

Used to set a custom connection class. Defaults to L<Mojo::TFTPd::Connection>.

=cut

has connection_class => 'Mojo::TFTPd::Connection';

=head2 ioloop

Holds an instance of L<Mojo::IOLoop>.

=cut

has ioloop => sub { Mojo::IOLoop->singleton };

=head2 listen

    $str = $self->server;
    $self->server("127.0.0.1:69");
    $self->server("tftp://*:69"); # any interface

The bind address for this server.

=cut

has listen => 'tftp://*:69';

=head2 max_connections

How many concurrent connections this server can handle. Default to 1000.

=cut

has max_connections => 1000;

=head2 retries

How many times the server should try to send ACK or DATA to the client before
dropping the L<connection|Mojo::TFTPd::Connection>.

=cut

has retries => 1;

=head2 inactive_timeout

How long a L<connection|Mojo::TFTPd::Connection> can stay idle before
being dropped. Default is 15 seconds.

=cut

has inactive_timeout => 15;

=head2 retransmit

How many times the server should try to retransmit the last packet on timeout before
dropping the L<connection|Mojo::TFTPd::Connection>. Default is 0 (disable retransmits)

=cut

has retransmit => 0;

=head2 retransmit_timeout

How long a L<connection|Mojo::TFTPd::Connection> can stay idle before last packet 
being retransmitted. Default is 2 seconds.

=cut

has retransmit_timeout => 2;


=head1 METHODS

=head2 start

Starts listening to the address and port set in L</Listen>. The L</error>
event will be emitted if the server fail to start.

=cut

sub start {
    my $self = shift;
    my $reactor = $self->ioloop->reactor;
    my $socket;

    $self->{connections} and return $self;
    $self->{connections} = {};

    # split $self->listen into host and port
    my ($host, $port) = $self->_parse_listen;

    warn "[Mojo::TFTPd] Listen to $host:$port\n" if DEBUG;

    $socket = IO::Socket::INET->new(
                  LocalAddr => $host,
                  LocalPort => $port,
                  Proto => 'udp',
              );

    if(!$socket) {
        delete $self->{connections};
        return $self->emit(error => "Can't create listen socket: $!");
    };

    Scalar::Util::weaken($self);

    $socket->blocking(0);
    $reactor->io($socket, sub { $self->_incoming });
    $reactor->watch($socket, 1, 0); # watch read events
    $self->{socket} = $socket;

    return $self;
}

sub _incoming {
    my $self = shift;
    my $socket = $self->{socket};
    my $read = $socket->recv(my $datagram, MAX_BLOCK_SIZE + 4); # Add 4 Bytes of Opcode + Block#
    my($opcode, $connection);
    my $keep = 0;

    if(!defined $read) {
        return $self->emit(error => "Read: $!");
    }

    $opcode = unpack 'n', substr $datagram, 0, 2, '';

    # new connection
    if($opcode eq OPCODE_RRQ) {
        return $self->_new_request(rrq => $datagram);
    }
    elsif($opcode eq OPCODE_WRQ) {
        return $self->_new_request(wrq => $datagram);
    }

    # existing connection
    $connection = $self->{connections}{$socket->peername};

    if(!$connection) {
        return $self->emit(error => "@{[$socket->peerhost]} has no connection");
    }

    # Stop retransmit/inactive timer
    $self->ioloop->remove($connection->{timer});
    delete $connection->{timer};


    if($opcode == OPCODE_ACK) {
        $keep = $connection->receive_ack($datagram);
    }
    elsif($opcode == OPCODE_DATA) {
        $keep = $connection->receive_data($datagram);
    }
    elsif($opcode == OPCODE_ERROR) {
        $connection->receive_error($datagram);
    }
    else {
        $connection->error('Unknown opcode');
    }

    if ($keep) {
        # restart retransmit/inactive timer
        $connection->{timer} = $self->ioloop->recurring($connection->timeout => sub {
            $connection->send_retransmit or $self->_delete_connection($connection);
        });
        return;
    }

    # if something goes wrong or finish with connection
    $self->_delete_connection($connection);
}

sub _new_request {
    my($self, $type, $datagram) = @_;
    my($file, $mode, @rfc) = split "\0", $datagram;
    my $socket = $self->{socket};
    my $connection;
    my $keep = 0;

    warn "[Mojo::TFTPd] <<< @{[$socket->peerhost]} $type $file $mode @rfc\n" if DEBUG;

    if(!$self->has_subscribers($type)) {
        $self->emit(error => "Cannot handle $type requests");
        return;
    }
    if($self->max_connections <= keys %{ $self->{connections} }) {
        $self->emit(error => "Max connections ($self->{max_connections}) reached");
        return;
    }

    my %rfc = @rfc;
    $connection = $self->connection_class->new(
                        type => $type,
                        file => $file,
                        mode => $mode,
                        peerhost => $socket->peerhost,
                        peername => $socket->peername,
                        retries => $self->retries,
                        timeout => $self->retransmit ? $self->retransmit_timeout : $self->inactive_timeout,
                        retransmit => $self->retransmit,
                        rfc => \%rfc,
                        socket => $socket,
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
        $keep = 1;
    }
    elsif ((%rfc and $connection->send_oack) 
        or $type eq 'rrq' ? $connection->send_data : $connection->send_ack) {
        $keep = 1;
    }

    if ($keep) {
        $self->{connections}{$connection->peername} = $connection;
        # start retransmit/inactive timer
        $connection->{timer} = $self->ioloop->recurring($connection->timeout => sub {
            $connection->send_retransmit or $self->_delete_connection($connection);
        });
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

    # if scheme is set but no port, use scheme
    $port = getservbyname($scheme, '') if $scheme && !defined $port;

    # use port 69 as fallback
    $port //= 69;

    # if host == '*', replace it with '0.0.0.0'
    $host = '0.0.0.0' if $host eq '*';

    return ($host, $port);
}

sub _delete_connection {
    my($self, $connection) = @_;
    $self->ioloop->remove($connection->{timer}) if $connection->{timer};
    delete $self->{connections}{$connection->peername};
    $self->emit(finish => $connection, $connection->error);
}

sub DEMOLISH {
    my $self = shift;
    my $reactor = eval { $self->ioloop->reactor } or return; # may be undef during global destruction

    $reactor->remove($self->{socket}) if $self->{socket};
}

=head1 AUTHOR

Svetoslav Naydenov - C<harryl@cpan.org>

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
