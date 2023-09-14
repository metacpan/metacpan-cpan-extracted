package Net::Async::OSC;
use 5.020;
use Moo 2;
use feature 'signatures';
no warnings 'experimental::signatures';
use Carp 'croak';

our $VERSION = '0.01';

=head1 NAME

Net::Async::OSC - send/receive OSC asynchronously

=head1 SYNOPSIS

  my $loop = IO::Async::Loop->new();
  my $osc = Net::Async::OSC->new(
      loop => $loop,
  );

  $osc->connect('127.0.0.1', 4560)->get;
  $osc->send_osc(
      "/trigger/melody" => 'ii',
      1,0);

=cut

use Protocol::OSC;
use IO::Async::Loop;
use IO::Async::Socket;
use Socket 'pack_sockaddr_in', 'inet_aton'; # IPv6 support?!

has 'osc' => (
   is => 'lazy',
   default => sub { return Protocol::OSC->new },
);

has 'loop' => (
   is => 'lazy',
   default => sub { return IO::Async::Loop->new },
);

has 'socket' => (
    is => 'rw',
);

=head1 METHODS

=head2 C<< ->connect >>

  $osc->connect('127.0.0.1', 4560)->get;

Connect to host/port.

=cut

sub connect( $self, $host, $port ) {
    my $loop = $self->loop;
    my $pingback = IO::Async::Socket->new(
        on_recv => sub( $sock, $data, $addr, @rest ) {
            warn "Reply: $data";
        },
    );
    $loop->add( $pingback );
    # What about multihomed hosts?!
    return $pingback->connect(
        host => $host,
        service => $port,
        socktype => 'dgram'
    )->on_done(sub($socket) {
		$self->socket($socket)
	});
}

=head2 C<< ->send_osc >>

    $osc->send_osc(
        "/trigger/melody" => 'ii',
        1,0);

Sends an OSC message as a list. The list will be packed according to
L<OSC::Protocol>.

=cut

sub send_osc( $self, @message ) {
	my $osc = $self->osc;
	my $socket = $self->socket;
    my $data = $osc->message(@message); # pack
    $self->send_osc_msg( $data );
}

=head2 C<< ->send_osc_msg >>

    my $msg = $protocol->message(
        "/trigger/melody" => 'ii',
        1,0
    );
    $osc->send_osc_msg($msg);

Sends an pre-packed OSC message.

=cut

sub send_osc_msg( $self, $data ) {
    #say join " , " , @{ $osc->parse( $data ) };
    $self->socket->send( $data );
}

1;

=head1 SEE ALSO

L<Protocol::OSC>

=cut
