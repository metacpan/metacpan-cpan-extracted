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

  method DESTROY : void ();

The destructor.

=head2 sa_family

  method sa_family : int ()s

Get C<sa_family>. This is the overriden method of the L<sa_family|SPVM::Sys::Socket::Sockaddr/"sa_family"> method in the Sys::Socket::Sockaddr class.

=head2 sin6_family

  method sin6_family : int ();

Get C<sin6_family>.

=head2 set_sin6_family

  method set_sin6_family : void ();

Set C<sin6_family>.

=head2 sin6_flowinfo

  method sin6_flowinfo : int ();

=head2 set_sin6_flowinfo

  method set_sin6_flowinfo : void ();

=head2 sin6_scope_id

  method sin6_scope_id : int ();

=head2 set_sin6_scope_id

  method set_sin6_scope_id : void ();

=head2 sin6_addr

  method sin6_addr : Sys::Socket::In6_addr ();

Get C<sin6_addr>. This is a L<Sys::Socket::In6_addr|SPVM::Sys::Socket::In6_addr> object.

=head2 set_sin6_addr

  method set_sin6_addr : void ($address : Sys::Socket::In6_addr);

Set C<sin6_addr>. This is a L<Sys::Socket::In6_addr|SPVM::Sys::Socket::In6_addr> object.

=head2 sin6_port

  method sin6_port : short ();

Get C<sin6_port>.

=head2 set_sin6_port

  method set_sin6_port : void ($port : short);

Set C<sin6_port>.

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

