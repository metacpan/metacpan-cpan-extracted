package SPVM::IO::Socket::UNIX;



1;

=head1 Name

SPVM::IO::Socket::UNIX - Short Description

=head1 Description

The IO::Socket::UNIX class in L<SPVM> has methods for someting.

=head1 Usage

  use IO::Socket::UNIX;
  use Sys::Socket;
  use Sys::Socket::Constant as SOCKET;
  
  # Client
  my $socket_path = "my_socket.sock";
  my $io_socket = IO::Socket::UNIX->new({
    Peer => $socket_path,
  });
  
  # Server
  my $socket_path = "my_socket.sock";
  my $io_socket = IO::Socket::UNIX->new({
    Local => $socket_path,
    Listen    => 5,
  });

=head1 Fields

=head2 Local

C<has Local : string;>

A local path.

=head2 Peer

C<has Peer : string;>

A peer path.

=head1 Class Methods

=head2 new

C<static method new : L<IO::Socket::UNIX|SPVM::IO::Socket::UNIX> ($options : object[] = undef);>

Creates a new L<IO::Socket::UNIX|SPVM::IO::Socket::UNIX> object.

And creates a Unix domain socket.

And if L</"Peer"> field is defined, L<connect|https://linux.die.net/man/2/connect> is executed.

And if L</"Local"> field is defined, L<bind|https://linux.die.net/man/2/bind> and L<listen|https://linux.die.net/man/2/listen> are executed.

And returns the new object.

Options:

The following options are available adding the options for L<IO::Socket#new|SPVM::IO::Socket/"new"> method are available.

=over 2

=item * C<Peer> : string

L</"Peer"> field is set to this value.

=item * C<Local> : string

L</"Local"> field is set to this value.

=back

=head1 Instance Methods

=head2 hostpath

C<method hostpath : string ();>

=head2 peerpath

C<method peerpath : string ();>

=head2 accept

C<method accept : L<IO::Socket::UNIX|SPVM::IO::Socket::UNIX> ($peer_ref : L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>[] = undef);>

Calls L<accept|SPVM::IO::Socke/"new"> method of its super class given the argument given to this method and returns its return value.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

