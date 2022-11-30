package SPVM::IO::Socket::Interface;

1;

=head1 Name

SPVM::IO::Socket::Interface - IO::Socket Interface

=head1 Usage
  
  use IO::Socket::Interface;

=head1 Description

C<IO::Socket::Interface> provides L<IO::Socket|SPVM::IO::Socket> interface.

=head2 Interface Methods

=head2 new_instance

  method new_instance : IO::Socket ($options = undef : object[]);

=head2 fd

  method fd : int ();

=head2 listen_backlog

  method listen_backlog : int ();

=head2 timeout

  method timeout : int ();

=head2 sockdomain

  method sockdomain : int ();

=head2 socktype

  method socktype : int ();

=head2 protocol

  method protocol : int ();

=head2 peername

  method peername : Sys::Socket::Sockaddr ();

=head2 connect

  method connect : int ($address : Sys::Socket::Sockaddr);

See also L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

=head2 recv

  method recv : int ($buffer : mutable string, $length = -1 : int, $flags = 0 : int);

=head2 send

  method send : int ($buffer : string, $flags = 0 : int, $to = undef : Sys::Socket::Sockaddr);

See also L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

=head2 close

  method close : int ();

=head2 fileno

  method fileno : int ();

=head2 opened

  method opened : int ();

=head2 listen

  method listen : int ($queue = 5 : int);

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

  method socket : int ($domain : int, $type : int, $protocol = 0 : int);

=head2 socketpair

  method socketpair : int[] ($domain : int, $type : int, $protocol : int);

=head2 accept

  method accept : IO::Socket::Interface ($peer_ref = undef : Sys::Socket::Sockaddr[]);

See also L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

See also L<IO::Socket::Builder|SPVM::IO::Socket::Builder>.

