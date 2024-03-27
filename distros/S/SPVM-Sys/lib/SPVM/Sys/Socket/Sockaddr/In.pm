package SPVM::Sys::Socket::Sockaddr::In;

1;

=head1 Name

SPVM::Sys::Socket::Sockaddr::In - struct sockaddr_in in the C language

=head1 Description

The Sys::Socket::Sockaddr::In class in L<SPVM> represents L<struct sockaddr_in|https://linux.die.net/man/7/ip> in the C language.

=head1 Usage

  use Sys::Socket::Sockaddr::In;

=head1 Details

This class is a pointer class. The pointer the instance has is set to a L<struct sockaddr_in|https://linux.die.net/man/7/ip> object.

=head1 Inheritance

L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>

=head1 Class Methods

=head2 new

C<static method new : L<Sys::Socket::Sockaddr::In|SPVM::Sys::Socket::Sockaddr::In> ();>

Create a new L<Sys::Socket::Sockaddr::In|SPVM::Sys::Socket::Sockaddr::In> object.

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

The destructor.

=head2 sa_family

C<method sa_family : int ()>

Returns C<sa_family>.

=head2 sin_family

C<method sin_family : int ();>
  
Returns C<sin_family>.

=head2 set_sin_family

C<method set_sin_family : void ($family : int);>

Sets C<sin_family>.

=head2 sin_addr

C<method sin_addr : L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr> ();>

Copies C<sin_addr> and returns it.

=head2 set_sin_addr

C<method set_sin_addr : void ($address : L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr>);>

Sets C<sin_addr>.

Exceptions:

The address must be defined. Otherwise an exception is thrown.

=head2 sin_port

C<method sin_port : int ();>

Returns C<sin_port>.

=head2 set_sin_port

C<method set_sin_port : void ($port : int);>

Sets C<sin_port>.

=head2 size

C<method size : int ()>

Returns the size of C<struct sockaddr_in>.

=head2 clone

C<method clone : L<Sys::Socket::Sockaddr::In|SPVM::Sys::Socket::Sockaddr::In> ()>

Clones this instance and returns it.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

