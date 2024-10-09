package SPVM::IO::Socket::IP;

1;

=head1 Name

SPVM::IO::Socket::IP - IPv4/IPv6 Sockets

=head1 Usage

  use IO::Socket::IP;
  use Sys::Socket;
  use Sys::Socket::Constant as SOCKET;
  
  # Client Socket
  my $host = "www.perl.org";
  my $port = 80;
  my $io_socket = IO::Socket::IP->new({
    PeerAddr => $host,
    PeerPort => $port
  });
  
  # Server Socket
  my $io_socket = IO::Socket::IP->new({
    LocalAddr => 'localhost',
    LocalPort => 9000,
    Listen    => 5,
  });
   
  # IPv6 Client Socket
  my $host = "google.com";
  my $port = 80;
  my $io_socket = IO::Socket::IP->new({
    PeerAddr => $host,
    PeerPort => $port,
    Domain => SOCKET->AF_INET6,
  });

=head1 Description

IO::Socket::INET class in L<SPVM> has methods to create IPv4/IPv6 Sockets.

=head1 Super Class

L<IO::Socket|SPVM::IO::Socket>

=head1 Fields

=head2 LocalAddr

C<has LocalAddr : protected string;>

A local address.

=head2 LocalPort

C<has LocalPort : protected int;>

A local port.

=head2 PeerAddr

C<has PeerAddr : protected string;>

A peer address.

=head2 PeerPort

C<has PeerPort : protected int;>

A peer port

=head2 ReuseAddr

C<has ReuseAddr : protected int;>

If this field is a true value, The L<SO_REUSEADDR|https://linux.die.net/man/3/setsockopt> socket option is set.

=head2 ReusePort

C<has ReusePort : protected int;>

If this field is a true value, The C<SO_REUSEPORT> socket option is set.

=head2 Broadcast

C<has Broadcast : protected int;>

If this field is a true value, The L<SO_BROADCAST|https://linux.die.net/man/3/setsockopt> socket option is set.

=head1 Class Methods

=head2 new

C<static method new : L<IO::Socket::IP|SPVM::IO::Socket::IP> ($options : object[] = undef);>

Creates a new L<IO::Socket::IP|SPVM::IO::Socket::IP> object.

And creates a socket.

And if L</"PeerAddr"> field is defined, L<connect|https://linux.die.net/man/2/connect> is executed.

And if L</"LocalPort"> field is defined, L<bind|https://linux.die.net/man/2/bind> and L<listen|https://linux.die.net/man/2/listen> are executed.

And returns the new object.

Options:

The following options are available adding the options for L<IO::Socket#new|SPVM::IO::Socket/"new"> method are available.

=over 2

=item * C<ReuseAddr> : string

L</"ReuseAddr"> field is set to this value.

=item * C<ReusePort> : Int

L</"ReusePort"> field is set to this value.

=item * C<Broadcast> : Int

L</"Broadcast"> field is set to this value.

=item * C<PeerAddr> : string

A peer address.

L</"PeerAddr"> field is set to this value.

=item * C<PeerPort> : Int

L</"PeerPort"> field is set to this value.

=item * C<LocalAddr> : string

L</"LocalAddr"> field is set to this value.

=item * C<LocalPort> : Int

L</"LocalPort"> field is set to this value.

=back

=head1 Instance Methods

=head2 init

C<protected method init : void ($options : object[] = undef);>

Initializes this instance.

=head2 sockaddr

C<method sockaddr : L<Sys::Socket::In_addr_base|SPVM::Sys::Socket::In_addr_base> ();>

Returns the local address.

If L</"Domain"> field is C<AF_INET>, this method calls L<IO::Socket::IP::Import::IPv4#sockaddr|IO::Socket::IP::Import::IPv4/"sockaddr"> method.

If L</"Domain"> field is C<AF_INET6>, this method calls L<IO::Socket::IP::Import::IPv6#sockaddr|IO::Socket::IP::Import::IPv6/"sockaddr"> method.

=head2 sockhost

C<method sockhost : string ();>

Returns the local host name.

If L</"Domain"> field is C<AF_INET>, this method calls L<IO::Socket::IP::Import::IPv4#sockhost|IO::Socket::IP::Import::IPv4/"sockhost"> method.

If L</"Domain"> field is C<AF_INET6>, this method calls L<IO::Socket::IP::Import::IPv6#sockhost|IO::Socket::IP::Import::IPv6/"sockhost"> method.

=head2 sockport

C<method sockport : int ();>

Returns the local port.

If L</"Domain"> field is C<AF_INET>, this method calls L<IO::Socket::IP::Import::IPv4#sockport|IO::Socket::IP::Import::IPv4/"sockport"> method.

If L</"Domain"> field is C<AF_INET6>, this method calls L<IO::Socket::IP::Import::IPv6#sockport|IO::Socket::IP::Import::IPv6/"sockport"> method.

=head2 peeraddr

C<method peeraddr : L<Sys::Socket::In_addr_base|SPVM::Sys::Socket::In_addr_base> ();>

Return the peer address.

If L</"Domain"> field is C<AF_INET>, this method calls L<IO::Socket::IP::Import::IPv4#peeraddr|IO::Socket::IP::Import::IPv4/"peeraddr"> method.

If L</"Domain"> field is C<AF_INET6>, this method calls L<IO::Socket::IP::Import::IPv6#peeraddr|IO::Socket::IP::Import::IPv6/"peeraddr"> method.

=head2 peerhost

C<method peerhost : string ();>

Returns the peer host name.

If L</"Domain"> field is C<AF_INET>, this method calls L<IO::Socket::IP::Import::IPv4#peerhost|IO::Socket::IP::Import::IPv4/"peerhost"> method.

If L</"Domain"> field is C<AF_INET6>, this method calls L<IO::Socket::IP::Import::IPv6#peerhost|IO::Socket::IP::Import::IPv6/"peerhost"> method.

=head2 peerport

C<method peerport : int ();>

Returns the peer port.

If L</"Domain"> field is C<AF_INET>, this method calls L<IO::Socket::IP::Import::IPv4#peerport|IO::Socket::IP::Import::IPv4/"peerport"> method.

If L</"Domain"> field is C<AF_INET6>, this method calls L<IO::Socket::IP::Import::IPv6#peerport|IO::Socket::IP::Import::IPv6/"peerport"> method.

=head2 accept

C<method accept : L<IO::Socket::IP|SPVM::IO::Socket::IP> ($peer_ref : L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>[] = undef);>

Calls L<accept|SPVM::IO::Socke/"new"> method of its super class given the argument given to this method and returns its return value.

=head1 Well Known Child Classes

=over 2

=item * L<IO::Socket::INET|SPVM::IO::Socket::INET>

=item * L<IO::Socket::INET6|SPVM::IO::Socket::INET6>

=back

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

