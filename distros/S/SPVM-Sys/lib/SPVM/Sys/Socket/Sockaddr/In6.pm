package SPVM::Sys::Socket::Sockaddr::In6;

1;

=head1 Name

SPVM::Sys::Socket::Sockaddr::In6 - struct sockaddr_in6 in C language

=head1 Usage

  use Sys::Socket::Sockaddr::In6;

=head1 Description

C<Sys::Socket::Sockaddr::In6> is the class for the C<struct sockaddr_in6> in C<C language>.

This is a L<pointer class|SPVM::Document::Language/"Pointer Class">.

=head1 Inheritance

This class inherits L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

=head1 Class Methods

=head2 new

  static method new : Sys::Socket::Sockaddr::In6 ();

Create a new C<Sys::Socket::Sockaddr::In6> object.

=head1 Instance Methods

=head2 DESTROY

  method DESTROY : void ()

The destructor.

=head2 sa_family

  method sa_family : int ()

Gets C<sa_family>. This is the overriden method of the L<sa_family|SPVM::Sys::Socket::Sockaddr/"sa_family"> method in the Sys::Socket::Sockaddr class.

=head2 sin6_family

  method sin6_family : int ();

Gets C<sin6_family>.

=head2 set_sin6_family

  method set_sin6_family : void ($family : int)

Sets C<sin6_family>.

=head2 sin6_flowinfo

  method sin6_flowinfo : int ()

Gets C<sin6_flowinfo>.

=head2 set_sin6_flowinfo

  method set_sin6_flowinfo : void ($flowinfo : int)

Sets C<sin6_flowinfo>.

=head2 sin6_scope_id

  method sin6_scope_id : int ();

Gets C<sin6_scope_id>.

=head2 set_sin6_scope_id

  method set_sin6_scope_id : void ($scope_id : int)

Sets C<sin6_scope_id>.

=head2 copy_sin6_addr

  method copy_sin6_addr : Sys::Socket::In6_addr ();

Copies C<sin6_addr>. This is a L<Sys::Socket::In6_addr|SPVM::Sys::Socket::In6_addr> object.

=head2 set_sin6_addr

  method set_sin6_addr : void ($address : Sys::Socket::In6_addr);

Sets C<sin6_addr>. This is a L<Sys::Socket::In6_addr|SPVM::Sys::Socket::In6_addr> object.

=head2 sin6_port

  method sin6_port : int ();

Gets C<sin6_port>.

=head2 set_sin6_port

  method set_sin6_port : void ($port : int);

Sets C<sin6_port>.

=head2 sizeof

  method sizeof : int ()

The size of C<struct sockaddr_in6>.

=head2 clone

  method clone : Sys::Socket::Sockaddr::In6 ();

Clones this object.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

