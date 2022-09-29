package SPVM::Sys::Socket::Sockaddr::In;

1;

=head1 Name

SPVM::Sys::Socket::Sockaddr::In - struct sockaddr_in in C language

=head1 Usage

  use Sys::Socket::Sockaddr::In;

=head1 Description

C<Sys::Socket::Sockaddr::In> is the class for the C<struct sockaddr_in> in C<C language>.

This is a L<pointer class|SPVM::Document::Language/"Pointer Class">.

=head1 Inheritance

This class inherits L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

=head1 Class Methods

=head2 new

  static method new : Sys::Socket::Sockaddr::In ();

Create a new C<Sys::Socket::Sockaddr::In> object.

=head1 Instance Methods

=head2 DESTROY

  method DESTROY : void ();

The destructor.

=head2 sa_family

  method sa_family : byte ()

Gets C<sa_family>. This is the overriden method of the L<sa_family|SPVM::Sys::Socket::Sockaddr/"sa_family"> method in the Sys::Socket::Sockaddr class.

=head2 sin_family

  method sin_family : byte ();
  
Gets C<sin_family>.

=head2 set_sin_family

  method set_sin_family : void ($family : byte);

Sets C<sin_family>.

=head2 sin_addr

  method sin_addr : Sys::Socket::In_addr ();

Gets C<sin_addr>. This is a L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr> object.

=head2 set_sin_addr

  method set_sin_addr : void ($address : Sys::Socket::In_addr);

Sets C<sin_addr>. This is a L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr> object.

=head2 sin_port

  method sin_port : short ();

Gets C<sin_port>.

=head2 set_sin_port

  method set_sin_port : void ($port : short);

Sets C<sin_port>.

=head2 sizeof

  method sizeof : int ()

The size of C<struct sockaddr_in>.

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

