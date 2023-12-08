package SPVM::IO::Socket;

1;

=head1 Name

SPVM::IO::Socket - Socket Communications

=head1 Usage
  
  use IO::Socket;
  use Sys::Socket::Constant as SOCKET;
  
  # Create a new AF_INET socket
  my $io_socket= IO::Socket->new({Domain => SOCKET->AF_INET});

  # Create a new AF_INET6 socket
  my $io_socket= IO::Socket->new({Domain => SOCKET->AF_INET6});
  
  # Create a new AF_UNIX socket
  my $io_socket= IO::Socket->new({Domain => SOCKET->AF_UNIX});

=head1 Description

L<SPVM::IO::Socket> provides socket communications.

=head1 Parent Class

L<IO::Handle|SPVM::IO::Handle>.

=head1 Fields

=head2 Domain

  has Domain : protected int;

=head2 Type

  has Type : protected int;

=head2 Proto

  has Proto : protected ro int;

=head2 Timeout

  has Timeout : protected double;

=head2 peername

  has peername : protected Sys::Socket::Sockaddr;

See also L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

=head2 Listen

  has Listen : protected int;

=head1 Class Methods

=head2 new

  static method new : IO::Socket ($options : object[] = undef);

The socket is set to non-blocking mode.

=head3 new Options

=over 2

=item * Domain : Int

=item * Type : Int

=item * Proto : Int

=item * Blocking : Int

=item * Timeout : Double

=item * Listen : Int

=back

See also L<SPVM::Sys::Socket::Constant>.

=head1 Instance Methods

=head2 sockdomain

  method sockdomain : int ();

Gets the L</"Domain"> field.

=head2 socktype

  method socktype : int ();

Gets the L</"Type"> field.

=head2 protocol

  method protocol : int ();

Gets the L</"Proto"> field.

=head2 timeout

  method timeout : double ();

Gets the L</"Timeout"> field.

=head2 new_from_instance

  method new_from_instance : IO::Socket ($options : object[] = undef);

=head2 peername

  method peername : Sys::Socket::Sockaddr ();

=head2 DESTROY

  method DESTROY : void ();

=head2 init

  protected method init : void ($options : object[] = undef);

=head2 connect

  method connect : void ($address : Sys::Socket::Sockaddr);

See also L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

=head2 recv

  method recv : int ($buffer : mutable string, $length : int = -1, $flags : int = 0, $buf_offset : int = 0);

=head2 send

  method send : int ($buffer : string, $flags : int = 0, $to : Sys::Socket::Sockaddr = undef, $length : int = -1, $buf_offset : int = 0);

See also L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

=head2 close

  method close : int ();

=head2 fileno

  method fileno : int (); return $self->{fd}; }

=head2 listen

  method listen : void ($queue : int = 5);

=head2 bind

  method bind : void ($address : Sys::Socket::Sockaddr);

See also L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

=head2 sockname

  method sockname : Sys::Socket::Sockaddr ();

See also L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

=head2 shutdown

  method shutdown : void ($sockfd : int, $how : int);

=head2 atmark

  method atmark : int ();

=head2 sockopt

  method sockopt : int ($level : int, $optname : int);

=head2 setsockopt

  method setsockopt : void ($level : int, $optname : int, $optval : object of string|Int)

=head2 connected

  method connected : Sys::Socket::Sockaddr ();

See also L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

=head2 socket

  method socket : void ($domain : int, $type : int, $protocol : int = 0);

=head2 socketpair

  method socketpair : int[] ($domain : int, $type : int, $protocol : int);

=head2 accept

  method accept : IO::Socket ($io_socket_builder : IO::Socket::Builder = undef, $peer_ref : Sys::Socket::Sockaddr[] = undef);

See also L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

See also L<IO::Socket::Builder|SPVM::IO::Socket::Builder>.


=head2 peerport

  method peerport : int ();

This method is implemented in a child class.

Exceptions:

Not implemented.

=head2 peerhost

  method peerhost : string ();

This method is implemented in a child class.

Exceptions:

Not implemented.

=head2 write

  method write : int ($string : string, $length : int = -1, $offset : int = 0);

=head2 read

  method read : int ($string : mutable string, $length : int = -1, $offset : int = 0);

=head1 See Also

=head2 Sys::Socket

L<Sys::Socket|SPVM::Sys::Socket>

=head2 Sys::Socket::Constant

L<Sys::Socket::Constant|SPVM::Sys::Socket::Constant>

=head2 IO::Socket::INET

L<IO::Socket::INET|SPVM::IO::Socket::INET>

=head2 Perl's IO::Socket

C<IO::Socket> is a Perl's L<IO::Socket|IO::Socket> porting to L<SPVM>.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

