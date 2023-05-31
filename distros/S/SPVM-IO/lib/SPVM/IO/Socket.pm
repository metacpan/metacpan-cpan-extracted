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

=head2 timeout

  has timeout : protected ro int;

=head2 sockdomain

  has sockdomain : protected ro int;

=head2 socktype

  has socktype : protected ro int;

=head2 protocol

  has protocol : protected ro int;

=head2 peername

  has peername : protected ro Sys::Socket::Sockaddr;

See also L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

=head2 fd

  has fd : protected int;

=head2 listen_backlog

  has listen_backlog : protected int;

=head1 Class Methods

=head2 new

  static method new : IO::Socket ($options : object[] = undef);

=head3 new Options

=over 2

=item * Timeout : Int

=item * Domain : Int

=item * Type : Int

=item * Blocking : Int

=item * Listen : Int

=back

See also L<SPVM::Sys::Socket::Constant>.

=head1 Instance Methods

=head2 new_instance

  method new_instance : IO::Socket ($options : object[] = undef);

=head2 DESTROY

  method DESTROY : void ();

=head2 init

  protected method init : void ($options : object[] = undef);

=head2 connect

  method connect : int ($address : Sys::Socket::Sockaddr);

See also L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

=head2 recv

  method recv : int ($buffer : mutable string, $length : int = -1, $flags : int = 0);

=head2 send

  method send : int ($buffer : string, $flags : int = 0, $to : Sys::Socket::Sockaddr = undef);

See also L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

=head2 close

  method close : int ();

=head2 fileno

  method fileno : int (); return $self->{fd}; }

=head2 opened

  method opened : int ();

=head2 listen

  method listen : int ($queue : int = 5);

=head2 bind

  method bind : int ($address : Sys::Socket::Sockaddr);

See also L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

=head2 sockname

  method sockname : Sys::Socket::Sockaddr ();

See also L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

=head2 shutdown

  method shutdown : int ($sockfd : int, $how : int);

=head2 atmark

  method atmark : int ();

=head2 setsockopt

  method setsockopt : int ($level : int, $optname : int, $optval : int);

=head2 getsockopt

  method getsockopt : int ($level : int, $optname : int);

=head2 connected

  method connected : Sys::Socket::Sockaddr ();

See also L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

=head2 socket

  method socket : int ($domain : int, $type : int, $protocol : int = 0);

=head2 socketpair

  method socketpair : int[] ($domain : int, $type : int, $protocol : int);

=head2 accept

  method accept : IO::Socket ($io_socket_builder : IO::Socket::Builder = undef, $peer_ref : Sys::Socket::Sockaddr[] = undef);

See also L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

See also L<IO::Socket::Builder|SPVM::IO::Socket::Builder>.

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

