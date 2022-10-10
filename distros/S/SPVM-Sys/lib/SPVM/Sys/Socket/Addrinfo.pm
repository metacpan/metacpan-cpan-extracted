package SPVM::Sys::Socket::Addrinfo;

1;

=head1 Name

SPVM::Sys::Socket::Addrinfo - struct addrinfo in C language

=head1 Usage

  use Sys::Socket::Addrinfo;

=head1 Description

C<Sys::Socket::Addrinfo> is the class for the C<struct addrinfo> in C<C language>.

This is a L<pointer class|SPVM::Document::Language/"Pointer Class">.

=head1 Class Methods

=head2 new

  method new : Sys::Socket::Addrinfo ();

Create a new Sys::Socket::Addrinfo object.

=head1 Instance Methods

=head2 DESTROY

  method DESTROY : void ();

The destructor.

=head2 ai_flags

  method ai_flags : int ();

Gets C<ai_flags>.

=head2 set_ai_flags

  method set_ai_flags : void ($ai_flags : int);

Sets C<ai_flags>.

=head2 ai_family

  method ai_family : int ();

Gets C<ai_family>.

=head2 set_ai_family

  method set_ai_family : void ($ai_family : int);

Sets C<ai_family>.

=head2 ai_socktype

  method ai_socktype : int ();

Gets C<ai_socktype>.

=head2 set_ai_socktype

  method set_ai_socktype : void ($ai_socktype : int);

Sets C<ai_socktype>.

=head2 ai_protocol

  method ai_protocol : int ();

Gets C<ai_protocol>.

=head2 set_ai_protocol

  method set_ai_protocol : void ($ai_protocol : int);

Sets C<ai_protocol>.

=head2 copy_ai_addr

  method copy_ai_addr : Sys::Socket::Sockaddr ();

Copies C<ai_addr>.

=head2 copy_ai_canonname

  method copy_ai_canonname : string ();

Copies C<ai_canonname>.

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
