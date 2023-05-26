package SPVM::IO::Socket::INET;

1;

=head1 Name

SPVM::IO::Socket::INET - IPv4 Socket

=head1 Usage

  use IO::Socket::INET;
  use Sys::Socket;
  use Sys::Socket::Constant as SOCKET;

  # Socket
  my $host = "google.com";
  my $port = 80;
  my $io_socket = IO::Socket::INET->new({
    PeerAddr => $host,
    PeerPort => $port
  });
  
  my $io_socket = IO::Socket::INET->new({
    PeerAddr => 'www.perl.org',
    PeerPort => 80,
    Proto    => SOCKET->IPPROTO_TCP
  });
 
  my $io_socket = IO::Socket::INET->new({
    Listen    => 5,
    LocalAddr => 'localhost',
    LocalPort => 9000,
    Proto     => SOCKET->IPPROTO_TCP
  });
   
  my $io_socket = IO::Socket::INET->new({
    PeerPort  => 9999,
    PeerAddr  => Sys::Socket->inet_ntoa(SOCKET->INADDR_BROADCAST),
    Proto     => SOCKET->IPPROTO_UDP,
    LocalAddr => 'localhost',
    Broadcast => 1
  })

=head1 Description

C<IO::Socket::INET> provides IPv4 Socket.

=head1 Super Class

L<IO::Socket|SPVM::IO::Socket>

=head1 Fields

=head2 peer_address

  has peer_address : string;

=head2 peer_port

  has peer_port : int;

=head2 local_address

  has local_address : string;

=head2 local_port

  has local_port : int;

=head2 proto_number

  has proto_number : int;

=head1 Class Methods

=head2 new

  static method new : IO::Socket::INET ($options = undef : object[]);

=head3 new Options

=over 2

=item * ReuseAddr : string
  
=item * ReusePort : Int
  
=item * Broadcast : Int

=item * PeerAddr : string

=item * PeerPort : Int

=item * LocalAddr : string

=item * LocalPort : Int

=item * Proto : Int

=item * Timeout : Int

=item * Domain : Int

=item * Type : Int

=item * Blocking : Int

=item * Listen : Int

=back

=head1 Instance Methods

=head2 init

  protected method init : void ($options = undef : object[]);

=head2 sockaddr

  method sockaddr : Sys::Socket::In_addr ();

=head2 sockport

  method sockport : int ();

=head2 sockhost

  method sockhost : string ();

=head2 peeraddr

  method peeraddr : Sys::Socket::In_addr ();

=head2 peerport

  method peerport : int ();

=head2 peerhost

  method peerhost : string ();

=head1 See Also

=head2 Perl's IO::Socket::INET

C<IO::Socket::INET> is a Perl's L<IO::Socket::INET|IO::Socket::INET> porting to L<SPVM>.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

